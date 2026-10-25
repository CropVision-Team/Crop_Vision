"""
check_leakage.py - are the test images near-duplicates of training images?

PlantVillage has several photos of the same leaf, and a random split puts them on both sides.
This script finds, for every test image, the most similar training image (perceptual "dHash",
also checking flipped and rotated versions) and reports how many test images have a
near-duplicate in the training data.

Usage (from the model folder):
  python .\\check_leakage.py --train_dir ".\\dataset" --test_dir ".\\official_test"
  python .\\check_leakage.py --train_dir ".\\dataset" --test_dir ".\\official_test" --misclassified .\\misclassified.csv

With --misclassified (written by evaluate_test.py) it also prints the accuracy on test images that
have NO near-duplicate in training - the honest estimate for new leaves. Run evaluate_test.py
for the checkpoint you care about first, because misclassified.csv is overwritten on every run.

Distance = number of differing bits out of 64. 0 = same picture, <= 6 = near-duplicate (default
--threshold), > 10 = clearly different pictures. This is a heuristic: it finds copies, flips,
rotations and small crops/re-compressions, not photos of the same leaf taken from another angle.
"""
import argparse
import csv
import os
from pathlib import Path

import numpy as np
from PIL import Image

IMG_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
POP = np.array([bin(i).count("1") for i in range(256)], dtype=np.uint8)
ORIENTATIONS = [None, Image.ROTATE_90, Image.ROTATE_180, Image.ROTATE_270,
                Image.FLIP_LEFT_RIGHT, Image.FLIP_TOP_BOTTOM, Image.TRANSPOSE, Image.TRANSVERSE]


def dhash(img):
    """64-bit difference hash packed into 8 bytes."""
    g = np.asarray(img.convert("L").resize((9, 8), Image.LANCZOS), dtype=np.int16)
    return np.packbits((g[:, 1:] > g[:, :-1]).flatten())


def hash_variants(img):
    """Hashes of the image in all 8 flips/rotations -> array (8, 8) of uint8."""
    return np.stack([dhash(img if o is None else img.transpose(o)) for o in ORIENTATIONS])


def list_images(root):
    out = []
    for cls in sorted(p for p in Path(root).iterdir() if p.is_dir()):
        out += [(f, cls.name) for f in sorted(cls.rglob("*")) if f.suffix.lower() in IMG_EXT]
    return out


def nearest(train_hashes, query_hashes, chunk=64):
    """For each query (Q, 8 variants, 8 bytes) -> (min distance, index of nearest train image)."""
    dist_out = np.empty(len(query_hashes), dtype=np.int32)
    idx_out = np.empty(len(query_hashes), dtype=np.int64)
    for s in range(0, len(query_hashes), chunk):
        q = query_hashes[s:s + chunk]                                   # (K, 8, 8)
        best = None
        for v in range(q.shape[1]):                                     # each orientation of the query
            x = np.bitwise_xor(train_hashes[None, :, :], q[:, v, None, :])   # (K, N, 8)
            d = POP[x].sum(2, dtype=np.int32)                           # (K, N)
            best = d if best is None else np.minimum(best, d)
        idx_out[s:s + chunk] = best.argmin(1)
        dist_out[s:s + chunk] = best.min(1)
    return dist_out, idx_out


def load_hashes(items, variants, label):
    hashes, ok = [], []
    for i, (path, _) in enumerate(items):
        try:
            with Image.open(path) as im:
                im = im.convert("RGB")
                hashes.append(hash_variants(im) if variants else dhash(im))
                ok.append(i)
        except Exception as exc:                                        # unreadable file: skip, but say so
            print(f"  skipped {path}: {exc}")
        if (i + 1) % 5000 == 0:
            print(f"  {label}: {i + 1}/{len(items)}")
    return np.stack(hashes), ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--train_dir", required=True)
    ap.add_argument("--test_dir", required=True)
    ap.add_argument("--threshold", type=int, default=6, help="bits; <= this counts as a near-duplicate")
    ap.add_argument("--misclassified", default=None, help="misclassified.csv from evaluate_test.py")
    ap.add_argument("--out", default="leakage_report.csv")
    args = ap.parse_args()

    train_items, test_items = list_images(args.train_dir), list_images(args.test_dir)
    print(f"training images: {len(train_items)}   test images: {len(test_items)}")
    print("hashing training images ...")
    th, t_ok = load_hashes(train_items, False, "train")
    print("hashing test images (8 orientations each) ...")
    qh, q_ok = load_hashes(test_items, True, "test")
    print("comparing ...")
    dist, nn_idx = nearest(th, qh)

    rows = []
    for k, i in enumerate(q_ok):
        path, cls = test_items[i]
        npath, ncls = train_items[t_ok[nn_idx[k]]]
        rows.append((str(path), cls, int(dist[k]), str(npath), ncls))
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["test_file", "class", "min_distance_bits", "nearest_train_file", "nearest_train_class"])
        w.writerows(rows)

    d = np.array([r[2] for r in rows])
    n = len(d)
    print(f"\nTest images compared: {n}")
    for t in (0, 2, 4, args.threshold, 10):
        print(f"  with a training image within {t:>2} bits: {int((d <= t).sum()):>6}  ({100 * (d <= t).mean():5.1f}%)")
    near = d <= args.threshold
    print(f"\nNEAR-DUPLICATES (<= {args.threshold} bits): {int(near.sum())} of {n} test images ({100 * near.mean():.1f}%)")

    per_class = {}
    for (_, cls, dd, _, _), nr in zip(rows, near):
        a = per_class.setdefault(cls, [0, 0])
        a[0] += int(nr)
        a[1] += 1
    print("classes with the most near-duplicates:")
    for cls, (a, b) in sorted(per_class.items(), key=lambda kv: -kv[1][0] / kv[1][1])[:8]:
        print(f"  {100 * a / b:5.1f}%  ({a} of {b})  {cls}")

    if args.misclassified:
        wrong = set()
        with open(args.misclassified, newline="", encoding="utf-8") as f:
            for r in csv.DictReader(f):
                wrong.add(os.path.normcase(os.path.abspath(r["file"])))
        is_wrong = np.array([os.path.normcase(os.path.abspath(r[0])) in wrong for r in rows])
        for name, mask in (("WITH a near-duplicate in training", near), ("WITHOUT a near-duplicate (new leaves)", ~near)):
            m = int(mask.sum())
            if m:
                e = int(is_wrong[mask].sum())
                print(f"accuracy on test images {name}: {100 * (m - e) / m:.2f}%  ({e} wrong of {m})")
        print(f"mistakes matched to test files: {int(is_wrong.sum())} of {len(wrong)} in misclassified.csv")
    print(f"\nSaved {args.out}")


if __name__ == "__main__":
    main()
