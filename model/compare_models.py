"""
Compare several CropVision checkpoints (made by train_cropvision.py) on the SAME test folder.

For every model it reports what a research paper needs:
  Accuracy, Macro-F1, worst per-class recall, number of classes below 95 % recall,
  parameters (M), fp32 weight size (MB) and CPU latency for one image (ms).
It also writes per_class_recall.csv (one column per model).

Usage (from the model folder):
  python .\\compare_models.py --test_dir ".\\official_test" --checkpoints (Get-ChildItem .\\runs -Recurse -Filter *_cropvision_best.pt).FullName

Notes
  * Macro-F1 here = mean F1 over the classes that occur in the test folder (same as
    sklearn f1_score(average="macro") unless a class is predicted but absent from the test set).
  * CPU latency is measured on THIS computer. It is not phone latency: export the model
    (ONNX / TFLite) and time it on the phone for the paper.
"""
import argparse
import copy
import csv
import time
from pathlib import Path

import numpy as np
import torch
from torch.utils.data import DataLoader
from torchvision import datasets, transforms

from train_cropvision import CropNet, Remap, confusion_metrics, predict


def cpu_latency_ms(model, size, runs=30):
    m = copy.deepcopy(model).cpu().float().eval()
    x = torch.randn(1, 3, size, size)
    with torch.no_grad():
        for _ in range(5):
            m(x)
        t0 = time.perf_counter()
        for _ in range(runs):
            m(x)
    return (time.perf_counter() - t0) / runs * 1000


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--checkpoints", nargs="+", required=True)
    ap.add_argument("--test_dir", required=True)
    ap.add_argument("--batch_size", type=int, default=64)
    ap.add_argument("--workers", type=int, default=0)
    ap.add_argument("--tta", action="store_true", help="average normal + mirrored prediction")
    ap.add_argument("--out", default="model_comparison.csv")
    args = ap.parse_args()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    use_amp = device.type == "cuda"
    test_names = datasets.ImageFolder(args.test_dir).classes
    results, recalls, class_names_ref = [], {}, None

    for path in args.checkpoints:
        ck = torch.load(path, map_location="cpu", weights_only=False)
        classes, crops = ck["classes"], ck["crops"]
        if class_names_ref is None:
            class_names_ref = classes
        elif classes != class_names_ref:
            raise SystemExit(f"{path}: class list differs from the first checkpoint")
        unknown = [c for c in test_names if c not in classes]
        if unknown:
            raise SystemExit(f"Test classes not in the checkpoint: {unknown}")
        table = [classes.index(c) for c in test_names]

        model = CropNet(ck["backbone"], len(classes), len(crops), pretrained=False)
        model.load_state_dict(ck["model"])
        model = model.to(device).to(memory_format=torch.channels_last).eval()

        tf = transforms.Compose([transforms.Resize((ck["img_size"], ck["img_size"])), transforms.ToTensor(),
                                 transforms.Normalize(ck["mean"], ck["std"])])
        ds = datasets.ImageFolder(args.test_dir, transform=tf, target_transform=Remap(table))
        loader = DataLoader(ds, batch_size=args.batch_size, num_workers=args.workers)
        probs, tg = predict(model, loader, device, use_amp, tta=args.tta)
        acc, f1, cm = confusion_metrics(tg, probs.argmax(1), len(classes))

        support = cm.sum(1)
        recall = np.where(support > 0, np.diag(cm) / np.maximum(support, 1), np.nan)
        present = support > 0
        params = sum(p.numel() for p in model.parameters()) / 1e6
        row = {
            "model": ck["backbone"],
            "accuracy_%": round(acc * 100, 2),
            "macro_f1_%": round(f1 * 100, 2),
            "worst_class_recall_%": round(float(np.nanmin(recall)) * 100, 1),
            "worst_class": classes[int(np.nanargmin(recall))],
            "classes_below_95%": int(np.sum(recall[present] < 0.95)),
            "params_M": round(params, 2),
            "fp32_weights_MB": round(params * 4, 1),
            "cpu_ms_per_image": round(cpu_latency_ms(model, ck["img_size"]), 1),
        }
        results.append(row)
        recalls[ck["backbone"]] = recall
        print(f"done: {row['model']}  acc {row['accuracy_%']}%  macro-F1 {row['macro_f1_%']}%")
        del model
        if device.type == "cuda":
            torch.cuda.empty_cache()

    keys = list(results[0].keys())
    print("\n" + " | ".join(keys))
    for r in sorted(results, key=lambda r: -r["macro_f1_%"]):
        print(" | ".join(str(r[k]) for k in keys))
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=keys)
        w.writeheader()
        w.writerows(results)
    with open("per_class_recall.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["class"] + list(recalls))
        for i, c in enumerate(class_names_ref):
            w.writerow([c] + ["" if np.isnan(recalls[m][i]) else round(float(recalls[m][i]) * 100, 1) for m in recalls])
    print(f"\nSaved {args.out} and per_class_recall.csv")


if __name__ == "__main__":
    main()
