"""
Real Disease Classification Server
--------------------------------------
Loads the trained MobileViT checkpoint (checkpoints/mobilevit_best.pt)
and serves it over a simple local HTTP endpoint. The Flutter app calls
this instead of on-device inference - this sidesteps adding another
native Android dependency (pytorch_lite/tflite/onnxruntime) on top of
an already fragile NDK/build setup, and reuses the same HTTP-call
pattern already working for the Gemini AI Assistant.

Run this BEFORE running the Flutter app:
    python inference_server.py

Then connect your phone (same USB cable used for `flutter run`) with:
    adb reverse tcp:8000 tcp:8000

This makes "localhost:8000" on the PHONE actually reach this server
running on your COMPUTER, over the same USB cable - no WiFi network
config needed, and it works identically whether phone and computer
share a network or not.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import torch
import torch.nn.functional as F
from torchvision import transforms
from PIL import Image
import io
import os

try:
    import timm
except ImportError as e:
    raise SystemExit(
        "timm is required: pip install timm --break-system-packages"
    ) from e

app = Flask(__name__)
# Needed for Flutter Web (Chrome) specifically: the browser treats
# localhost:<flutter-port> calling localhost:8000 as a cross-origin
# request (different port = different origin for CORS purposes) and
# blocks it by default unless the server explicitly allows it. Native
# Android/iOS builds don't need this - CORS is a browser-only concept -
# but it's required for testing in Chrome via `flutter run -d chrome`.
CORS(app)

IMG_SIZE = 224
MEAN = [0.485, 0.456, 0.406]
STD = [0.229, 0.224, 0.225]

# Use CROPVISION_CHECKPOINT to serve a new hierarchical checkpoint without
# editing code, for example: $env:CROPVISION_CHECKPOINT='.\runs\mobilevit_hier\mobilevit_s_cropvision_best.pt'
CHECKPOINT_PATH = os.environ.get("CROPVISION_CHECKPOINT", "./checkpoints/mobilevit_best.pt")

print(f"Loading checkpoint from {CHECKPOINT_PATH}...")
checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu", weights_only=False)
hierarchical = "classes" in checkpoint and "model" in checkpoint
class_names = checkpoint["classes"] if hierarchical else checkpoint["class_names"]
print(f"Loaded {len(class_names)} classes: {class_names}")

if hierarchical:
    from train_cropvision import CropNet

    crop_names = checkpoint["crops"]
    model = CropNet(checkpoint["backbone"], len(class_names), len(crop_names), pretrained=False)
    model.load_state_dict(checkpoint["model"])
    IMG_SIZE = checkpoint["img_size"]
    MEAN = checkpoint["mean"]
    STD = checkpoint["std"]
else:
    crop_names = None
    model = timm.create_model("mobilevit_s", pretrained=False, num_classes=len(class_names))
    model.load_state_dict(checkpoint["model_state"])
model.eval()
print("Model ready.")

transform = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(MEAN, STD),
])


@app.route("/classify", methods=["POST"])
def classify():
    if "image" not in request.files:
        return jsonify({"error": "No 'image' file in request"}), 400

    image_bytes = request.files["image"].read()
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as e:
        return jsonify({"error": f"Could not decode image: {e}"}), 400

    input_tensor = transform(image).unsqueeze(0)

    with torch.no_grad():
        output = model(input_tensor)
        logits, crop_logits = output if hierarchical else (output, None)
        probs = F.softmax(logits, dim=1)
        confidence, predicted_idx = torch.max(probs, dim=1)

    predicted_class = class_names[predicted_idx.item()]

    # Debug output - shows the top 5 predictions with their probabilities.
    # If confidence is suspiciously close to 1/num_classes (here, ~2.6%)
    # for every image regardless of what's actually photographed, that's
    # a strong sign the model is outputting a near-uniform distribution -
    # meaning something upstream (checkpoint loading, preprocessing) is
    # broken, not that the images are genuinely unrecognizable.
    top5_probs, top5_idx = torch.topk(probs[0], k=min(5, len(class_names)))
    print(f"\n--- Prediction for this request ---")
    print(f"Uniform-guess baseline would be ~{100/len(class_names):.2f}%")
    for p, idx in zip(top5_probs, top5_idx):
        print(f"  {class_names[idx.item()]}: {p.item()*100:.2f}%")
    print("---\n")

    response = {
        "predicted_class": predicted_class,
        "confidence": round(confidence.item(), 4),
    }
    if crop_logits is not None:
        crop_probs = F.softmax(crop_logits, dim=1)
        crop_confidence, crop_idx = torch.max(crop_probs, dim=1)
        response["predicted_crop"] = crop_names[crop_idx.item()]
        response["crop_confidence"] = round(crop_confidence.item(), 4)
    return jsonify(response)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "classes": len(class_names)})


if __name__ == "__main__":
    print("Starting server on http://0.0.0.0:8000")
    print("On your phone, run: adb reverse tcp:8000 tcp:8000")
    app.run(host="0.0.0.0", port=8000)
