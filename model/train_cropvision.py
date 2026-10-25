#!/usr/bin/env python
"""
CropVision training script  (PyTorch + timm)

One shared backbone (MobileViT-S by default, any timm model works) with:
  * a DISEASE head   (38 crop/disease classes)
  * a CROP head      (crop name, taken from the folder prefix before '___')
  * hierarchical consistency loss: the crop implied by the disease probabilities
    must agree with the true crop
  * optional OUTLIER EXPOSURE (--outlier_dir): non-leaf photos (selfies, objects,
    soil, hands ...) are trained towards a uniform prediction, so low confidence
    can be used as the "is this a valid leaf?" gate in the app.

Recipe: ImageNet-pretrained weights, AdamW, warm-up + cosine LR, label smoothing,
strong augmentation, weight EMA, AMP, early stopping, resume, final evaluation on
the separate test folder (classes matched BY NAME, so a missing class folder in
the test set cannot shift the labels).

Install once:  pip install timm

MobileViT-S (one line):
  python train_cropvision.py --data_dir ".\\dataset" --test_dir ".\\official_test" --backbone mobilevit_s --epochs 30 --batch_size 32 --output_dir ".\\checkpoints_v2"

Second model for comparison (one line):
  python train_cropvision.py --data_dir ".\\dataset" --test_dir ".\\official_test" --backbone efficientnet_b0 --epochs 30 --batch_size 32 --output_dir ".\\checkpoints_effb0"
"""
import argparse
import copy
import csv
import json
import math
import random
import time
import pathlib
import sys
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from PIL import Image
from torch.utils.data import DataLoader, Dataset, Subset
from torchvision import datasets, transforms

import timm

IMG_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

if sys.platform == "win32":
    # Older timm downloads the original XCiT / DeiT weight files, which were saved on Linux and contain a
    # PosixPath. Without this line Windows fails with "cannot instantiate 'PosixPath' on your system".
    pathlib.PosixPath = pathlib.WindowsPath


# ----------------------------------------------------------------------------- helpers
def set_seed(seed):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)


def stratified_split(targets, val_fraction, seed):
    """Per-class random split -> (train_idx, val_idx). Every class appears in both."""
    rng = np.random.RandomState(seed)
    targets = np.asarray(targets)
    train_idx, val_idx = [], []
    for c in np.unique(targets):
        idx = np.where(targets == c)[0]
        rng.shuffle(idx)
        n_val = max(1, int(round(len(idx) * val_fraction)))
        val_idx.extend(idx[:n_val].tolist())
        train_idx.extend(idx[n_val:].tolist())
    return train_idx, val_idx


def confusion_metrics(t, p, n_classes):
    """Return accuracy, macro-F1 (over classes that occur in t) and the confusion matrix."""
    t = np.asarray(t)
    p = np.asarray(p)
    cm = np.zeros((n_classes, n_classes), dtype=np.int64)
    np.add.at(cm, (t, p), 1)
    tp = np.diag(cm).astype(float)
    prec = tp / np.maximum(cm.sum(0), 1)
    rec = tp / np.maximum(cm.sum(1), 1)
    f1 = 2 * prec * rec / np.maximum(prec + rec, 1e-12)
    present = cm.sum(1) > 0
    return float(tp.sum() / max(cm.sum(), 1)), float(f1[present].mean()), cm


def lr_at(step, total, warmup, base, floor=1e-6):
    if step < warmup:
        return base * (step + 1) / max(1, warmup)
    prog = (step - warmup) / max(1, total - warmup)
    return floor + (base - floor) * 0.5 * (1 + math.cos(math.pi * prog))


class Remap:
    """Picklable target transform (lambdas break DataLoader workers on Windows)."""

    def __init__(self, table):
        self.table = table

    def __call__(self, i):
        return self.table[i]


class FlatImages(Dataset):
    """All images found recursively under a folder (no class sub-folders needed)."""

    def __init__(self, root, tf):
        self.files = sorted(p for p in Path(root).rglob("*") if p.suffix.lower() in IMG_EXT)
        if not self.files:
            raise FileNotFoundError(f"No images found under {root}")
        self.tf = tf

    def __len__(self):
        return len(self.files)

    def __getitem__(self, i):
        return self.tf(Image.open(self.files[i]).convert("RGB"))


def endless(loader):
    while True:
        for batch in loader:
            yield batch


class EMA:
    def __init__(self, model, decay):
        self.module = copy.deepcopy(model).eval()
        for p in self.module.parameters():
            p.requires_grad_(False)
        self.decay = decay
        self.n = 0

    @torch.no_grad()
    def update(self, model):
        self.n += 1
        d = min(self.decay, (1 + self.n) / (10 + self.n))
        for e, m in zip(self.module.state_dict().values(), model.state_dict().values()):
            if e.dtype.is_floating_point:
                e.mul_(d).add_(m.detach(), alpha=1 - d)
            else:
                e.copy_(m)


class CropNet(nn.Module):
    def __init__(self, backbone, n_classes, n_crops, pretrained, drop=0.2):
        super().__init__()
        self.body = timm.create_model(backbone, pretrained=pretrained, num_classes=0)
        d = self.body.num_features
        self.drop = nn.Dropout(drop)
        self.disease = nn.Linear(d, n_classes)
        self.crop = nn.Linear(d, n_crops)

    def forward(self, x):
        f = self.drop(self.body(x))
        return self.disease(f), self.crop(f)


# ----------------------------------------------------------------------------- losses
def train_loss(logits_d, logits_c, y, crop_y, class_to_crop_onehot, args):
    loss_d = F.cross_entropy(logits_d, y, label_smoothing=args.label_smoothing)
    loss_c = F.cross_entropy(logits_c, crop_y)
    implied_crop = F.softmax(logits_d.float(), 1) @ class_to_crop_onehot  # (B, n_crops)
    loss_h = F.nll_loss(torch.log(implied_crop.clamp_min(1e-8)), crop_y)
    return loss_d + args.w_crop * loss_c + args.w_hier * loss_h


def outlier_exposure_loss(logits_d):
    """Cross-entropy to the uniform distribution (Hendrycks et al., Outlier Exposure)."""
    return -F.log_softmax(logits_d.float(), 1).mean(1).mean()


# ----------------------------------------------------------------------------- evaluation
@torch.no_grad()
def predict(model, loader, device, use_amp, tta=False):
    model.eval()
    probs, targets = [], []
    for batch in loader:
        x, y = batch if isinstance(batch, (tuple, list)) else (batch, None)
        x = x.to(device, non_blocking=True).contiguous(memory_format=torch.channels_last)
        with torch.autocast(device_type=device.type, dtype=torch.float16, enabled=use_amp):
            p = F.softmax(model(x)[0].float(), 1)
            if tta:
                p = (p + F.softmax(model(x.flip(3))[0].float(), 1)) / 2
        probs.append(p.cpu())
        if y is not None:
            targets.append(y)
    probs = torch.cat(probs).numpy()
    return probs, (torch.cat(targets).numpy() if targets else None)


# ----------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data_dir", required=True)
    ap.add_argument("--test_dir", default=None)
    ap.add_argument("--outlier_dir", default=None, help="folder of NON-leaf images for the leaf gate")
    ap.add_argument("--outlier_test_dir", default=None, help="held-out non-leaf images to measure rejection")
    ap.add_argument("--output_dir", default="checkpoints_v2")
    ap.add_argument("--backbone", default="mobilevit_s")
    ap.add_argument("--no_pretrained", action="store_true", help="only for offline smoke tests")
    ap.add_argument("--img_size", type=int, default=224)
    ap.add_argument("--epochs", type=int, default=30)
    ap.add_argument("--batch_size", type=int, default=32, help="keep >= 16: MobileViT uses BatchNorm")
    ap.add_argument("--lr", type=float, default=3e-4)
    ap.add_argument("--head_lr_mult", type=float, default=10.0)
    ap.add_argument("--weight_decay", type=float, default=0.05)
    ap.add_argument("--warmup_epochs", type=float, default=1.0)
    ap.add_argument("--label_smoothing", type=float, default=0.1)
    ap.add_argument("--w_crop", type=float, default=0.3)
    ap.add_argument("--w_hier", type=float, default=0.2)
    ap.add_argument("--w_oe", type=float, default=0.5)
    ap.add_argument("--ema", type=float, default=0.999)
    ap.add_argument("--val_split", type=float, default=0.15)
    ap.add_argument("--patience", type=int, default=8)
    ap.add_argument("--gate_threshold", type=float, default=0.80)
    ap.add_argument("--workers", type=int, default=2)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--resume", default=None)
    args = ap.parse_args()

    set_seed(args.seed)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    use_amp = device.type == "cuda"
    out = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)
    print(f"device={device}  backbone={args.backbone}  batch={args.batch_size}  epochs={args.epochs}")

    # ---- model first: its pretrained config tells us the right mean/std (MobileViT != ImageNet stats)
    classes = datasets.ImageFolder(args.data_dir).classes
    crops = sorted({c.split("___")[0] for c in classes})
    crop_idx = {c: i for i, c in enumerate(crops)}
    class_to_crop = torch.tensor([crop_idx[c.split("___")[0]] for c in classes]).to(device)
    onehot = F.one_hot(class_to_crop, len(crops)).float()
    model = CropNet(args.backbone, len(classes), len(crops), pretrained=not args.no_pretrained)
    cfg = timm.data.resolve_data_config({}, model=model.body)
    mean, std = cfg["mean"], cfg["std"]
    print(f"{len(classes)} classes, {len(crops)} crops, mean={mean}, std={std}")
    model = model.to(device).to(memory_format=torch.channels_last)

    train_tf = transforms.Compose([
        transforms.RandomResizedCrop(args.img_size, scale=(0.5, 1.0)),
        transforms.RandomHorizontalFlip(),
        transforms.RandomVerticalFlip(),
        transforms.RandomRotation(20),
        transforms.TrivialAugmentWide(),
        transforms.ToTensor(),
        transforms.Normalize(mean, std),
        transforms.RandomErasing(p=0.25),
    ])
    eval_tf = transforms.Compose([
        transforms.Resize((args.img_size, args.img_size)),
        transforms.ToTensor(),
        transforms.Normalize(mean, std),
    ])

    # ---- data
    ds_train_full = datasets.ImageFolder(args.data_dir, transform=train_tf)
    ds_eval_full = datasets.ImageFolder(args.data_dir, transform=eval_tf)
    tr_idx, va_idx = stratified_split(ds_train_full.targets, args.val_split, args.seed)
    kw = dict(num_workers=args.workers, pin_memory=device.type == "cuda",
              persistent_workers=args.workers > 0)
    train_loader = DataLoader(Subset(ds_train_full, tr_idx), batch_size=args.batch_size,
                              shuffle=True, drop_last=True, **kw)
    val_loader = DataLoader(Subset(ds_eval_full, va_idx), batch_size=args.batch_size * 2, **kw)
    print(f"train={len(tr_idx)}  val={len(va_idx)}")

    outlier_iter = None
    if args.outlier_dir:
        od = FlatImages(args.outlier_dir, train_tf)
        ob = max(2, args.batch_size // 2)
        outlier_iter = endless(DataLoader(od, batch_size=ob, shuffle=True, drop_last=True, **kw))
        print(f"outlier images for the leaf gate: {len(od)}")

    # ---- optimiser: no weight decay on bias / norm, 10x LR for the fresh heads
    groups = {}
    for name, p in model.named_parameters():
        if not p.requires_grad:
            continue
        is_head = name.startswith(("disease", "crop"))
        decay = p.ndim > 1
        groups.setdefault((is_head, decay), []).append(p)
    param_groups = [{"params": ps, "weight_decay": args.weight_decay if d else 0.0,
                     "lr_mult": args.head_lr_mult if h else 1.0} for (h, d), ps in groups.items()]
    opt = torch.optim.AdamW(param_groups, lr=args.lr)
    scaler = torch.amp.GradScaler("cuda", enabled=use_amp) if hasattr(torch.amp, "GradScaler") \
        else torch.cuda.amp.GradScaler(enabled=use_amp)
    ema = EMA(model, args.ema)

    steps_per_epoch = len(train_loader)
    total_steps = args.epochs * steps_per_epoch
    warm_steps = int(args.warmup_epochs * steps_per_epoch)
    start_epoch, best_acc, bad = 0, 0.0, 0
    best_path, last_path = out / f"{args.backbone}_cropvision_best.pt", out / f"{args.backbone}_cropvision_last.pt"

    if args.resume:
        ck = torch.load(args.resume, map_location=device)
        model.load_state_dict(ck["model_raw"])
        ema.module.load_state_dict(ck["model"])
        opt.load_state_dict(ck["opt"])
        start_epoch, best_acc, bad = ck["epoch"] + 1, ck["best_acc"], ck["bad"]
        print(f"resumed from {args.resume} at epoch {start_epoch}")

    def save(path, epoch, val_acc):
        torch.save({"model": ema.module.state_dict(), "model_raw": model.state_dict(),
                    "opt": opt.state_dict(), "epoch": epoch, "best_acc": best_acc, "bad": bad,
                    "val_acc": val_acc, "backbone": args.backbone, "classes": classes,
                    "crops": crops, "img_size": args.img_size, "mean": mean, "std": std,
                    "gate_threshold": args.gate_threshold}, path)

    # ---- training
    for epoch in range(start_epoch, args.epochs):
        model.train()
        t0, run = time.time(), 0.0
        for i, (x, y) in enumerate(train_loader):
            step = epoch * steps_per_epoch + i
            base = lr_at(step, total_steps, warm_steps, args.lr)
            for g in opt.param_groups:
                g["lr"] = base * g["lr_mult"]
            x = x.to(device, non_blocking=True).contiguous(memory_format=torch.channels_last)
            y = y.to(device, non_blocking=True)
            n_leaf = x.size(0)
            if outlier_iter is not None:
                xo = next(outlier_iter).to(device, non_blocking=True).contiguous(memory_format=torch.channels_last)
                x = torch.cat([x, xo])
            with torch.autocast(device_type=device.type, dtype=torch.float16, enabled=use_amp):
                ld, lc = model(x)
            loss = train_loss(ld[:n_leaf].float(), lc[:n_leaf].float(), y, class_to_crop[y], onehot, args)
            if outlier_iter is not None:
                loss = loss + args.w_oe * outlier_exposure_loss(ld[n_leaf:])
            opt.zero_grad(set_to_none=True)
            scaler.scale(loss).backward()
            scaler.unscale_(opt)
            torch.nn.utils.clip_grad_norm_(model.parameters(), 2.0)
            scaler.step(opt)
            scaler.update()
            ema.update(model)
            run += loss.item()

        probs, tg = predict(ema.module, val_loader, device, use_amp)
        # val_loader targets are indices into ds_eval_full -> already class indices
        acc, f1, _ = confusion_metrics(tg, probs.argmax(1), len(classes))
        improved = acc > best_acc
        if improved:
            best_acc, bad = acc, 0
        else:
            bad += 1
        print(f"epoch {epoch + 1:>3}/{args.epochs}  loss {run / steps_per_epoch:.4f}  "
              f"val_acc {acc * 100:.2f}%  val_macro_f1 {f1:.4f}  best {best_acc * 100:.2f}%  "
              f"{time.time() - t0:.0f}s{'  *' if improved else ''}")
        save(last_path, epoch, acc)          # resumable after overheating / interruption
        if improved:
            save(best_path, epoch, acc)
        if bad >= args.patience:
            print(f"early stopping: no improvement for {args.patience} epochs")
            break

    # ---- final evaluation with the best (EMA) weights
    ck = torch.load(best_path, map_location=device)
    ema.module.load_state_dict(ck["model"])
    print(f"\nBest validation accuracy: {ck['val_acc'] * 100:.2f}%  (epoch {ck['epoch'] + 1})")
    if args.test_dir:
        remap_names = datasets.ImageFolder(args.test_dir).classes
        unknown = [c for c in remap_names if c not in classes]
        if unknown:
            raise SystemExit(f"Test classes not in training data: {unknown}")
        table = [classes.index(c) for c in remap_names]
        missing = [c for c in classes if c not in remap_names]
        if missing:
            print(f"note: test set has no folder for: {missing}")
        test_ds = datasets.ImageFolder(args.test_dir, transform=eval_tf, target_transform=Remap(table))
        test_loader = DataLoader(test_ds, batch_size=args.batch_size * 2, **kw)
        for tta in (False, True):
            probs, tg = predict(ema.module, test_loader, device, use_amp, tta=tta)
            acc, f1, cm = confusion_metrics(tg, probs.argmax(1), len(classes))
            print(f"OFFICIAL TEST ACCURACY{' (+flip TTA)' if tta else ''}: {acc * 100:.2f}%   macro-F1 {f1:.4f}   "
                  f"({int(np.trace(cm))}/{int(cm.sum())})")
        conf = probs.max(1)
        print(f"leaf gate @ threshold {args.gate_threshold}: {np.mean(conf >= args.gate_threshold) * 100:.1f}% "
              f"of real leaf test images accepted")
        with open(out / f"{args.backbone}_confusion_matrix.csv", "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow([""] + classes)
            for name, row in zip(classes, cm):
                w.writerow([name] + row.tolist())
        worst = sorted(((cm[i, i] / max(cm[i].sum(), 1), classes[i]) for i in range(len(classes)) if cm[i].sum()))[:5]
        print("weakest classes:", ", ".join(f"{n} ({r * 100:.1f}%)" for r, n in worst))
        if args.outlier_test_dir:
            ot = DataLoader(FlatImages(args.outlier_test_dir, eval_tf), batch_size=args.batch_size * 2, **kw)
            op, _ = predict(ema.module, ot, device, use_amp)
            print(f"leaf gate: {np.mean(op.max(1) < args.gate_threshold) * 100:.1f}% of NON-leaf images rejected")
    (out / f"{args.backbone}_classes.json").write_text(json.dumps({"classes": classes, "crops": crops}, indent=2))


if __name__ == "__main__":
    main()
