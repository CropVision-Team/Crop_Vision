"""Evaluate an existing CropVision checkpoint on the official test set.

Usage:
    python evaluate_checkpoint.py
"""

import argparse
from pathlib import Path

import torch
from torch.utils.data import DataLoader, Subset
from torchvision import datasets

import timm

from train_mobilevit import build_transforms, split_train_val_indices


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--checkpoint", default="./checkpoints/mobilevit_best.pt")
    parser.add_argument(
        "--split",
        choices=("validation", "official_test"),
        default="validation",
    )
    parser.add_argument("--test_dir", default="./official_test")
    parser.add_argument("--data_dir", default="./dataset")
    parser.add_argument("--batch_size", type=int, default=4)
    parser.add_argument("--val_split", type=float, default=0.15)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    checkpoint_path = Path(args.checkpoint)
    data_path = Path(args.data_dir)
    test_path = Path(args.test_dir)

    if not checkpoint_path.is_file():
        raise FileNotFoundError(f"Checkpoint not found: {checkpoint_path.resolve()}")
    if not data_path.is_dir():
        raise FileNotFoundError(f"Training directory not found: {data_path.resolve()}")
    if args.split == "official_test" and not test_path.is_dir():
        raise FileNotFoundError(f"Test directory not found: {test_path.resolve()}")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    checkpoint = torch.load(
        checkpoint_path,
        map_location=device,
        weights_only=False,
    )
    class_names = checkpoint["class_names"]
    model = timm.create_model(
        "mobilevit_s",
        pretrained=False,
        num_classes=len(class_names),
    )
    model.load_state_dict(checkpoint["model_state"])
    model.to(device)
    model.eval()

    source_dataset = datasets.ImageFolder(
        str(data_path),
        transform=build_transforms(training=False),
    )
    if source_dataset.classes != class_names:
        raise RuntimeError(
            "Dataset class order does not match the checkpoint class order."
        )

    if args.split == "validation":
        _, validation_indices = split_train_val_indices(
            source_dataset.targets,
            val_fraction=args.val_split,
            seed=args.seed,
        )
        evaluation_dataset = Subset(source_dataset, validation_indices)
        split_name = "VALIDATION"
    else:
        evaluation_dataset = datasets.ImageFolder(
            str(test_path),
            transform=build_transforms(training=False),
        )
        if evaluation_dataset.classes != class_names:
            raise RuntimeError(
                "Official test class order does not match the checkpoint."
            )
        split_name = "OFFICIAL TEST"

    loader = DataLoader(
        evaluation_dataset,
        batch_size=args.batch_size,
        shuffle=False,
        num_workers=0,
    )

    correct = 0
    total = 0
    with torch.inference_mode():
        for images, labels in loader:
            outputs = model(images.to(device))
            correct += (outputs.argmax(dim=1).cpu() == labels).sum().item()
            total += labels.size(0)

    accuracy = 100.0 * correct / total if total else 0.0
    print(f"Checkpoint: {checkpoint_path.resolve()}")
    print(f"Split: {split_name}")
    print(f"Images: {total}")
    print(f"Correct: {correct}")
    print(f"{split_name} ACCURACY: {accuracy:.2f}%")


if __name__ == "__main__":
    main()
