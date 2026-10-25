"""
Supported Crops & Diseases Registry
-------------------------------------
Single source of truth for which crop/disease classes the app supports.
Mirrors the `crops` table in Supabase (backend/supabase_schema.sql) and
must match the class folder names used when training MobileViT
(train_mobilevit.py), since the model's output indices map 1:1 to
these labels.

Based on the PlantVillage dataset (14 crops, 38 classes). This now
lists all 14 - matches what train_mobilevit.py actually trained on
(confirmed from the real training run's discovered class list), not a
trimmed subset.
"""

SUPPORTED_CROPS = {
    "Apple": [
        "Apple___Apple_scab",
        "Apple___Black_rot",
        "Apple___Cedar_apple_rust",
        "Apple___healthy",
    ],
    "Blueberry": [
        "Blueberry___healthy",
    ],
    "Cherry": [
        "Cherry_(including_sour)___Powdery_mildew",
        "Cherry_(including_sour)___healthy",
    ],
    "Corn (Maize)": [
        "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot",
        "Corn_(maize)___Common_rust_",
        "Corn_(maize)___Northern_Leaf_Blight",
        "Corn_(maize)___healthy",
    ],
    "Grape": [
        "Grape___Black_rot",
        "Grape___Esca_(Black_Measles)",
        "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)",
        "Grape___healthy",
    ],
    "Orange": [
        "Orange___Haunglongbing_(Citrus_greening)",
    ],
    "Peach": [
        "Peach___Bacterial_spot",
        "Peach___healthy",
    ],
    "Pepper (Bell)": [
        "Pepper,_bell___Bacterial_spot",
        "Pepper,_bell___healthy",
    ],
    "Potato": [
        "Potato___Early_blight",
        "Potato___Late_blight",
        "Potato___healthy",
    ],
    "Raspberry": [
        "Raspberry___healthy",
    ],
    "Soybean": [
        "Soybean___healthy",
    ],
    "Squash": [
        "Squash___Powdery_mildew",
    ],
    "Strawberry": [
        "Strawberry___Leaf_scorch",
        "Strawberry___healthy",
    ],
    "Tomato": [
        "Tomato___Bacterial_spot",
        "Tomato___Early_blight",
        "Tomato___Late_blight",
        "Tomato___Leaf_Mold",
        "Tomato___Septoria_leaf_spot",
        "Tomato___Spider_mites Two-spotted_spider_mite",
        "Tomato___Target_Spot",
        "Tomato___Tomato_Yellow_Leaf_Curl_Virus",
        "Tomato___Tomato_mosaic_virus",
        "Tomato___healthy",
    ],
}


def all_class_names() -> list[str]:
    """Flat list of every class the model needs to predict, in a
    stable order - this order MUST match training and inference."""
    names = []
    for diseases in SUPPORTED_CROPS.values():
        names.extend(diseases)
    return sorted(names)


def crop_for_class(class_name: str) -> str | None:
    """Given a raw model class label, find which crop it belongs to."""
    for crop, diseases in SUPPORTED_CROPS.items():
        if class_name in diseases:
            return crop
    return None


def is_healthy_class(class_name: str) -> bool:
    return class_name.endswith("healthy")


if __name__ == "__main__":
    classes = all_class_names()
    print(f"Total supported classes: {len(classes)}")
    for c in classes:
        print(f"  {c}  ->  crop: {crop_for_class(c)}")
