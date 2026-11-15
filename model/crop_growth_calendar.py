"""
Crop Growth Calendar
----------------------
Since our capture flow photographs a single LEAF close-up (for disease
diagnosis), it cannot reliably detect whole-plant growth stages like
flowering or fruiting from that same photo - those need to observe the
whole plant, not a leaf. And no labeled dataset exists to train a
dedicated "growth stage" image classifier (PlantVillage has disease
labels, not growth-stage labels).

So growth stage here is computed from TIME rather than the image: the
crop is identified from the disease-diagnosis model (already gives a
crop name, e.g. "Tomato"), and the farmer sets a planting date once per
crop. From then on, days-since-planting is looked up against this
crop's typical stage durations to say which of the 5 stages applies.

IMPORTANT: these day ranges are illustrative, typical-case estimates
based on common growing guides, NOT measured from this project's data.
Actual timing varies by variety, climate, and region - a farmer using
this for real decisions should treat it as a rough guide, not a
precise schedule. Adjust these numbers if presenting for a specific
region/variety in your viva.
"""

GROWTH_STAGES = [
    "Sowing & Planting",
    "Crop Establishment & Vegetative Growth",
    "Reproductive Growth & Care Management",
    "Maturation & Ripening",
    "Harvesting",
]

# Each crop: list of (stage_name, day_range_start, day_range_end) tuples,
# where day_range is days-since-planting. Ranges are inclusive of start,
# exclusive of end, except the last stage which has no upper bound.
CROP_GROWTH_CALENDAR = {
    "Tomato": [
        ("Sowing & Planting", 0, 10),
        ("Crop Establishment & Vegetative Growth", 10, 35),
        ("Reproductive Growth & Care Management", 35, 65),
        ("Maturation & Ripening", 65, 85),
        ("Harvesting", 85, None),
    ],
    "Potato": [
        ("Sowing & Planting", 0, 14),
        ("Crop Establishment & Vegetative Growth", 14, 40),
        ("Reproductive Growth & Care Management", 40, 70),
        ("Maturation & Ripening", 70, 95),
        ("Harvesting", 95, None),
    ],
    "Apple": [
        # Perennial tree - models one growing SEASON (bud break to
        # harvest), not the tree's multi-year life. "Planting date"
        # here means "start of this season's growth" (spring bud break).
        ("Sowing & Planting", 0, 20),
        ("Crop Establishment & Vegetative Growth", 20, 60),
        ("Reproductive Growth & Care Management", 60, 120),
        ("Maturation & Ripening", 120, 160),
        ("Harvesting", 160, None),
    ],
    "Corn (Maize)": [
        ("Sowing & Planting", 0, 10),
        ("Crop Establishment & Vegetative Growth", 10, 45),
        ("Reproductive Growth & Care Management", 45, 75),
        ("Maturation & Ripening", 75, 100),
        ("Harvesting", 100, None),
    ],
    "Grape": [
        # Also perennial - models one season from bud break to harvest.
        ("Sowing & Planting", 0, 15),
        ("Crop Establishment & Vegetative Growth", 15, 55),
        ("Reproductive Growth & Care Management", 55, 110),
        ("Maturation & Ripening", 110, 150),
        ("Harvesting", 150, None),
    ],
    "Blueberry": [
        # Perennial bush - one season, bud break to harvest.
        ("Sowing & Planting", 0, 20),
        ("Crop Establishment & Vegetative Growth", 20, 60),
        ("Reproductive Growth & Care Management", 60, 100),
        ("Maturation & Ripening", 100, 130),
        ("Harvesting", 130, None),
    ],
    "Cherry": [
        # Perennial tree - shorter season than apple/peach.
        ("Sowing & Planting", 0, 15),
        ("Crop Establishment & Vegetative Growth", 15, 45),
        ("Reproductive Growth & Care Management", 45, 75),
        ("Maturation & Ripening", 75, 95),
        ("Harvesting", 95, None),
    ],
    "Orange": [
        # Perennial citrus - long cycle, roughly a full year from bloom
        # to harvest depending on variety.
        ("Sowing & Planting", 0, 30),
        ("Crop Establishment & Vegetative Growth", 30, 90),
        ("Reproductive Growth & Care Management", 90, 180),
        ("Maturation & Ripening", 180, 270),
        ("Harvesting", 270, None),
    ],
    "Peach": [
        # Perennial tree - one season, bud break to harvest.
        ("Sowing & Planting", 0, 15),
        ("Crop Establishment & Vegetative Growth", 15, 50),
        ("Reproductive Growth & Care Management", 50, 90),
        ("Maturation & Ripening", 90, 120),
        ("Harvesting", 120, None),
    ],
    "Pepper (Bell)": [
        ("Sowing & Planting", 0, 21),
        ("Crop Establishment & Vegetative Growth", 21, 50),
        ("Reproductive Growth & Care Management", 50, 80),
        ("Maturation & Ripening", 80, 100),
        ("Harvesting", 100, None),
    ],
    "Raspberry": [
        # Perennial bramble - one season, bud break to harvest.
        ("Sowing & Planting", 0, 20),
        ("Crop Establishment & Vegetative Growth", 20, 55),
        ("Reproductive Growth & Care Management", 55, 85),
        ("Maturation & Ripening", 85, 100),
        ("Harvesting", 100, None),
    ],
    "Soybean": [
        ("Sowing & Planting", 0, 10),
        ("Crop Establishment & Vegetative Growth", 10, 45),
        ("Reproductive Growth & Care Management", 45, 90),
        ("Maturation & Ripening", 90, 110),
        ("Harvesting", 110, None),
    ],
    "Squash": [
        ("Sowing & Planting", 0, 10),
        ("Crop Establishment & Vegetative Growth", 10, 35),
        ("Reproductive Growth & Care Management", 35, 55),
        ("Maturation & Ripening", 55, 70),
        ("Harvesting", 70, None),
    ],
    "Strawberry": [
        # Often grown as an annual in practice even though technically
        # perennial - models one fruiting season.
        ("Sowing & Planting", 0, 21),
        ("Crop Establishment & Vegetative Growth", 21, 60),
        ("Reproductive Growth & Care Management", 60, 90),
        ("Maturation & Ripening", 90, 105),
        ("Harvesting", 105, None),
    ],
}


def get_current_stage(crop_name: str, days_since_planting: int) -> dict:
    """Given a crop name and how many days since it was planted, return
    which of the 5 growth stages it's currently in."""
    if crop_name not in CROP_GROWTH_CALENDAR:
        return {
            "stage": None,
            "message": f"No growth calendar data for '{crop_name}' yet.",
        }

    if days_since_planting < 0:
        return {
            "stage": None,
            "message": "Planting date is in the future.",
        }

    stages = CROP_GROWTH_CALENDAR[crop_name]
    for stage_name, start, end in stages:
        if end is None or days_since_planting < end:
            if days_since_planting >= start:
                return {
                    "stage": stage_name,
                    "days_since_planting": days_since_planting,
                    "stage_day_range": (start, end),
                }
    # Shouldn't reach here given the last stage has no upper bound, but
    # fall back safely just in case.
    return {"stage": stages[-1][0], "days_since_planting": days_since_planting}


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python crop_growth_calendar.py <crop_name> <days_since_planting>")
        sys.exit(1)
    print(get_current_stage(sys.argv[1], int(sys.argv[2])))
