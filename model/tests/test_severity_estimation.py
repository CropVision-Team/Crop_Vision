"""Step 40: Test G0-G3 severity."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from severity_estimation import estimate_severity


def test_healthy_leaf_is_g0(healthy_leaf):
    result = estimate_severity(healthy_leaf)
    assert result["stage"] == "G0"
    assert result["severity_percent"] < 2


def test_mild_leaf_is_g1(mild_leaf):
    result = estimate_severity(mild_leaf)
    assert result["stage"] == "G1"
    assert 2 <= result["severity_percent"] < 15


def test_moderate_leaf_is_g2(moderate_leaf):
    result = estimate_severity(moderate_leaf)
    assert result["stage"] == "G2"
    assert 15 <= result["severity_percent"] < 40


def test_critical_leaf_is_g3(critical_leaf):
    result = estimate_severity(critical_leaf)
    assert result["stage"] == "G3"
    assert result["severity_percent"] >= 40


def test_severity_increases_monotonically_with_blotch_count(
    healthy_leaf, mild_leaf, moderate_leaf, critical_leaf
):
    # Sanity check on the underlying measurement, not just the
    # threshold buckets: more diseased area should always mean a
    # higher percentage, regardless of which G-stage it lands in.
    pcts = [
        estimate_severity(healthy_leaf)["severity_percent"],
        estimate_severity(mild_leaf)["severity_percent"],
        estimate_severity(moderate_leaf)["severity_percent"],
        estimate_severity(critical_leaf)["severity_percent"],
    ]
    assert pcts == sorted(pcts), f"Severity percentages not monotonically increasing: {pcts}"


def test_diseased_pixels_never_exceed_leaf_pixels(critical_leaf):
    result = estimate_severity(critical_leaf)
    assert result["diseased_pixel_count"] <= result["leaf_pixel_count"]


def test_severity_percent_is_bounded(critical_leaf):
    result = estimate_severity(critical_leaf)
    assert 0 <= result["severity_percent"] <= 100
