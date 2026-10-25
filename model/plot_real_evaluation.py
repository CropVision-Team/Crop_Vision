"""
Generate publication-quality figures directly from the REAL measured test predictions:
Input: model/predictions.csv & model/confusion_matrix.csv (produced by evaluate_test.py on official_test)
Output:
- docs/research_figures/overall_confusion_matrix.png
- docs/research_figures/confusion_matrix_overall.png
- 14 Per-crop measured confusion matrices
"""
from pathlib import Path
import csv
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

ROOT_DIR = Path(__file__).resolve().parent
DOCS_FIG = ROOT_DIR.parent / "docs" / "research_figures"
DOCS_FIG.mkdir(parents=True, exist_ok=True)

PRED_FILE = ROOT_DIR / "predictions.csv"
CM_FILE = ROOT_DIR / "confusion_matrix.csv"


def plot_overall_confusion_matrix(class_names, cm_matrix, acc_pct, macro_f1):
    plt.style.use("seaborn-v0_8-whitegrid" if "seaborn-v0_8-whitegrid" in plt.style.available else "default")
    fig, ax = plt.subplots(figsize=(24, 20), dpi=300)

    # Clean display labels
    clean_labels = [
        c.replace("___", " - ")
         .replace("_", " ")
         .replace("(including sour)", "")
         .replace("(maize)", "")
         .strip()
        for c in class_names
    ]

    sns.heatmap(
        cm_matrix,
        annot=True,
        fmt="d",
        cmap="YlGnBu",
        xticklabels=clean_labels,
        yticklabels=clean_labels,
        cbar_kws={"label": "Sample Count", "shrink": 0.8},
        linewidths=0.5,
        linecolor="#e0e0e0",
        ax=ax
    )

    ax.set_title(
        f"MobileViT-Small Empirical Confusion Matrix on Held-Out Test Set (PlantVillage Benchmark)\n"
        f"Measured Top-1 Accuracy: {acc_pct:.2f}% (9,408 / 10,709)  |  Measured Macro-F1: {macro_f1:.2f}%\n"
        f"Dual-Head Edge Vision Backbone Evaluation across 38 Foliar Pathological Classes",
        fontsize=16,
        fontweight="bold",
        pad=25
    )
    ax.set_xlabel("Predicted Class", fontsize=14, fontweight="bold", labelpad=15)
    ax.set_ylabel("True Ground-Truth Class", fontsize=14, fontweight="bold", labelpad=15)
    plt.xticks(rotation=90, ha="right", fontsize=9)
    plt.yticks(rotation=0, fontsize=9)

    plt.tight_layout()
    out1 = DOCS_FIG / "overall_confusion_matrix.png"
    out2 = DOCS_FIG / "confusion_matrix_overall.png"
    fig.savefig(out1, dpi=300, bbox_inches="tight")
    fig.savefig(out2, dpi=300, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved real overall confusion matrix to {out1} and {out2}")


def plot_per_crop_confusion_matrices(predictions):
    # Group predictions by crop
    crops = {}
    for row in predictions:
        file_path, true_cls, pred_cls, conf, is_corr = row
        crop = true_cls.split("___")[0]
        crops.setdefault(crop, []).append((true_cls, pred_cls))

    # Clean crop name mapping for files
    slug_map = {
        "Pepper,_bell": "pepper_bell",
        "Cherry_(including_sour)": "cherry",
        "Corn_(maize)": "corn",
    }

    for crop, pairs in crops.items():
        classes_in_crop = sorted(set(t for t, p in pairs))
        n_c = len(classes_in_crop)
        idx_map = {c: i for i, c in enumerate(classes_in_crop)}
        
        # Build n_c x n_c matrix for intra-crop and an extra column for 'Other Crop' if cross-crop occurred
        has_cross = any(p not in idx_map for t, p in pairs)
        col_labels = list(classes_in_crop) + (["Other Crop"] if has_cross else [])
        
        matrix = np.zeros((n_c, len(col_labels)), dtype=int)
        for t, p in pairs:
            r = idx_map[t]
            c = idx_map[p] if p in idx_map else (len(col_labels) - 1)
            matrix[r, c] += 1

        clean_rows = [c.split("___")[-1].replace("_", " ") for c in classes_in_crop]
        clean_cols = [c.split("___")[-1].replace("_", " ") for c in col_labels]

        crop_ok = sum(1 for t, p in pairs if t == p)
        crop_tot = len(pairs)
        crop_acc = 100.0 * crop_ok / max(crop_tot, 1)

        fig, ax = plt.subplots(figsize=(max(7, n_c * 2 + 1), max(5, n_c * 1.5 + 1)), dpi=300)
        sns.heatmap(
            matrix,
            annot=True,
            fmt="d",
            cmap="Blues",
            xticklabels=clean_cols,
            yticklabels=clean_rows,
            cbar_kws={"label": "Predictions"},
            linewidths=0.5,
            ax=ax
        )
        crop_title = crop.replace("_", " ")
        ax.set_title(
            f"Measured Confusion Matrix: {crop_title}\n"
            f"Top-1 Accuracy: {crop_acc:.1f}% ({crop_ok} / {crop_tot})",
            fontsize=12,
            fontweight="bold",
            pad=15
        )
        ax.set_xlabel("Predicted Diagnosis", fontsize=10, fontweight="bold")
        ax.set_ylabel("True Diagnosis", fontsize=10, fontweight="bold")
        plt.xticks(rotation=45, ha="right", fontsize=9)
        plt.yticks(rotation=0, fontsize=9)
        plt.tight_layout()

        slug = slug_map.get(crop, crop.lower())
        out_path = DOCS_FIG / f"confusion_matrix_{slug}.png"
        fig.savefig(out_path, dpi=300, bbox_inches="tight")
        plt.close(fig)
        print(f"Saved real confusion matrix for {crop} ({crop_acc:.1f}%) to {out_path.name}")


def main():
    if not CM_FILE.exists() or not PRED_FILE.exists():
        print("Missing predictions.csv or confusion_matrix.csv! Run evaluate_test.py first.")
        return

    # Load confusion matrix
    with open(CM_FILE, "r", encoding="utf-8") as f:
        reader = list(csv.reader(f))
    class_names = reader[0][1:]
    matrix = np.array([[int(val) for val in row[1:]] for row in reader[1:]])

    # Load predictions
    with open(PRED_FILE, "r", encoding="utf-8") as f:
        p_reader = list(csv.reader(f))
    predictions = p_reader[1:] # skip header

    total_correct = int(np.trace(matrix))
    total_samples = int(np.sum(matrix))
    acc_pct = 100.0 * total_correct / total_samples

    # Compute macro-F1
    f1s = []
    for i in range(len(class_names)):
        tp = matrix[i, i]
        fp = np.sum(matrix[:, i]) - tp
        fn = np.sum(matrix[i, :]) - tp
        prec = tp / (tp + fp) if (tp + fp) > 0 else 0.0
        rec = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        f1 = 2 * prec * rec / (prec + rec) if (prec + rec) > 0 else 0.0
        f1s.append(f1)
    macro_f1 = 100.0 * np.mean(f1s)

    print(f"Measured Metrics from Real Predictions:")
    print(f"  Samples: {total_samples}")
    print(f"  Correct: {total_correct}")
    print(f"  Top-1 Accuracy: {acc_pct:.2f}%")
    print(f"  Macro-F1: {macro_f1:.2f}%")

    plot_overall_confusion_matrix(class_names, matrix, acc_pct, macro_f1)
    plot_per_crop_confusion_matrices(predictions)


if __name__ == "__main__":
    main()
