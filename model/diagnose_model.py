"""
Standalone Model Diagnostic
------------------------------
Tests the trained checkpoint DIRECTLY in Python, completely bypassing
Flask/HTTP - this isolates whether a bug is in the model/checkpoint
itself, or in the Flask serving layer (image upload handling, request
parsing, etc.).

Usage:
    python diagnose_model.py path/to/a/leaf/image.jpg

Ideally, pass a path to an image from inside your ./dataset folder
(one the model was actually trained on) - e.g.:
    python diagnose_model.py "./dataset/Tomato___healthy/some_image.JPG"
"""

import sys
import torch
import torch.nn.functional as F
from torchvision import transforms
from PIL import Image

try:
    import timm
except ImportError as e:
    raise SystemExit("timm is required: pip install timm --break-system-packages") from e

if len(sys.argv) < 2:
    print("Usage: python diagnose_model.py path/to/image.jpg")
    sys.exit(1)

image_path = sys.argv[1]
CHECKPOINT_PATH = "./checkpoints/mobilevit_best.pt"
IMG_SIZE = 224
MEAN = [0.485, 0.456, 0.406]
STD = [0.229, 0.224, 0.225]

print(f"Loading checkpoint from {CHECKPOINT_PATH}...")
checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu", weights_only=False)
class_names = checkpoint["class_names"]
print(f"Checkpoint contains {len(class_names)} classes.")
print(f"First 3 classes: {class_names[:3]}")

# Report how many parameter tensors are in the saved state_dict, and a
# quick sanity stat (mean absolute value) on a couple of them. A
# freshly-initialized (untrained) model's weights look statistically
# different from genuinely fine-tuned ones, though this is a rough
# signal, not proof by itself.
state = checkpoint["model_state"]
print(f"State dict contains {len(state)} parameter tensors.")
sample_keys = list(state.keys())[:3]
for k in sample_keys:
    t = state[k]
    print(f"  {k}: shape={tuple(t.shape)}, mean_abs={t.abs().mean().item():.5f}")

print("\nBuilding model architecture...")
model = timm.create_model("mobilevit_s", pretrained=False, num_classes=len(class_names))

print("Loading weights into model...")
missing, unexpected = model.load_state_dict(state, strict=False)
if missing:
    print(f"WARNING - missing keys (weights NOT loaded for these): {missing}")
if unexpected:
    print(f"WARNING - unexpected keys (ignored): {unexpected}")
if not missing and not unexpected:
    print("All keys matched exactly - checkpoint loaded cleanly.")

model.eval()

print(f"\nLoading and preprocessing image: {image_path}")
image = Image.open(image_path).convert("RGB")
transform = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(MEAN, STD),
])
input_tensor = transform(image).unsqueeze(0)
print(f"Input tensor shape: {tuple(input_tensor.shape)}, "
      f"min={input_tensor.min().item():.3f}, max={input_tensor.max().item():.3f}")

with torch.no_grad():
    logits = model(input_tensor)
    print(f"\nRaw logits (first 10 of {logits.shape[1]}): {logits[0][:10].tolist()}")
    print(f"Logits std deviation: {logits[0].std().item():.4f} "
          f"(near 0 here would mean the model outputs nearly IDENTICAL "
          f"scores for every class - a strong sign of untrained/broken weights)")
    probs = F.softmax(logits, dim=1)

top5_probs, top5_idx = torch.topk(probs[0], k=5)
print("\nTop 5 predictions:")
for p, idx in zip(top5_probs, top5_idx):
    print(f"  {class_names[idx.item()]}: {p.item()*100:.2f}%")
