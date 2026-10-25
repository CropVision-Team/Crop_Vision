
"""
CropVision - MobileViT Small Training Script

Training images: ./dataset
Official test images: ./official_test
Best checkpoint: ./checkpoints/mobilevit_best.pt

Training data is split into training and validation subsets.
The official test set is kept separate and used only for final evaluation.
"""

import argparse
import os
import random
import time
from collections import defaultdict
from pathlib import Path

import torch
import torch.nn as nn
from torch.utils.data import DataLoader, Subset
from torchvision import datasets, transforms

try:
    import timm
except ImportError as exc:
    raise SystemExit(
        "Missing timm. Install it with: python -m pip install timm"
    ) from exc


IMG_SIZE = 224
MEAN = [0.485, 0.456, 0.406]
STD = [0.229, 0.224, 0.225]


class AddGaussianNoise:
    """Add mild camera sensor noise to training images."""

    def __init__(self, std=0.02):
        self.std = std

    def __call__(self, tensor):
        return tensor + torch.randn_like(tensor) * self.std


def build_transforms(training=False):
    """Create separate augmentation and evaluation pipelines."""

    if training:
        return transforms.Compose([
            transforms.RandomResizedCrop(
                IMG_SIZE, scale=(0.8, 1.0), ratio=(0.9, 1.1)
            ),
            transforms.RandomHorizontalFlip(),
            transforms.RandomVerticalFlip(p=0.2),
            transforms.RandomRotation(45),
            transforms.RandomAffine(
                degrees=0, translate=(0.08, 0.08)
            ),
            transforms.RandomPerspective(
                distortion_scale=0.15, p=0.3
            ),
            transforms.ColorJitter(
                brightness=0.25,
                contrast=0.25,
                saturation=0.2,
                hue=0.02,
            ),
            transforms.RandomApply([
                transforms.GaussianBlur(
                    kernel_size=3, sigma=(0.1, 1.0)
                )
            ], p=0.2),
            transforms.RandomGrayscale(p=0.1),
            transforms.ToTensor(),
            AddGaussianNoise(std=0.02),
            transforms.Normalize(MEAN, STD),
        ])

    return transforms.Compose([
        transforms.Resize((IMG_SIZE, IMG_SIZE)),
        transforms.ToTensor(),
        transforms.Normalize(MEAN, STD),
    ])


def split_train_val_indices(labels, val_fraction=0.15, seed=42):
    """Create reproducible, class-stratified training/validation splits."""

    if not 0.0 < val_fraction < 1.0:
        raise ValueError("val_fraction must be between 0 and 1.")

    by_class = defaultdict(list)

    for index, label in enumerate(labels):
        by_class[label].append(index)

    rng = random.Random(seed)
    train_indices = []
    val_indices = []

    for class_indices in by_class.values():
        rng.shuffle(class_indices)

        if len(class_indices) < 2:
            raise ValueError(
                "Every class needs at least two images for the split."
            )

        val_size = max(1, round(len(class_indices) * val_fraction))
        val_size = min(val_size, len(class_indices) - 1)

        val_indices.extend(class_indices[:val_size])
        train_indices.extend(class_indices[val_size:])

    rng.shuffle(train_indices)
    rng.shuffle(val_indices)

    return train_indices, val_indices


def build_model(num_classes):
    """Create MobileViT Small with pretrained ImageNet weights."""
    return timm.create_model(
        "mobilevit_s",
        pretrained=True,
        num_classes=num_classes,
    )


def evaluate(model, loader, device, criterion=None):
    """Evaluate loss and accuracy without updating model weights."""

    model.eval()
    total = 0
    correct = 0
    total_loss = 0.0

    with torch.inference_mode():
        for images, labels in loader:
            images = images.to(device)
            labels = labels.to(device)

            outputs = model(images)
            predictions = outputs.argmax(dim=1)

            correct += (predictions == labels).sum().item()
            total += labels.size(0)

            if criterion is not None:
                loss = criterion(outputs, labels)
                total_loss += loss.item() * labels.size(0)

    accuracy = correct / total if total else 0.0
    average_loss = total_loss / total if total and criterion else None

    return accuracy, average_loss


def train(args):
    random.seed(args.seed)
    torch.manual_seed(args.seed)

    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(args.seed)

    device = torch.device(
        "cuda" if torch.cuda.is_available() else "cpu"
    )

    print("=" * 60)
    print("CropVision MobileViT Small Training")
    print("=" * 60)
    print(f"Device: {device}")

    if device.type == "cuda":
        print(f"GPU: {torch.cuda.get_device_name(0)}")

    training_path = Path(args.data_dir)
    test_path = Path(args.test_dir)

    if not training_path.is_dir():
        raise FileNotFoundError(
            f"Training folder not found: {training_path.resolve()}"
        )

    if not test_path.is_dir():
        raise FileNotFoundError(
            f"Official test folder not found: {test_path.resolve()}"
        )

    # Separate datasets ensure training augmentation does not affect
    # validation or official test images.
    train_full = datasets.ImageFolder(
        str(training_path),
        transform=build_transforms(training=True),
    )

    validation_full = datasets.ImageFolder(
        str(training_path),
        transform=build_transforms(training=False),
    )

    official_test = datasets.ImageFolder(
        str(test_path),
        transform=build_transforms(training=False),
    )

    class_names = train_full.classes

    if len(class_names) != 38:
        raise RuntimeError(
            f"Expected 38 classes, but found {len(class_names)}."
        )

    if validation_full.class_to_idx != train_full.class_to_idx:
        raise RuntimeError("Training and validation classes do not match.")

    if official_test.class_to_idx != train_full.class_to_idx:
        raise RuntimeError(
            "Official test class names or class indices do not match "
            "the training dataset."
        )

    print(f"Classes: {len(class_names)}")
    print(f"Training source images: {len(train_full)}")
    print(f"Official test images: {len(official_test)}")

    train_indices, val_indices = split_train_val_indices(
        train_full.targets,
        val_fraction=args.val_split,
        seed=args.seed,
    )

    train_dataset = Subset(train_full, train_indices)
    val_dataset = Subset(validation_full, val_indices)

    print(f"Training subset: {len(train_dataset)}")
    print(f"Validation subset: {len(val_dataset)}")
    print(f"Official test set: {len(official_test)}")

    train_loader = DataLoader(
        train_dataset,
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=0,
        pin_memory=(device.type == "cuda"),
    )

    val_loader = DataLoader(
        val_dataset,
        batch_size=args.batch_size,
        shuffle=False,
        num_workers=0,
        pin_memory=(device.type == "cuda"),
    )

    test_loader = DataLoader(
        official_test,
        batch_size=args.batch_size,
        shuffle=False,
        num_workers=0,
        pin_memory=(device.type == "cuda"),
    )

    print("\nLoading pretrained MobileViT Small...")
    model = build_model(len(class_names)).to(device)

    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(
        model.parameters(),
        lr=args.lr,
    )
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimizer,
        T_max=args.epochs,
    )

    checkpoint_dir = Path(args.output_dir)
    checkpoint_dir.mkdir(parents=True, exist_ok=True)

    checkpoint_path = checkpoint_dir / "mobilevit_best.pt"
    best_val_accuracy = -1.0

    # Confirm that a trainable parameter changes after an optimizer step.
    sanity_name = "stem.bn.weight"
    sanity_before = model.state_dict().get(sanity_name)

    if sanity_before is not None:
        sanity_before = sanity_before.detach().clone()

    sanity_checked = False

    for epoch in range(args.epochs):
        model.train()
        epoch_start = time.time()
        running_loss = 0.0

        print(f"\nEpoch {epoch + 1}/{args.epochs}")

        for batch_index, (images, labels) in enumerate(train_loader):
            images = images.to(device)
            labels = labels.to(device)

            optimizer.zero_grad(set_to_none=True)

            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item() * images.size(0)

            if not sanity_checked:
                sanity_checked = True
                sanity_after = model.state_dict().get(sanity_name)

                if sanity_before is not None and sanity_after is not None:
                    changed = not torch.equal(
                        sanity_before, sanity_after
                    )
                    print(f"Weight update sanity check: {changed}")

                    if not changed:
                        raise RuntimeError(
                            "The checked model parameter did not change. "
                            "Stop and investigate the training setup."
                        )

            if batch_index % args.log_every == 0:
                print(
                    f"  Batch {batch_index + 1}/{len(train_loader)} "
                    f"| Loss: {loss.item():.4f}"
                )

        scheduler.step()

        train_loss = running_loss / len(train_dataset)
        val_accuracy, val_loss = evaluate(
            model, val_loader, device, criterion
        )

        elapsed = time.time() - epoch_start

        print(
            f"Epoch summary | "
            f"Train loss: {train_loss:.4f} | "
            f"Validation loss: {val_loss:.4f} | "
            f"Validation accuracy: {val_accuracy * 100:.2f}% | "
            f"Time: {elapsed / 60:.1f} minutes"
        )

        # Save the best model based on validation accuracy only.
        if val_accuracy > best_val_accuracy:
            best_val_accuracy = val_accuracy

            torch.save(
                {
                    "model_state": model.state_dict(),
                    "class_names": class_names,
                },
                checkpoint_path,
            )

            print(f"Saved best checkpoint: {checkpoint_path.resolve()}")

    if not checkpoint_path.is_file():
        raise RuntimeError(
            "Training ended without creating a model checkpoint."
        )

    print("\nTraining completed.")
    print(
        f"Best validation accuracy: "
        f"{best_val_accuracy * 100:.2f}%"
    )

    # Evaluate the best saved model on the untouched official test set.
    print("\nLoading best checkpoint for final official test evaluation...")

    checkpoint = torch.load(
        checkpoint_path,
        map_location=device,
        weights_only=False,
    )

    if checkpoint.get("class_names") != class_names:
        raise RuntimeError(
            "Saved checkpoint class order does not match the dataset."
        )

    model.load_state_dict(checkpoint["model_state"])

    test_accuracy, _ = evaluate(
        model, test_loader, device, criterion
    )

    print("\n" + "=" * 60)
    print(f"FINAL OFFICIAL TEST ACCURACY: {test_accuracy * 100:.2f}%")
    print(f"Checkpoint: {checkpoint_path.resolve()}")
    print("=" * 60)
    print("Use this checkpoint with the CropVision inference server.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Train MobileViT Small for CropVision."
    )

    parser.add_argument(
        "--data_dir",
        type=str,
        default="./dataset",
        help="Training images arranged in class folders.",
    )

    parser.add_argument(
        "--test_dir",
        type=str,
        default="./official_test",
        help="Official held-out test images arranged in class folders.",
    )

    parser.add_argument(
        "--output_dir",
        type=str,
        default="./checkpoints",
        help="Directory where the best checkpoint is saved.",
    )

    parser.add_argument("--epochs", type=int, default=25)
    parser.add_argument("--batch_size", type=int, default=4)
    parser.add_argument("--lr", type=float, default=0.0001)
    parser.add_argument("--val_split", type=float, default=0.15)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--log_every", type=int, default=20)

    args = parser.parse_args()

    if args.epochs < 1:
        parser.error("--epochs must be at least 1.")

    if args.batch_size < 1:
        parser.error("--batch_size must be at least 1.")

    train(args)
