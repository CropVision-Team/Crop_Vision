"""
Plot REAL training curves from training_history.csv, which train_mobilevit.py now writes
(one row per epoch: epoch, train_loss, val_loss, val_accuracy).

Usage (from the model folder):
    python train_mobilevit.py ...            # writes checkpoints/training_history.csv
    python plot_learning_curves.py --csv checkpoints/training_history.csv --out ../docs/research_figures

Only quantities that were actually measured are drawn. Training accuracy is not logged by the
training script, so it is not plotted.
"""
import argparse
import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--csv", default="checkpoints/training_history.csv")
    ap.add_argument("--out", default="../docs/research_figures")
    ap.add_argument("--model_name", default="MobileViT-Small")
    args = ap.parse_args()

    with open(args.csv, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    if not rows:
        raise SystemExit("History file is empty.")
    ep = [int(r["epoch"]) for r in rows]
    tl = [float(r["train_loss"]) for r in rows]
    vl = [float(r["val_loss"]) for r in rows]
    va = [100 * float(r["val_accuracy"]) for r in rows]
    best = max(range(len(va)), key=va.__getitem__)

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(11, 4.2))
    a1.plot(ep, va, color="#1f6fb2", lw=2, label="Validation accuracy")
    a1.scatter([ep[best]], [va[best]], color="#c0392b", zorder=3,
               label=f"Best: {va[best]:.2f}% (epoch {ep[best]})")
    a1.set_xlabel("Epoch"); a1.set_ylabel("Accuracy (%)"); a1.set_title("Validation accuracy")
    a2.plot(ep, tl, color="#2c3e50", lw=2, label="Training loss")
    a2.plot(ep, vl, color="#e67e22", lw=2, label="Validation loss")
    a2.set_xlabel("Epoch"); a2.set_ylabel("Loss"); a2.set_title("Training and validation loss")
    for a in (a1, a2):
        a.grid(alpha=.25); a.legend(frameon=False)
    fig.suptitle(f"{args.model_name}: training behaviour over {len(ep)} epochs", fontweight="bold")
    fig.tight_layout()
    out = Path(args.out); out.mkdir(parents=True, exist_ok=True)
    fig.savefig(out / "learning_curves_overall.png", dpi=300, bbox_inches="tight", facecolor="white")
    print(f"Wrote {(out / 'learning_curves_overall.png').resolve()}")


if __name__ == "__main__":
    main()
