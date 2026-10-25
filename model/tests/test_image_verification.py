"""Step 38: Test valid/invalid images."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from image_verification import verify_image


def test_healthy_leaf_passes(healthy_leaf):
    result = verify_image(healthy_leaf)
    assert result["is_valid"] is True
    assert result["rejection_reason"] is None


def test_diseased_leaf_still_passes_verification(moderate_leaf):
    # Verification only checks quality/validity, not disease presence -
    # a diseased leaf is still a valid photo to analyze.
    result = verify_image(moderate_leaf)
    assert result["is_valid"] is True


def test_blurry_image_rejected(blurry_leaf):
    result = verify_image(blurry_leaf)
    assert result["is_valid"] is False
    assert "blurry" in result["rejection_reason"].lower()


def test_dark_image_rejected_as_dark_not_blurry(dark_leaf):
    # Regression test for the bug found during Phase 2 manual testing:
    # dark images were being misreported as "too blurry" because low
    # contrast depresses the Laplacian variance score too.
    result = verify_image(dark_leaf)
    assert result["is_valid"] is False
    assert "dark" in result["rejection_reason"].lower()
    assert "blurry" not in result["rejection_reason"].lower()


def test_overexposed_image_rejected(overexposed_leaf):
    result = verify_image(overexposed_leaf)
    assert result["is_valid"] is False
    assert "overexposed" in result["rejection_reason"].lower()


def test_non_plant_image_rejected(non_plant_image):
    result = verify_image(non_plant_image)
    assert result["is_valid"] is False
    assert "leaf" in result["rejection_reason"].lower() or "detected" in result["rejection_reason"].lower()


def test_low_resolution_image_rejected(low_resolution_image):
    result = verify_image(low_resolution_image)
    assert result["is_valid"] is False
    assert "resolution" in result["rejection_reason"].lower()


def test_nonexistent_file_handled_gracefully():
    result = verify_image("/tmp/does_not_exist_12345.jpg")
    assert result["is_valid"] is False
    assert result["rejection_reason"] is not None
