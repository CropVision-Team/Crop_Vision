"""
Severity Estimation Module
---------------------------
Since no public dataset provides G0-G3 severity labels for most crops,
severity is estimated using classical image processing rather than a
second deep-learning head:

    1. Segment the leaf from the background.
    2. Within the leaf mask, segment "diseased" pixels (brown/yellow/
       necrotic tones) vs "healthy" pixels (green tones) using HSV
       thresholds.
    3. severity_percent = diseased_pixels / total_leaf_pixels * 100
    4. Map the percentage to a G0-G3 stage using thresholds.

This is a documented, defensible technique used in plant-pathology
literature (e.g. Wang et al. 2017 style severity grading) and avoids
having to hand-label thousands of images per crop.

Usage:
    from severity_estimation import estimate_severity
    result = estimate_severity("leaf.jpg")
    print(result)  # {'severity_percent': 34.2, 'stage': 'G2', 'label': 'Moderate Infection'}
"""

import cv2
import numpy as np
from dataclasses import dataclass


# Default severity thresholds - tune these against a small hand-checked
# validation set of ~50-100 images per crop before finalizing.
DEFAULT_SEVERITY_THRESHOLDS = {
    "G0": (0, 2),      # Healthy: <2% diseased area
    "G1": (2, 15),     # Mild
    "G2": (15, 40),    # Moderate
    "G3": (40, 100),   # Critical
}

# Per-crop threshold overrides. Different crops/diseases can progress
# very differently at the same visible-damage percentage (e.g. a fast,
# aggressive blight vs a slow-spreading rust), so the same 15%
# "moderate" cutoff isn't necessarily right for every crop. Only crops
# that genuinely need a different cutoff are listed here - anything
# not listed falls back to DEFAULT_SEVERITY_THRESHOLDS. This dict is
# the place to encode that domain knowledge once it's validated;
# empty for now since finalizing crop-specific cutoffs needs the
# hand-checked validation set mentioned above, not guessed numbers.
CROP_SEVERITY_THRESHOLD_OVERRIDES: dict = {
    # Example of how to add one, once validated:
    # "Tomato": {"G0": (0, 2), "G1": (2, 12), "G2": (12, 35), "G3": (35, 100)},
}


def get_severity_thresholds(crop_name: str | None = None) -> dict:
    """Returns this crop's threshold set, falling back to the default
    if no crop-specific override is defined."""
    if crop_name and crop_name in CROP_SEVERITY_THRESHOLD_OVERRIDES:
        return CROP_SEVERITY_THRESHOLD_OVERRIDES[crop_name]
    return DEFAULT_SEVERITY_THRESHOLDS

SEVERITY_LABELS = {
    "G0": "Healthy",
    "G1": "Mild Infection",
    "G2": "Moderate Infection",
    "G3": "Critical Infection",
}


@dataclass
class SeverityResult:
    severity_percent: float
    stage: str
    label: str
    leaf_pixel_count: int
    diseased_pixel_count: int


def _segment_leaf_mask(hsv: np.ndarray) -> np.ndarray:
    """Leaf area = healthy green tissue UNION diseased/necrotic tissue.

    IMPORTANT: diseased spots are often brown/reddish/dark and can fall
    completely outside a narrow "green leaf" hue range. If leaf area is
    computed from green-only pixels, diseased regions get excluded from
    the denominator entirely - this silently deflates the severity
    percentage (verified empirically: a ~25% blotched synthetic leaf
    measured as ~3% before this fix). So the leaf mask must be the
    union of both healthy-tissue and diseased-tissue color ranges.
    """
    green_lower = np.array([25, 30, 20])
    green_upper = np.array([95, 255, 255])
    green_mask = cv2.inRange(hsv, green_lower, green_upper)

    disease_mask = _segment_diseased_mask(hsv)

    leaf_mask = cv2.bitwise_or(green_mask, disease_mask)
    kernel = np.ones((5, 5), np.uint8)
    leaf_mask = cv2.morphologyEx(leaf_mask, cv2.MORPH_CLOSE, kernel)
    leaf_mask = cv2.morphologyEx(leaf_mask, cv2.MORPH_OPEN, kernel)
    return leaf_mask


def _segment_diseased_mask(hsv: np.ndarray) -> np.ndarray:
    """Brown/yellow/necrotic-spot pixels, independent of the leaf mask
    (the leaf mask is built FROM this, so it can't depend on it).
    Two sub-ranges: reddish-brown necrotic tissue (hue wraps near 0)
    and yellow/brown chlorotic tissue (hue ~10-30)."""
    lower1 = np.array([0, 30, 15])
    upper1 = np.array([30, 255, 200])
    mask1 = cv2.inRange(hsv, lower1, upper1)

    # Wrap-around reds (hue near 179) - necrotic tissue can skew this
    # way depending on camera white balance.
    lower2 = np.array([170, 30, 15])
    upper2 = np.array([179, 255, 200])
    mask2 = cv2.inRange(hsv, lower2, upper2)

    return cv2.bitwise_or(mask1, mask2)


def _percent_to_stage(pct: float, thresholds: dict) -> str:
    for stage, (low, high) in thresholds.items():
        if low <= pct < high:
            return stage
    return "G3"  # pct == 100 edge case


def estimate_severity(image_path: str, crop_name: str | None = None) -> dict:
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Could not read image: {image_path}")

    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    leaf_mask = _segment_leaf_mask(hsv)
    leaf_pixels = int(np.count_nonzero(leaf_mask))

    if leaf_pixels == 0:
        # Should not normally happen if Image Verification already
        # confirmed a valid leaf - this is a safety fallback.
        return {
            "severity_percent": 0.0,
            "stage": "G0",
            "label": "Healthy",
            "leaf_pixel_count": 0,
            "diseased_pixel_count": 0,
            "warning": "No leaf area detected - check upstream verification.",
        }

    disease_mask = cv2.bitwise_and(_segment_diseased_mask(hsv), leaf_mask)
    disease_pixels = int(np.count_nonzero(disease_mask))

    pct = round((disease_pixels / leaf_pixels) * 100, 2)
    thresholds = get_severity_thresholds(crop_name)
    stage = _percent_to_stage(pct, thresholds)

    result = SeverityResult(
        severity_percent=pct,
        stage=stage,
        label=SEVERITY_LABELS[stage],
        leaf_pixel_count=leaf_pixels,
        diseased_pixel_count=disease_pixels,
    )
    return result.__dict__


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python severity_estimation.py <image_path>")
        sys.exit(1)
    print(estimate_severity(sys.argv[1]))
