"""
Image Verification Module
--------------------------
Runs BEFORE the disease-classification model. Three checks, in order
(cheapest/fastest first so bad images are rejected early):

1. Quality Check   - blur, brightness, resolution
2. Validity Check  - is this actually a plant/leaf (vs random object)?
3. Context Match   - does predicted crop match the expected crop for
                      this record? (checked AFTER classification, so
                      it's wired in from the app layer, not here)

Only (1) and (2) run purely on the image itself; (3) needs the
classification result + the farmer's expected crop, so it's exposed
as a separate helper the app calls after inference.
"""

import cv2
import numpy as np
from dataclasses import dataclass
from typing import Optional

MIN_RESOLUTION = 224          # px, shorter side
BLUR_THRESHOLD = 100.0        # Laplacian variance; below this = too blurry
MIN_BRIGHTNESS = 40           # 0-255 mean brightness
MAX_BRIGHTNESS = 220
MIN_PLANT_PIXEL_RATIO = 0.15  # at least 15% of the image should be plant-colored


@dataclass
class VerificationResult:
    is_valid: bool
    rejection_reason: Optional[str]
    quality_score: dict
    plant_pixel_ratio: float


def _blur_score(gray: np.ndarray) -> float:
    return cv2.Laplacian(gray, cv2.CV_64F).var()


def _brightness_score(gray: np.ndarray) -> float:
    return float(np.mean(gray))


def _plant_pixel_ratio(hsv: np.ndarray) -> float:
    """Rough proxy for 'does this image contain plant material at all'.
    Wider hue range than severity_estimation's leaf mask, since here we
    only need presence, not a clean segmentation."""
    lower = np.array([15, 20, 20])
    upper = np.array([100, 255, 255])
    mask = cv2.inRange(hsv, lower, upper)
    return float(np.count_nonzero(mask)) / mask.size


def verify_image(image_path: str) -> dict:
    img = cv2.imread(image_path)
    if img is None:
        return VerificationResult(
            is_valid=False,
            rejection_reason="File could not be read as an image.",
            quality_score={},
            plant_pixel_ratio=0.0,
        ).__dict__

    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

    # --- 1. Quality Check ---
    if min(h, w) < MIN_RESOLUTION:
        return VerificationResult(
            False,
            f"Image resolution too low ({w}x{h}). Please retake closer to the leaf.",
            {"resolution": (w, h)},
            0.0,
        ).__dict__

    # Brightness is checked BEFORE blur: a dark/underexposed image has
    # naturally low contrast, which depresses the Laplacian variance
    # even when the image isn't actually out of focus. Checking
    # brightness first avoids misreporting "too blurry" for what's
    # really a lighting problem.
    brightness = _brightness_score(gray)
    if brightness < MIN_BRIGHTNESS:
        return VerificationResult(
            False,
            "Image is too dark. Please retake in better lighting.",
            {"brightness": round(brightness, 2)},
            0.0,
        ).__dict__
    if brightness > MAX_BRIGHTNESS:
        return VerificationResult(
            False,
            "Image is overexposed. Please avoid direct glare/flash.",
            {"brightness": round(brightness, 2)},
            0.0,
        ).__dict__

    blur = _blur_score(gray)
    if blur < BLUR_THRESHOLD:
        return VerificationResult(
            False,
            "Image is too blurry. Please hold the camera steady and refocus.",
            {"blur_score": round(blur, 2), "brightness": round(brightness, 2)},
            0.0,
        ).__dict__

    # --- 2. Validity Check (is this actually plant material?) ---
    ratio = _plant_pixel_ratio(hsv)
    if ratio < MIN_PLANT_PIXEL_RATIO:
        return VerificationResult(
            False,
            "No crop leaf detected in this image. Please photograph a leaf directly.",
            {"blur_score": round(blur, 2), "brightness": round(brightness, 2)},
            round(ratio, 3),
        ).__dict__

    return VerificationResult(
        is_valid=True,
        rejection_reason=None,
        quality_score={"blur_score": round(blur, 2), "brightness": round(brightness, 2),
                        "resolution": (w, h)},
        plant_pixel_ratio=round(ratio, 3),
    ).__dict__


def check_context_match(predicted_crop: str, expected_crop: Optional[str]) -> dict:
    """Stage 3: Context Match. Call this AFTER the classifier runs,
    only when the app/record has an expected crop type (e.g. the
    farmer's field profile says 'Tomato' but the model predicted
    'Potato')."""
    if not expected_crop:
        return {"context_match": True, "note": "No expected crop set - skipped."}
    match = predicted_crop.strip().lower() == expected_crop.strip().lower()
    return {
        "context_match": match,
        "note": None if match else (
            f"Predicted crop '{predicted_crop}' does not match expected "
            f"crop '{expected_crop}' for this field/record."
        ),
    }


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python image_verification.py <image_path>")
        sys.exit(1)
    print(verify_image(sys.argv[1]))
