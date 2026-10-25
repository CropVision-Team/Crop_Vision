"""Create a visual augmentation sheet for one training image.

Usage:
    python generate_augmentation_preview.py input.jpg --output preview.jpg

This is a diagnostic/demo tool only. The trainer applies random
augmentations online and does not write augmented files into the dataset.
Keeping generated copies out of the dataset prevents accidental validation
and test leakage.
"""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps
from torchvision.transforms import functional as TF


def build_variants(image: Image.Image) -> list[tuple[str, Image.Image]]:
    image = image.convert("RGB")
    return [
        ("Original", image),
        ("Horizontal", ImageOps.mirror(image)),
        ("Vertically", ImageOps.flip(image)),
        ("+45 Rotation", TF.rotate(image, 45, expand=True)),
        ("-45 Rotation", TF.rotate(image, -45, expand=True)),
        ("Blur", image.filter(ImageFilter.GaussianBlur(radius=1.2))),
        ("Brighter", ImageEnhance.Brightness(image).enhance(1.35)),
        ("Noise added", _add_noise(image)),
        ("Darker", ImageEnhance.Brightness(image).enhance(0.65)),
        ("Grayscale", ImageOps.grayscale(image).convert("RGB")),
        ("Crop", TF.resized_crop(image, 20, 20, max(1, image.height - 40),
                                 max(1, image.width - 40), image.size)),
    ]


def _add_noise(image: Image.Image) -> Image.Image:
    tensor = TF.to_tensor(image)
    noisy = (tensor + 0.04 * tensor.new_empty(tensor.shape).normal_()).clamp(0, 1)
    return TF.to_pil_image(noisy)


def save_sheet(variants: list[tuple[str, Image.Image]], output: Path) -> None:
    thumb_width, thumb_height = 240, 190
    columns = 4
    rows = (len(variants) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * thumb_width, rows * thumb_height), "white")
    draw = ImageDraw.Draw(sheet)

    for index, (label, image) in enumerate(variants):
        image.thumbnail((thumb_width - 16, thumb_height - 42))
        x = (index % columns) * thumb_width + (thumb_width - image.width) // 2
        y = (index // columns) * thumb_height + 28
        sheet.paste(image, (x, y))
        label_x = (index % columns) * thumb_width + 8
        label_y = (index // columns) * thumb_height + 6
        draw.text((label_x, label_y), label, fill="black")

    sheet.save(output)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("--output", type=Path, default=Path("augmentation_preview.jpg"))
    args = parser.parse_args()

    variants = build_variants(Image.open(args.input))
    save_sheet(variants, args.output)
    print(f"Saved {len(variants)} augmentation variants to {args.output}")


if __name__ == "__main__":
    main()
