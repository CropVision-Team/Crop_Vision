"""
Initialize MobileViT Checkpoint
--------------------------------
Creates an initial MobileViT-Small model checkpoint with the 38 PlantVillage
class names and saves it to checkpoints/mobilevit_best.pt. This allows running
inference_server.py immediately for API / app testing before full training completes.
"""

import os
import torch
import timm
from torchvision import datasets


def init_checkpoint(data_dir="./dataset", output_dir="./checkpoints"):
    os.makedirs(output_dir, exist_ok=True)
    checkpoint_path = os.path.join(output_dir, "mobilevit_best.pt")

    if os.path.exists(data_dir):
        ds = datasets.ImageFolder(data_dir)
        class_names = ds.classes
    else:
        class_names = [f"Class_{i}" for i in range(38)]

    print(f"Initializing MobileViT-Small model for {len(class_names)} classes...")
    model = timm.create_model("mobilevit_s", pretrained=False, num_classes=len(class_names))

    checkpoint = {
        "model_state": model.state_dict(),
        "class_names": class_names
    }

    torch.save(checkpoint, checkpoint_path)
    print(f"Checkpoint successfully saved to {checkpoint_path}")


if __name__ == "__main__":
    init_checkpoint()
