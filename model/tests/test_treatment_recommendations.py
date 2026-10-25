"""Step 41: Test treatment recommendations."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from treatment_recommendations import get_recommendation, TREATMENT_MAP
from supported_crops import all_class_names


def test_known_disease_severity_combo_returns_specific_advice():
    result = get_recommendation("Tomato___Early_blight", "G2")
    assert result["matched"] is True
    assert "fungicide" in result["recommendation"].lower()


def test_unknown_class_falls_back_gracefully():
    result = get_recommendation("Strawberry___Leaf_scorch", "G1")
    assert result["matched"] is False
    assert "recommendation" in result
    assert "prevention" in result


def test_healthy_classifier_with_nonzero_severity_flags_contradiction():
    # A model saying "healthy" combined with a severity estimator
    # finding G2 damage is a real contradiction the app should
    # surface, not silently paper over.
    result = get_recommendation("Tomato___healthy", "G2")
    assert result["matched"] is False
    assert result.get("warning") == "classifier/severity mismatch"


def test_diseased_classifier_with_g0_severity_flags_contradiction():
    # Reverse case, found via real-world testing with a pepper bell
    # bacterial-spot photo: a diagnosed disease combined with G0
    # (0% affected) severity is equally a contradiction, since a real
    # disease should never register as fully healthy. Both directions
    # need the same clear handling, not just the healthy->diseased one.
    result = get_recommendation("Tomato___Early_blight", "G0")
    assert result["matched"] is False
    assert result.get("warning") == "classifier/severity mismatch"


def test_healthy_g0_is_consistent():
    result = get_recommendation("Tomato___healthy", "G0")
    assert result["matched"] is True


@pytest.mark.parametrize("disease_class", list(TREATMENT_MAP.keys()))
def test_every_filled_in_disease_has_no_empty_strings(disease_class):
    for stage, entry in TREATMENT_MAP[disease_class].items():
        assert entry["recommendation"].strip() != "", f"{disease_class}/{stage} has empty recommendation"
        assert entry["prevention"].strip() != "", f"{disease_class}/{stage} has empty prevention"


def test_every_non_healthy_filled_disease_covers_g1_g2_g3():
    # Coverage check: for diseases we HAVE filled in, make sure all
    # three non-healthy severity stages exist - a disease with only
    # G1 and G3 filled but missing G2 would silently fall back to the
    # generic message for moderate cases, which is worse than for
    # mild/critical ones since G2 is the most common real-world case.
    for disease_class, stages in TREATMENT_MAP.items():
        if disease_class.endswith("healthy"):
            continue
        missing = {"G1", "G2", "G3"} - set(stages.keys())
        assert not missing, f"{disease_class} is missing severity stages: {missing}"


def test_all_treatment_map_keys_match_supported_crops():
    # Regression test: caught a real bug where "Corn___Cercospora_leaf_spot
    # Gray_leaf_spot" (supported_crops.py, matching the real PlantVillage
    # folder name) didn't match "Corn___Cercospora leaf spot Gray leaf spot"
    # (treatment_recommendations.py, missing underscores). A name mismatch
    # like this means a correct model prediction would silently fail to
    # find its treatment entry and fall back to generic advice.
    supported = set(all_class_names())
    treated = set(TREATMENT_MAP.keys())
    orphaned_treatment_keys = treated - supported
    assert not orphaned_treatment_keys, (
        f"treatment_recommendations.py has keys not in supported_crops.py "
        f"(likely a naming mismatch): {orphaned_treatment_keys}"
    )


def test_every_supported_class_has_at_least_fallback_coverage():
    # Every class the model can output should resolve to SOME
    # recommendation (even if it's the generic fallback) - never crash.
    for class_name in all_class_names():
        result = get_recommendation(class_name, "G1")
        assert "recommendation" in result
        assert "prevention" in result
