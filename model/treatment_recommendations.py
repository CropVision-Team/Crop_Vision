"""
Treatment & Prevention Recommendations
-----------------------------------------
Disease -> Severity Stage -> Recommendation mapping (Phase 3, steps 14-16).

Keys MUST match the raw class names in supported_crops.py exactly
(these are the same strings the trained model will output), not
human-friendly display names - this is what step 17 ("connect
recommendations to AI prediction") depends on.

Healthy classes only need a G0 entry (a model should never output G1-G3
severity for a class it already called healthy - that's a contradiction
the app layer should treat as a bug, not silently accept).

This starter set covers Tomato and Potato in full detail (the two most
common crops in the spec's example) plus representative entries for
Apple/Corn/Grape. Fill in the remaining ones the same way before your
final submission - the get_recommendation() function below falls back
to a generic message for anything not yet filled in, so nothing crashes
in the meantime.
"""

from typing import Optional

TREATMENT_MAP: dict[str, dict[str, dict[str, str]]] = {

    # ---------------- TOMATO ----------------
    "Tomato___healthy": {
        "G0": {
            "recommendation": "No treatment needed. Plant is healthy.",
            "prevention": "Continue regular monitoring, proper spacing, and balanced fertilization.",
        },
    },
    "Tomato___Early_blight": {
        "G1": {
            "recommendation": "Remove affected lower leaves. Apply a preventive copper-based fungicide.",
            "prevention": "Mulch soil to prevent spore splash-back onto leaves.",
        },
        "G2": {
            "recommendation": "Apply copper-based or chlorothalonil fungicide every 7-10 days. Remove and destroy affected leaves.",
            "prevention": "Rotate crops annually; avoid planting tomatoes/potatoes in the same soil consecutively.",
        },
        "G3": {
            "recommendation": "Apply systemic fungicide immediately. Remove severely affected plants to prevent spread. Consult local agricultural extension officer.",
            "prevention": "Consider resistant tomato varieties for the next planting cycle.",
        },
    },
    "Tomato___Late_blight": {
        "G1": {
            "recommendation": "Apply preventive fungicide (mancozeb or copper-based).",
            "prevention": "Improve field drainage and airflow between plants.",
        },
        "G2": {
            "recommendation": "Apply systemic fungicide (metalaxyl-based). Remove infected foliage immediately.",
            "prevention": "Avoid working in fields when foliage is wet to reduce spread.",
        },
        "G3": {
            "recommendation": "Urgent: remove and destroy infected plants entirely. Apply fungicide to remaining healthy plants as a barrier.",
            "prevention": "Late blight can destroy a field within days - report to local agri-extension for regional alerts.",
        },
    },
    "Tomato___Bacterial_spot": {
        "G1": {
            "recommendation": "Apply copper-based bactericide. Avoid handling wet plants.",
            "prevention": "Use certified disease-free seeds/transplants.",
        },
        "G2": {
            "recommendation": "Increase copper spray frequency to every 5-7 days. Remove severely spotted leaves.",
            "prevention": "Avoid overhead irrigation; water at the base of plants.",
        },
        "G3": {
            "recommendation": "Remove and destroy heavily infected plants. Apply bactericide to remaining crop.",
            "prevention": "Rotate with non-solanaceous crops for at least 2 years.",
        },
    },
    "Tomato___Leaf_Mold": {
        "G1": {
            "recommendation": "Improve greenhouse/field ventilation. Apply fungicide if humidity remains high.",
            "prevention": "Reduce humidity around plants; increase plant spacing.",
        },
        "G2": {
            "recommendation": "Apply fungicide (chlorothalonil or copper-based). Remove affected leaves.",
            "prevention": "Avoid leaf wetness overnight - water early in the day.",
        },
        "G3": {
            "recommendation": "Apply systemic fungicide immediately; heavy leaf mold can severely reduce yield.",
            "prevention": "Use resistant tomato varieties in humid climates.",
        },
    },
    "Tomato___Septoria_leaf_spot": {
        "G1": {
            "recommendation": "Remove lower affected leaves. Apply preventive fungicide.",
            "prevention": "Mulch to prevent soil splash onto lower leaves.",
        },
        "G2": {
            "recommendation": "Apply fungicide every 7-10 days. Remove and destroy infected debris.",
            "prevention": "Avoid working among wet plants to prevent spread.",
        },
        "G3": {
            "recommendation": "Apply fungicide immediately; consider removing severely defoliated plants.",
            "prevention": "Practice 2-3 year crop rotation away from tomato/potato.",
        },
    },
    "Tomato___Spider_mites Two-spotted_spider_mite": {
        "G1": {
            "recommendation": "Spray with insecticidal soap or neem oil.",
            "prevention": "Keep plants well-watered - mites thrive in drought-stressed plants.",
        },
        "G2": {
            "recommendation": "Apply miticide. Introduce predatory mites if using biological control.",
            "prevention": "Avoid excessive nitrogen fertilization, which favors mite reproduction.",
        },
        "G3": {
            "recommendation": "Apply targeted miticide immediately; heavy infestation can defoliate plants rapidly.",
            "prevention": "Regularly inspect undersides of leaves for early detection.",
        },
    },
    "Tomato___Target_Spot": {
        "G1": {
            "recommendation": "Apply preventive fungicide; remove affected leaves.",
            "prevention": "Ensure good air circulation between plants.",
        },
        "G2": {
            "recommendation": "Apply fungicide (azoxystrobin or chlorothalonil-based) every 7-10 days.",
            "prevention": "Avoid overhead watering; remove crop debris after harvest.",
        },
        "G3": {
            "recommendation": "Apply fungicide immediately and remove severely infected plant material.",
            "prevention": "Rotate crops and avoid dense planting in future seasons.",
        },
    },
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus": {
        "G1": {
            "recommendation": "Control whitefly vectors with insecticidal soap; remove affected leaves.",
            "prevention": "Use whitefly-proof netting/screens in nursery stage.",
        },
        "G2": {
            "recommendation": "Apply systemic insecticide to control whitefly population. Remove heavily symptomatic plants.",
            "prevention": "Use reflective mulches to repel whiteflies.",
        },
        "G3": {
            "recommendation": "Remove and destroy severely infected plants immediately - no cure exists once systemic. Focus on protecting remaining crop from whiteflies.",
            "prevention": "Plant virus-resistant tomato varieties in future seasons.",
        },
    },
    "Tomato___Tomato_mosaic_virus": {
        "G1": {
            "recommendation": "Remove affected leaves; disinfect tools between plants (virus spreads via contact).",
            "prevention": "Wash hands and tools with soap before handling plants.",
        },
        "G2": {
            "recommendation": "Remove moderately affected plants if spread is increasing. No chemical cure exists.",
            "prevention": "Avoid tobacco product use near plants (a known transmission source).",
        },
        "G3": {
            "recommendation": "Remove and destroy severely infected plants to protect the rest of the field.",
            "prevention": "Use certified virus-free seed for future planting.",
        },
    },

    # ---------------- POTATO ----------------
    "Potato___healthy": {
        "G0": {
            "recommendation": "No treatment needed. Plant is healthy.",
            "prevention": "Continue regular monitoring and good field hygiene.",
        },
    },
    "Potato___Early_blight": {
        "G1": {
            "recommendation": "Apply preventive fungicide. Remove lower affected leaves.",
            "prevention": "Ensure balanced fertilization - avoid nitrogen deficiency, which increases susceptibility.",
        },
        "G2": {
            "recommendation": "Apply fungicide (chlorothalonil or mancozeb) every 7-10 days.",
            "prevention": "Rotate with non-host crops for at least 2 years.",
        },
        "G3": {
            "recommendation": "Apply fungicide immediately; consider early harvest if tuber bulking is complete.",
            "prevention": "Use certified disease-free seed potatoes.",
        },
    },
    "Potato___Late_blight": {
        "G1": {
            "recommendation": "Apply preventive fungicide immediately - late blight spreads extremely fast.",
            "prevention": "Monitor weather forecasts; blight thrives in cool, wet conditions.",
        },
        "G2": {
            "recommendation": "Apply systemic fungicide. Remove and destroy infected foliage.",
            "prevention": "Improve field drainage and plant spacing for airflow.",
        },
        "G3": {
            "recommendation": "Urgent: destroy infected plants to prevent field-wide loss. This disease caused historic famines - treat as emergency.",
            "prevention": "Report outbreaks to local agricultural extension for regional monitoring.",
        },
    },

    # ---------------- APPLE ----------------
    "Apple___healthy": {
        "G0": {
            "recommendation": "No treatment needed.",
            "prevention": "Prune trees to improve air circulation.",
        },
    },
    "Apple___Black_rot": {
        "G1": {
            "recommendation": "Remove mummified fruit and cankers from tree.",
            "prevention": "Sanitize pruning tools between cuts.",
        },
        "G2": {
            "recommendation": "Apply fungicide spray program (captan or myclobutanil-based) during growing season.",
            "prevention": "Remove nearby wild/abandoned apple trees that can host the fungus.",
        },
        "G3": {
            "recommendation": "Aggressive pruning of infected branches. Apply fungicide immediately.",
            "prevention": "Consider resistant apple cultivars for future plantings.",
        },
    },
    "Apple___Apple_scab": {
        "G1": {
            "recommendation": "Apply preventive fungicide at green-tip stage.",
            "prevention": "Rake and destroy fallen leaves in autumn (fungus overwinters there).",
        },
        "G2": {
            "recommendation": "Apply fungicide (myclobutanil or captan) every 7-14 days through the season.",
            "prevention": "Prune for better air circulation and sunlight penetration.",
        },
        "G3": {
            "recommendation": "Apply fungicide immediately; heavy defoliation risk affects fruit yield next season too.",
            "prevention": "Plant scab-resistant apple varieties.",
        },
    },
    "Apple___Cedar_apple_rust": {
        "G1": {
            "recommendation": "Apply preventive fungicide in spring when orange gall spores are active nearby.",
            "prevention": "Remove nearby juniper/cedar trees within 2 miles if feasible (alternate host).",
        },
        "G2": {
            "recommendation": "Apply fungicide (myclobutanil-based) every 10-14 days during spring.",
            "prevention": "Choose rust-resistant apple varieties for new plantings.",
        },
        "G3": {
            "recommendation": "Apply fungicide immediately and remove heavily infected leaves.",
            "prevention": "Coordinate with neighbors to remove alternate juniper hosts in the area.",
        },
    },

    # ---------------- CORN ----------------
    "Corn_(maize)___healthy": {
        "G0": {
            "recommendation": "No treatment needed.",
            "prevention": "Practice crop rotation with non-host crops.",
        },
    },
    "Corn_(maize)___Northern_Leaf_Blight": {
        "G1": {
            "recommendation": "Monitor closely; apply fungicide if weather remains humid.",
            "prevention": "Use resistant hybrid seed varieties where available.",
        },
        "G2": {
            "recommendation": "Apply foliar fungicide (strobilurin or triazole-based).",
            "prevention": "Till under crop residue after harvest to reduce fungal spores.",
        },
        "G3": {
            "recommendation": "Apply fungicide immediately; yield loss risk is high at this stage.",
            "prevention": "Rotate to soybean or other non-host crop next season.",
        },
    },
    "Corn_(maize)___Common_rust_": {
        "G1": {
            "recommendation": "Monitor; fungicide rarely needed at this stage for resistant hybrids.",
            "prevention": "Plant rust-resistant hybrids where common rust pressure is high.",
        },
        "G2": {
            "recommendation": "Apply fungicide if susceptible hybrid and conditions favor spread.",
            "prevention": "Avoid late planting that exposes young plants to peak rust season.",
        },
        "G3": {
            "recommendation": "Apply fungicide immediately to protect remaining green leaf area for grain fill.",
            "prevention": "Select resistant hybrids for future seasons in high-pressure areas.",
        },
    },
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": {
        "G1": {
            "recommendation": "Monitor; consider fungicide if continuous corn planting history.",
            "prevention": "Rotate crops; avoid continuous corn-on-corn planting.",
        },
        "G2": {
            "recommendation": "Apply foliar fungicide, especially before tasseling.",
            "prevention": "Till crop residue to reduce overwintering fungal spores.",
        },
        "G3": {
            "recommendation": "Apply fungicide immediately; significant yield loss risk from leaf area loss.",
            "prevention": "Select resistant hybrids and rotate away from corn for a season.",
        },
    },

    # ---------------- GRAPE ----------------
    "Grape___healthy": {
        "G0": {
            "recommendation": "No treatment needed.",
            "prevention": "Maintain good canopy management for airflow.",
        },
    },
    "Grape___Black_rot": {
        "G1": {
            "recommendation": "Remove mummified berries and infected leaves.",
            "prevention": "Prune for open canopy to reduce humidity around clusters.",
        },
        "G2": {
            "recommendation": "Apply fungicide (myclobutanil or captan) starting at bloom.",
            "prevention": "Remove wild grape vines nearby that can harbor the fungus.",
        },
        "G3": {
            "recommendation": "Apply fungicide immediately and remove severely infected clusters.",
            "prevention": "Consider resistant grape varieties for new plantings.",
        },
    },
    "Grape___Esca_(Black_Measles)": {
        "G1": {
            "recommendation": "Prune out affected wood during dry weather; disinfect tools.",
            "prevention": "Avoid pruning wounds during wet weather when fungal spores are active.",
        },
        "G2": {
            "recommendation": "Remove and destroy affected canes/spurs. No effective fungicide cure exists.",
            "prevention": "Protect large pruning wounds with wound sealant.",
        },
        "G3": {
            "recommendation": "Remove severely affected vines to prevent spread to healthy vines.",
            "prevention": "Replant with certified disease-free nursery stock.",
        },
    },
    "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)": {
        "G1": {
            "recommendation": "Apply preventive fungicide; remove affected leaves.",
            "prevention": "Improve canopy airflow through leaf pulling.",
        },
        "G2": {
            "recommendation": "Apply fungicide (copper-based) every 10-14 days.",
            "prevention": "Avoid overhead irrigation.",
        },
        "G3": {
            "recommendation": "Apply fungicide immediately; heavy defoliation affects fruit ripening.",
            "prevention": "Rotate fungicide classes to avoid resistance buildup.",
        },
    },
}

GENERIC_FALLBACK = {
    "recommendation": (
        "Specific guidance for this disease/severity combination is not yet "
        "in the knowledge base. Consult your local agricultural extension "
        "officer for a field-verified treatment plan."
    ),
    "prevention": (
        "General good practice: rotate crops, avoid overhead irrigation, "
        "remove infected plant debris, and monitor regularly."
    ),
}


def get_recommendation(disease_class: str, severity_stage: str) -> dict:
    """Steps 14-17: given a model's predicted class + the CV-estimated
    severity stage, return the treatment + prevention text.

    disease_class must be one of the raw class names from
    supported_crops.all_class_names(). severity_stage is one of
    'G0'..'G3'.
    """
    disease_entry = TREATMENT_MAP.get(disease_class)
    if disease_entry is None:
        return {**GENERIC_FALLBACK, "matched": False}

    stage_entry: Optional[dict] = disease_entry.get(severity_stage)
    if stage_entry is None:
        # e.g. model said "healthy" but severity estimator found G2 -
        # this is a contradiction the app should flag, not silently mask.
        if disease_class.endswith("healthy") and severity_stage != "G0":
            return {
                "recommendation": (
                    "Inconsistent result: classifier predicted a healthy "
                    "leaf but the image shows visible discoloration. "
                    "Please retake the photo or run a manual check."
                ),
                "prevention": "N/A",
                "matched": False,
                "warning": "classifier/severity mismatch",
            }
        # Reverse case: a diagnosed disease combined with G0 severity
        # is equally a contradiction - handling both directions gives
        # a clearer message than the generic fallback here.
        if not disease_class.endswith("healthy") and severity_stage == "G0":
            return {
                "recommendation": (
                    "Inconsistent result: classifier predicted a disease "
                    "but the image shows minimal discoloration. This can "
                    "happen with the placeholder classifier, or with "
                    "disease types (e.g. bacterial spot) whose lesion "
                    "coloring differs from what the severity estimator "
                    "was tuned for. Consider a manual check."
                ),
                "prevention": "N/A",
                "matched": False,
                "warning": "classifier/severity mismatch",
            }
        return {**GENERIC_FALLBACK, "matched": False}

    return {**stage_entry, "matched": True}


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python treatment_recommendations.py <disease_class> <severity_stage>")
        print("Example: python treatment_recommendations.py Tomato___Early_blight G2")
        sys.exit(1)
    print(get_recommendation(sys.argv[1], sys.argv[2]))
