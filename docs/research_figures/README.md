# Research figures

> **Status: the existing confusion matrices (`confusion_matrix_*.png`, `overall_confusion_matrix.png`) and learning curves
> (`learning_curve_*.png`, `overall_learning_curves.png`) in this folder were produced by simulation scripts
> (random numbers tuned to hit a target accuracy). They are NOT measured results and must not be cited or placed in a paper.**
> The scripts have been removed. Replace these files with real ones, then delete this notice.

## How to produce real figures

```bash
cd model
# 1. Evaluate the real checkpoint on the untouched test split (writes confusion_matrix.csv and misclassified.csv)
python evaluate_test.py --split_dir ./official_test --checkpoint ./checkpoints/mobilevit_best.pt

# 2. Build the confusion-matrix figures and the metrics JSON from that CSV
python plot_confusion_matrix.py --csv confusion_matrix.csv --out ../docs/research_figures

# 3. Training curves (train_mobilevit.py now writes checkpoints/training_history.csv)
python plot_learning_curves.py --csv checkpoints/training_history.csv --out ../docs/research_figures
```

`evaluation_metrics.json` (written in step 2) holds the accuracy, macro-F1, per-class and per-crop numbers.
Quote those numbers in the README, model cards and paper so every figure and table comes from one evaluation.
