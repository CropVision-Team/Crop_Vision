"""
Build the publication confusion-matrix figure and the metrics tables from REAL
evaluation output.

Input: the confusion_matrix.csv written by evaluate_test.py
       (rows = true class, columns = predicted class, first cell is a header).

Usage (from the model folder):
    python evaluate_test.py --split_dir ./official_test --checkpoint ./checkpoints/mobilevit_best.pt
    python plot_confusion_matrix.py                       # reads ./confusion_matrix.csv
    python plot_confusion_matrix.py --csv path/to/confusion_matrix.csv --out ../docs/research_figures

Outputs (in --out):
    confusion_matrix_overall.png        large, titled version for viewing
    confusion_matrix_overall_paper.png  7.16 in wide, 600 dpi, no title (IEEE page width)
    evaluation_metrics.json             accuracy, macro-F1, per-class and per-crop numbers

Every number in the figure and in the JSON is computed from the CSV. Nothing is simulated.
"""
import argparse
import csv
import json
import re
from pathlib import Path

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import PowerNorm


def load_matrix(path):
    with open(path, newline="", encoding="utf-8") as f:
        rows = list(csv.reader(f))
    class_names = rows[0][1:]
    names_rows = [r[0] for r in rows[1:]]
    if names_rows != class_names:
        raise SystemExit("Row names and column names of the CSV do not match.")
    cm = np.array([[int(float(v)) for v in r[1:]] for r in rows[1:]], dtype=int)
    if cm.shape[0] != cm.shape[1]:
        raise SystemExit(f"Matrix is not square: {cm.shape}")
    return class_names, cm


def clean(s):
    s = re.sub(r"[_,]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def split_class(name):
    """'Tomato___Late_blight' -> ('Tomato', 'Tomato Late blight'). Falls back to first word as crop."""
    if "___" in name:
        crop, disease = name.split("___", 1)
    else:
        crop, disease = name.split(" ", 1)[0], name
        disease = disease.split(" ", 1)[-1] if " " in disease else disease
    crop_c = re.sub(r"\s*\(.*?\)", "", clean(crop)).strip() or clean(crop)   # "Corn (maize)" -> "Corn"
    dis_c = clean(disease)
    label = dis_c if dis_c.lower().startswith(crop_c.lower()) else f"{crop_c} {dis_c}"
    return crop_c, label


def crop_blocks(crops):
    blocks, start = [], 0
    for i in range(1, len(crops) + 1):
        if i == len(crops) or crops[i] != crops[start]:
            blocks.append((crops[start], start, i))
            start = i
    return blocks


def compute_metrics(class_names, cm, crops):
    n = len(class_names)
    tp = np.diag(cm).astype(float)
    support = cm.sum(1)
    pred = cm.sum(0)
    prec = np.divide(tp, pred, out=np.zeros(n), where=pred > 0)
    rec = np.divide(tp, support, out=np.zeros(n), where=support > 0)
    f1 = np.divide(2 * tp, support + pred, out=np.zeros(n), where=(support + pred) > 0)
    has = support > 0
    per_crop = {}
    for crop, a, b in crop_blocks(crops):
        sub = cm[a:b]
        tot = int(sub.sum())
        ok = int(np.trace(cm[a:b, a:b]))
        inside = int(sub[:, a:b].sum())
        per_crop[crop] = dict(images=tot, correct=ok, accuracy=ok / tot if tot else 0.0,
                              cross_crop_errors=tot - inside,
                              macro_f1=float(f1[a:b][has[a:b]].mean()) if has[a:b].any() else 0.0)
    total = int(cm.sum())
    return dict(
        images=total, correct=int(tp.sum()), accuracy=float(tp.sum() / total),
        macro_f1=float(f1[has].mean()), macro_precision=float(prec[has].mean()),
        macro_recall=float(rec[has].mean()),
        per_class={class_names[i]: dict(support=int(support[i]), precision=float(prec[i]),
                                        recall=float(rec[i]), f1=float(f1[i])) for i in range(n)},
        per_crop=per_crop,
    )


def draw(cm, labels, crops, out_path, figsize, annot_fs, tick_fs, crop_fs, label_fs, dpi, title, title_pad):
    n = len(labels)
    blocks = crop_blocks(crops)
    norm = PowerNorm(0.4, vmin=0, vmax=max(int(cm.max()), 1))
    fig, ax = plt.subplots(figsize=figsize)
    mesh = ax.pcolormesh(np.arange(n + 1), np.arange(n + 1), cm, cmap="Blues", norm=norm,
                         edgecolors="face", linewidth=0.3, rasterized=True)
    ax.set_xlim(0, n)
    ax.set_ylim(n, 0)
    ax.set_aspect("equal")
    for i in range(n):
        for j in range(n):
            v = int(cm[i, j])
            col = "#8a96a3" if v == 0 else ("white" if norm(v) > 0.62 else "#111111")
            ax.text(j + .5, i + .5, str(v), ha="center", va="center", fontsize=annot_fs, color=col,
                    fontweight="bold" if i == j else "normal")
    ax.set_xticks(np.arange(n) + .5)
    ax.set_yticks(np.arange(n) + .5)
    ax.set_xticklabels(labels, rotation=90, fontsize=tick_fs)
    ax.set_yticklabels(labels, fontsize=tick_fs)
    ax.tick_params(length=0, pad=2)
    for s in ax.spines.values():
        s.set_visible(False)
    ax.set_xlabel("Predicted label", fontsize=label_fs, labelpad=6)

    fig.canvas.draw()
    r = fig.canvas.get_renderer()
    wmax = max(t.get_window_extent(r).width for t in ax.get_yticklabels())
    x_left = ax.transAxes.inverted().transform((ax.get_window_extent(r).x0 - wmax - 14, 0))[0]
    ink = "#1b3a57"
    for name, a, b in blocks:
        ax.annotate(name, xy=(x_left, (a + b) / 2), xycoords=("axes fraction", "data"), ha="right",
                    va="center", fontsize=crop_fs, fontweight="bold", color=ink, annotation_clip=False)
        ax.plot([x_left + .004] * 2, [a + .12, b - .12], transform=ax.get_yaxis_transform(),
                color=ink, lw=1.4, clip_on=False)
        ax.annotate(name, xy=((a + b) / 2, -0.35), xycoords="data", ha="center", va="bottom",
                    rotation=90, fontsize=crop_fs, fontweight="bold", color=ink, annotation_clip=False)
        ax.plot([a + .12, b - .12], [-0.15, -0.15], color=ink, lw=1.4, clip_on=False)
    ax.yaxis.set_label_coords(x_left - (0.095 if figsize[0] > 10 else 0.13), 0.5)
    ax.set_ylabel("True label", fontsize=label_fs)

    ax.apply_aspect()
    fig.canvas.draw()
    pos = ax.get_position()
    cax = fig.add_axes([pos.x1 + 0.012, pos.y0, 0.016 if figsize[0] > 10 else 0.022, pos.height])
    cb = fig.colorbar(mesh, cax=cax)
    cb.ax.tick_params(labelsize=tick_fs)
    cb.set_label("Number of images", fontsize=label_fs - 1)
    cb.outline.set_visible(False)
    if title:
        ax.set_title(title, fontsize=label_fs + 3, fontweight="bold", pad=title_pad)
    fig.savefig(out_path, dpi=dpi, bbox_inches="tight", pad_inches=0.06, facecolor="white")
    plt.close(fig)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--csv", default="confusion_matrix.csv")
    ap.add_argument("--out", default="../docs/research_figures")
    ap.add_argument("--model_name", default="MobileViT-Small")
    args = ap.parse_args()

    class_names, cm = load_matrix(args.csv)
    parts = [split_class(c) for c in class_names]
    crops = [p[0] for p in parts]
    labels = [p[1] for p in parts]
    m = compute_metrics(class_names, cm, crops)

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    (out / "evaluation_metrics.json").write_text(json.dumps(m, indent=2), encoding="utf-8")

    n_crops = len(crop_blocks(crops))
    title = (f"CropVision ({args.model_name}) – Confusion Matrix: {len(class_names)} Classes across "
             f"{n_crops} Crops | {m['images']:,} Test Images | Accuracy {100 * m['accuracy']:.2f}% | "
             f"Macro-F1 {m['macro_f1']:.4f}")
    draw(cm, labels, crops, out / "confusion_matrix_overall.png", (17, 16), 9.5, 11, 11, 15, 300, title, 120)
    draw(cm, labels, crops, out / "confusion_matrix_overall_paper.png", (7.16, 6.9), 3.4, 4.6, 4.8, 7, 600,
         None, 0)

    print(f"Images {m['images']:,} | correct {m['correct']:,} | accuracy {100 * m['accuracy']:.2f}% | "
          f"macro-F1 {m['macro_f1']:.4f}")
    print("\n| Crop | Images | Accuracy (%) | Macro-F1 | Cross-crop errors |\n|---|---:|---:|---:|---:|")
    for crop, d in m["per_crop"].items():
        print(f"| {crop} | {d['images']:,} | {100 * d['accuracy']:.2f} | {d['macro_f1']:.4f} | "
              f"{d['cross_crop_errors']} |")
    print(f"\nWrote figures and evaluation_metrics.json to {out.resolve()}")


if __name__ == "__main__":
    main()
