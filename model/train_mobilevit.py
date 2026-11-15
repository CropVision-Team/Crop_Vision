"""
Disease Classification Training Script — HIGH ACCURACY VERSION
----------------------------------------------------------------
Techniques added to push accuracy to 99%+:
  - Label Smoothing (0.1): prevents overconfidence, improves generalisation
  - Mixup Augmentation (alpha=0.2): blends training image pairs
  - Linear LR Warmup (5 epochs): stabilises early training
  - Gradient Clipping (max_norm=1.0): prevents exploding gradients
  - Higher input resolution (256px): more detail for ViT attention heads
  - AdamW with weight decay (1e-4)
  - Early stopping (patience=5): avoids wasted epochs after convergence
  - Classifier dropout (0.1): extra regularization on the final layer

Run:
    python train_mobilevit.py --data_dir ./dataset --epochs 25
"""

import argparse
import os
import random
import time

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, Subset
from torchvision import datasets, transforms

try:
    import timm
except ImportError as e:
    raise SystemExit("timm is required: pip install timm") from e


IMG_SIZE = 256
MEAN = [0.485, 0.456, 0.406]
STD  = [0.229, 0.224, 0.225]


class AddGaussianNoise:
    def __init__(self, std=0.02):
        self.std = std
    def __call__(self, tensor):
        return tensor + torch.randn_like(tensor) * self.std


def build_transforms(train):
    if train:
        return transforms.Compose([
            transforms.RandomResizedCrop(IMG_SIZE, scale=(0.8, 1.0), ratio=(0.9, 1.1)),
            transforms.RandomHorizontalFlip(),
            transforms.RandomVerticalFlip(p=0.2),
            transforms.RandomRotation(30),
            transforms.RandomAffine(degrees=0, translate=(0.08, 0.08)),
            transforms.RandomPerspective(distortion_scale=0.15, p=0.3),
            transforms.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.25, hue=0.03),
            transforms.RandomApply([transforms.GaussianBlur(kernel_size=3, sigma=(0.1, 1.0))], p=0.2),
            transforms.RandomGrayscale(p=0.05),
            transforms.ToTensor(),
            transforms.Normalize(MEAN, STD),
            AddGaussianNoise(std=0.02),
        ])
    return transforms.Compose([
        transforms.Resize((IMG_SIZE, IMG_SIZE)),
        transforms.ToTensor(),
        transforms.Normalize(MEAN, STD),
    ])


def mixup_data(x, y, alpha=0.2, device="cpu"):
    lam = np.random.beta(alpha, alpha) if alpha > 0 else 1.0
    index = torch.randperm(x.size(0)).to(device)
    return lam * x + (1 - lam) * x[index], y, y[index], lam


def mixup_criterion(criterion, pred, y_a, y_b, lam):
    return lam * criterion(pred, y_a) + (1 - lam) * criterion(pred, y_b)


def build_model(num_classes):
    return timm.create_model("mobilevit_s", pretrained=True, num_classes=num_classes, drop_rate=0.1)


def get_scheduler(optimizer, warmup_epochs, total_epochs):
    def lr_lambda(epoch):
        if epoch < warmup_epochs:
            return float(epoch + 1) / float(max(1, warmup_epochs))
        progress = (epoch - warmup_epochs) / max(1, total_epochs - warmup_epochs)
        return 0.5 * (1.0 + np.cos(np.pi * progress))
    return torch.optim.lr_scheduler.LambdaLR(optimizer, lr_lambda)


def split_indices(n, val_frac, test_frac, seed=42):
    idx = list(range(n))
    random.Random(seed).shuffle(idx)
    v = int(n * val_frac)
    t = int(n * test_frac)
    return idx[v + t:], idx[:v], idx[v:v + t]


def evaluate(model, loader, device):
    model.eval()
    correct = total = 0
    with torch.no_grad():
        for images, labels in loader:
            images, labels = images.to(device), labels.to(device)
            _, pred = torch.max(model(images), 1)
            total += labels.size(0)
            correct += (pred == labels).sum().item()
    return correct / total if total else 0.0


def train(args):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Device: {device}")
    if device.type == "cuda":
        print(f"GPU: {torch.cuda.get_device_name(0)}")

    if device.type == "cpu":
        torch.set_num_threads(args.threads)
        print(f"Set PyTorch CPU threads: {args.threads}")

    train_full = datasets.ImageFolder(args.data_dir, transform=build_transforms(True))
    eval_full  = datasets.ImageFolder(args.data_dir, transform=build_transforms(False))
    class_names = train_full.classes
    print(f"Classes: {len(class_names)} | Input: {IMG_SIZE}px")

    train_idx, val_idx, test_idx = split_indices(len(train_full), args.val_split, args.test_split)
    print(f"train={len(train_idx)}, val={len(val_idx)}, test={len(test_idx)}")

    train_loader = DataLoader(Subset(train_full, train_idx), batch_size=args.batch_size, shuffle=True,  num_workers=0)
    val_loader   = DataLoader(Subset(eval_full,  val_idx),   batch_size=args.batch_size, shuffle=False, num_workers=0)
    test_loader  = DataLoader(Subset(eval_full,  test_idx),  batch_size=args.batch_size, shuffle=False, num_workers=0)

    model = build_model(len(class_names)).to(device)

    best_acc = 0.0
    patience = 0
    start_epoch = 0

    ckpt_path = os.path.join(args.output_dir, "mobilevit_best.pt")
    if args.resume and os.path.exists(ckpt_path):
        print(f"Loading weights from {ckpt_path} to resume training...")
        ckpt = torch.load(ckpt_path, map_location=device, weights_only=False)
        model.load_state_dict(ckpt["model_state"])
        best_acc = ckpt.get("val_acc", 0.0)
        start_epoch = ckpt.get("epoch", 1)
        print(f"Resumed from epoch {start_epoch} with previous val_acc={best_acc*100:.2f}%")

    criterion = nn.CrossEntropyLoss(label_smoothing=args.label_smoothing)
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=1e-4)
    warmup = 0 if args.resume else min(5, args.epochs // 3)
    scheduler = get_scheduler(optimizer, warmup, args.epochs)
    print(f"Warmup={warmup} epochs, training {args.epochs} additional epochs, lr={args.lr}, mixup={args.mixup}")

    for epoch in range(start_epoch, start_epoch + args.epochs):
        model.train()
        t0 = time.time()
        total_loss = 0.0

        for i, (images, labels) in enumerate(train_loader):
            images, labels = images.to(device), labels.to(device)
            if args.mixup > 0:
                mixed, ya, yb, lam = mixup_data(images, labels, alpha=args.mixup, device=device)
                optimizer.zero_grad()
                loss = mixup_criterion(criterion, model(mixed), ya, yb, lam)
            else:
                optimizer.zero_grad()
                loss = criterion(model(images), labels)

            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            optimizer.step()
            total_loss += loss.item() * images.size(0)
            if i % 20 == 0:
                print(f"  ep{epoch+1} batch{i}/{len(train_loader)} loss={loss.item():.4f} lr={optimizer.param_groups[0]['lr']:.6f}")

        scheduler.step()
        val_acc = evaluate(model, val_loader, device)
        total_epochs = start_epoch + args.epochs
        print(f"Epoch {epoch+1}/{total_epochs} | loss={total_loss/len(train_idx):.4f} | val_acc={val_acc*100:.2f}% | {time.time()-t0:.1f}s")

        if val_acc > best_acc:
            best_acc = val_acc
            patience = 0
            os.makedirs(args.output_dir, exist_ok=True)
            torch.save({"model_state": model.state_dict(), "class_names": class_names, "val_acc": val_acc, "epoch": epoch+1},
                       os.path.join(args.output_dir, "mobilevit_best.pt"))
            print(f"  -> BEST saved: {val_acc*100:.2f}%")
        else:
            patience += 1
            print(f"  -> patience {patience}/5")
            if patience >= 5:
                print(f"Early stop at epoch {epoch+1}")
                break

    print(f"\nBest val_acc = {best_acc*100:.2f}%")
    print("Loading best checkpoint for final test evaluation...")
    ckpt = torch.load(os.path.join(args.output_dir, "mobilevit_best.pt"), map_location=device, weights_only=False)
    model.load_state_dict(ckpt["model_state"])
    test_acc = evaluate(model, test_loader, device)
    print(f"\n{'='*55}")
    print(f"  FINAL TEST SET ACCURACY: {test_acc*100:.2f}%")
    print(f"{'='*55}")
    print("Report this number in your project submission.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir",        required=True)
    parser.add_argument("--output_dir",      default="./checkpoints")
    parser.add_argument("--epochs",          type=int,   default=25)
    parser.add_argument("--batch_size",      type=int,   default=32)
    parser.add_argument("--lr",              type=float, default=2e-4)
    parser.add_argument("--val_split",       type=float, default=0.15)
    parser.add_argument("--test_split",      type=float, default=0.15)
    parser.add_argument("--resume",          action="store_true", default=False, help="Resume training from previous checkpoint")
    parser.add_argument("--mixup",           type=float, default=0.2, help="Mixup alpha (set to 0.0 for pure fine-tuning)")
    parser.add_argument("--label_smoothing", type=float, default=0.1, help="Label smoothing value")
    parser.add_argument("--threads",         type=int,   default=8,   help="CPU threads for PyTorch")
    train(parser.parse_args())

