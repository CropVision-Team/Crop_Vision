"""Integration tests: full run_diagnosis() pipeline, matching the
Final System Flow diagram end-to-end."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from pipeline import run_diagnosis


def test_invalid_image_stops_at_verification(blurry_leaf):
    result = run_diagnosis(blurry_leaf)
    assert result["stage_reached"] == "image_verification"
    assert result["is_valid_leaf"] is False
    assert "predicted_disease" not in result  # pipeline must not continue past rejection


def test_valid_image_completes_full_pipeline(moderate_leaf):
    result = run_diagnosis(moderate_leaf)
    assert result["stage_reached"] == "complete"
    assert result["is_valid_leaf"] is True
    assert result["predicted_disease"] is not None
    assert result["severity_stage"] in {"G0", "G1", "G2", "G3"}
    assert result["treatment"] is not None
    assert result["prevention"] is not None


def test_context_match_true_when_crop_matches(moderate_leaf):
    # classify_disease_MOCK always returns a Tomato class currently.
    result = run_diagnosis(moderate_leaf, expected_crop="Tomato")
    assert result["context_match"]["context_match"] is True


def test_context_match_false_when_crop_mismatches(moderate_leaf):
    result = run_diagnosis(moderate_leaf, expected_crop="Potato")
    assert result["context_match"]["context_match"] is False
    assert result["context_match"]["note"] is not None
    # Mismatch should be flagged, not crash the pipeline:
    assert result["stage_reached"] == "complete"


def test_no_expected_crop_skips_context_check(moderate_leaf):
    result = run_diagnosis(moderate_leaf, expected_crop=None)
    assert result["context_match"]["context_match"] is True
    assert "skipped" in result["context_match"]["note"].lower()


def test_severity_result_consistent_with_standalone_estimator(moderate_leaf):
    from severity_estimation import estimate_severity
    standalone = estimate_severity(moderate_leaf)
    piped = run_diagnosis(moderate_leaf)
    assert piped["severity_stage"] == standalone["stage"]
    assert piped["severity_percent"] == standalone["severity_percent"]


def test_low_confidence_classification_flags_unknown_crop(moderate_leaf, monkeypatch):
    # Simulates what should happen once real inference replaces the
    # mock: a crop the model wasn't trained on should surface as
    # "not recognized" rather than a confident-looking wrong guess.
    # The mock always returns 0.91 confidence, so this test patches it
    # to return a low-confidence result the way real out-of-distribution
    # inference would.
    import pipeline as pipeline_module
    monkeypatch.setattr(
        pipeline_module, "classify_disease_MOCK",
        lambda image_path: ("SomeUnknownCrop___disease", 0.35),
    )
    result = run_diagnosis(moderate_leaf)
    assert result["stage_reached"] == "unknown_crop"
    assert result["predicted_disease"] is None
    assert "message" in result
    # Must stop BEFORE severity/treatment lookup - those keys should
    # not appear at all for an unrecognized crop.
    assert "severity_stage" not in result
    assert "treatment" not in result


def test_high_confidence_classification_proceeds_normally(moderate_leaf, monkeypatch):
    import pipeline as pipeline_module
    monkeypatch.setattr(
        pipeline_module, "classify_disease_MOCK",
        lambda image_path: ("Tomato___Early_blight", 0.85),
    )
    result = run_diagnosis(moderate_leaf)
    assert result["stage_reached"] == "complete"
    assert result["predicted_disease"] == "Tomato___Early_blight"
