"""Tests for the metrics computed from a real confusion matrix (plot_confusion_matrix.py)."""
import csv
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from plot_confusion_matrix import compute_metrics, crop_blocks, load_matrix, split_class  # noqa: E402

NAMES = ["Apple___scab", "Apple___healthy", "Corn_(maize)___rust", "Corn_(maize)___healthy"]
CM = np.array([[8, 2, 0, 0],
               [1, 9, 0, 0],
               [0, 0, 7, 3],
               [0, 1, 0, 9]])


def _crops():
    return [split_class(n)[0] for n in NAMES]


def test_accuracy_and_totals():
    m = compute_metrics(NAMES, CM, _crops())
    assert m["images"] == 40 and m["correct"] == 33
    assert abs(m["accuracy"] - 33 / 40) < 1e-12


def test_macro_f1_matches_hand_calculation():
    m = compute_metrics(NAMES, CM, _crops())
    f1 = [2 * 8 / (2 * 8 + 1 + 2), 2 * 9 / (2 * 9 + 3 + 1), 2 * 7 / (2 * 7 + 0 + 3), 2 * 9 / (2 * 9 + 3 + 1)]
    assert abs(m["macro_f1"] - sum(f1) / 4) < 1e-12


def test_cross_crop_errors_counted():
    cm = CM.copy()
    cm[1, 2] = 1
    m = compute_metrics(NAMES, cm, _crops())
    assert m["per_crop"]["Apple"]["cross_crop_errors"] == 1
    assert m["per_crop"]["Corn"]["cross_crop_errors"] == 1  # row 3 -> col 1 in CM


def test_crop_blocks_and_names():
    assert crop_blocks(_crops()) == [("Apple", 0, 2), ("Corn", 2, 4)]
    assert split_class("Pepper,_bell___Bacterial_spot") == ("Pepper bell", "Pepper bell Bacterial spot")


def test_load_matrix_roundtrip(tmp_path):
    p = tmp_path / "cm.csv"
    with open(p, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["true/pred"] + NAMES)
        for n, r in zip(NAMES, CM):
            w.writerow([n] + list(map(int, r)))
    names, cm = load_matrix(p)
    assert names == NAMES and (cm == CM).all()
