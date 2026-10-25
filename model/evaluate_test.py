"""
Score a CropVision MobileViT-S checkpoint on a whole folder of class sub-folders
(e.g. .\\official_test) and list the mistakes.

Usage (from the model folder):
    python .\\evaluate_test.py
    python .\\evaluate_test.py --split_dir ".\\official_test" --checkpoint ".\\checkpoints\\mobilevit_best.pt" --batch_size 32

Writes misclassified.csv (file, true class, predicted class, confidence) so you can open the
wrong images and see whether they are look-alikes or wrongly labelled.
"""
import argparse
import csv
from collections import Counter
from pathlib import Path

import torch
import timm
from PIL import Image
from torch.utils.data import DataLoader, Dataset
from torchvision import transforms

IMG_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
IMG_SIZE = 224
MEAN = [0.485, 0.456, 0.406]
STD = [0.229, 0.224, 0.225]


class FolderDataset(Dataset):
    """Class sub-folders matched to the checkpoint's class names BY NAME."""

    def __init__(self, root, class_names, tf):
        index = {c: i for i, c in enumerate(class_names)}
        self.items, self.tf = [], tf
        self.skipped = []
        for d in sorted(p for p in Path(root).iterdir() if p.is_dir()):
            if d.name not in index:
                self.skipped.append(d.name)
                continue
            for f in sorted(d.rglob("*")):
                if f.suffix.lower() in IMG_EXT:
                    self.items.append((f, index[d.name]))
        if not self.items:
            raise SystemExit(f"No images found under {root}")

    def __len__(self):
        return len(self.items)

    def __getitem__(self, i):
        path, label = self.items[i]
        return self.tf(Image.open(path).convert("RGB")), label, i


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--split_dir", default="./official_test")
    ap.add_argument("--checkpoint", default="./checkpoints/mobilevit_best.pt")
    ap.add_argument("--batch_size", type=int, default=32)
    ap.add_argument("--workers", type=int, default=0, help="0 is safest on Windows")
    ap.add_argument("--tta", action="store_true", help="average normal + mirrored prediction")
    ap.add_argument("--known_crop", action="store_true",
                    help="only allow classes of the true crop (= the farmer picked the crop in the app)")
    args = ap.parse_args()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    ck = torch.load(args.checkpoint, map_location="cpu", weights_only=False)
    class_names = ck["class_names"]
    model = timm.create_model("mobilevit_s", pretrained=False, num_classes=len(class_names))
    model.load_state_dict(ck["model_state"])
    model.to(device).eval()

    crop_of = [c.split("___")[0] for c in class_names]
    crops = sorted(set(crop_of))
    cls_crop = torch.tensor([crops.index(c) for c in crop_of], device=device)
    allowed = torch.tensor([[1.0 if crop_of[j] == c else 0.0 for j in range(len(class_names))] for c in crops],
                           device=device)

    tf = transforms.Compose([transforms.Resize((IMG_SIZE, IMG_SIZE)), transforms.ToTensor(),
                             transforms.Normalize(MEAN, STD)])
    ds = FolderDataset(args.split_dir, class_names, tf)
    loader = DataLoader(ds, batch_size=args.batch_size, num_workers=args.workers)
    print(f"Checkpoint: {Path(args.checkpoint).resolve()}")
    print(f"Folder: {Path(args.split_dir).resolve()}   images: {len(ds)}   device: {device}")
    if ds.skipped:
        print(f"Skipped folders not in the checkpoint's classes: {ds.skipped}")

    n_cls = len(class_names)
    per_total, per_ok, per_pred = [0] * n_cls, [0] * n_cls, [0] * n_cls
    confusions, wrong = Counter(), []
    correct = 0
    cross_crop = 0
    with torch.no_grad():
        for x, y, idx in loader:
            x = x.to(device)
            p = torch.softmax(model(x), 1)
            if args.tta:
                p = (p + torch.softmax(model(x.flip(3)), 1)) / 2
            if args.known_crop:
                p = p * allowed[cls_crop[y.to(device)]]
            conf, pred = p.max(1)
            for yi, pi, ci, ii in zip(y.tolist(), pred.cpu().tolist(), conf.cpu().tolist(), idx.tolist()):
                per_total[yi] += 1
                per_pred[pi] += 1
                if yi == pi:
                    per_ok[yi] += 1
                    correct += 1
                else:
                    if crop_of[yi] != crop_of[pi]:
                        cross_crop += 1
                    confusions[(class_names[yi], class_names[pi])] += 1
                    wrong.append((str(ds.items[ii][0]), class_names[yi], class_names[pi], round(ci, 4)))

    total = len(ds)
    print(f"\nCorrect: {correct}\nTOTAL: {total}\nTEST ACCURACY{' (+flip TTA)' if args.tta else ''}{' (crop given)' if args.known_crop else ''}: "
          f"{100 * correct / total:.2f}%")

    f1s = []
    for i in range(n_cls):
        if per_total[i]:
            prec = per_ok[i] / per_pred[i] if per_pred[i] else 0.0
            rec = per_ok[i] / per_total[i]
            f1s.append(2 * prec * rec / (prec + rec) if prec + rec else 0.0)
    print(f"MACRO-F1: {100 * sum(f1s) / len(f1s):.2f}%")

    print("\nEVERY class, worst first   (!! = below 95%)")
    rows = sorted((per_ok[i] / per_total[i], per_total[i] - per_ok[i], per_total[i], class_names[i])
                  for i in range(n_cls) if per_total[i])
    for acc, err, tot, name in rows:
        print(f"  {'!!' if acc < 0.95 else '  '} {100 * acc:5.1f}%  ({err:>3} wrong of {tot:>5})  {name}")
    print(f"\nClasses below 95%: {sum(1 for r in rows if r[0] < 0.95)} of {len(rows)}")

    print("\nPer crop:")
    agg = {}
    for i in range(n_cls):
        a = agg.setdefault(crop_of[i], [0, 0])
        a[0] += per_ok[i]
        a[1] += per_total[i]
    for c, (ok, tot) in sorted(agg.items(), key=lambda kv: kv[1][0] / max(kv[1][1], 1)):
        if tot:
            print(f"  {100 * ok / tot:5.1f}%  ({tot - ok:>3} wrong of {tot:>5})  {c}")
    print(f"\nMistakes that picked a DIFFERENT crop: {cross_crop} of {total - correct}")

    print("\nMost common mix-ups (true -> predicted):")
    for (t, p), n in confusions.most_common(15):
        print(f"  {n:>4}  {t}  ->  {p}")

    with open("misclassified.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["file", "true_class", "predicted_class", "confidence"])
        w.writerows(sorted(wrong, key=lambda r: -r[3]))
    print(f"\nSaved {len(wrong)} mistakes to misclassified.csv (most confident mistakes first).")

    idx = {c: i for i, c in enumerate(class_names)}
    cm = [[0] * n_cls for _ in range(n_cls)]
    for i in range(n_cls):
        cm[i][i] = per_ok[i]
    for (t, p), n in confusions.items():
        cm[idx[t]][idx[p]] = n
    with open("confusion_matrix.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["true class (rows) / predicted class (columns)"] + class_names)
        for name, row in zip(class_names, cm):
            w.writerow([name] + row)
    print("Saved confusion_matrix.csv (open it in Excel: rows = true class, columns = predicted class).")


if __name__ == "__main__":
    main()
