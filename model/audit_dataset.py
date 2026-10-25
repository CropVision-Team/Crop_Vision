#!/usr/bin/env python
"""Audit a train/test image split for leakage before training.

The audit checks exact byte duplicates, visually near-duplicate images using
64-bit difference hashes, and EXIF camera/date groups that cross the split.
It does not claim to discover a source that is not represented in the files:
source-level leakage still needs source/plant/field IDs in a manifest.

Example (from model/):
    python audit_dataset.py --train_dir ./dataset --test_dir ./official_test
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


@dataclass(frozen=True)
class ImageRecord:
    path: str
    label: str
    sha256: str
    dhash: int
    exif_group: str | None


def image_files(root: Path) -> Iterable[Path]:
    return (path for path in sorted(root.rglob("*")) if path.suffix.lower() in IMAGE_EXTENSIONS)


def label_for(path: Path, root: Path) -> str:
    """Use the first directory below root, matching ImageFolder labels."""
    relative = path.relative_to(root)
    return relative.parts[0] if len(relative.parts) > 1 else "__unlabelled__"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def difference_hash(path: Path) -> int:
    """A dependency-free 64-bit dHash. Small Hamming distance means similar pixels."""
    with Image.open(path) as image:
        gray = image.convert("L").resize((9, 8), Image.Resampling.LANCZOS)
        # Pillow 14 replaces getdata() with get_flattened_data(). Keep the
        # fallback so the script also works with the older Pillow in a number
        # of existing CropVision environments.
        pixels = list(gray.get_flattened_data() if hasattr(gray, "get_flattened_data") else gray.getdata())
    value = 0
    for row in range(8):
        start = row * 9
        for col in range(8):
            value = (value << 1) | int(pixels[start + col] > pixels[start + col + 1])
    return value


def exif_group(path: Path) -> str | None:
    """Return a conservative camera/time group when those EXIF fields exist."""
    try:
        with Image.open(path) as image:
            data = image.getexif()
            # 271 Make, 272 Model, 306 DateTime; EXIF sub-IFD may vary by device.
            make = str(data.get(271, "")).strip()
            model = str(data.get(272, "")).strip()
            timestamp = str(data.get(306, "")).strip()
        group = " | ".join(item for item in (make, model, timestamp) if item)
        return group or None
    except (OSError, ValueError):
        return None


def scan(root: Path) -> list[ImageRecord]:
    records = []
    for path in image_files(root):
        try:
            records.append(ImageRecord(
                path=str(path), label=label_for(path, root), sha256=sha256(path),
                dhash=difference_hash(path), exif_group=exif_group(path),
            ))
        except (OSError, ValueError) as error:
            print(f"Skipping unreadable image {path}: {error}")
    return records


class HashTree:
    """BK-tree: near-neighbour search without comparing every train/test pair."""

    def __init__(self):
        self.root: tuple[int, list[ImageRecord], dict[int, tuple]] | None = None

    @staticmethod
    def distance(left: int, right: int) -> int:
        return (left ^ right).bit_count()

    def add(self, record: ImageRecord) -> None:
        if self.root is None:
            self.root = (record.dhash, [record], {})
            return
        node = self.root
        while True:
            value, records, children = node
            distance = self.distance(record.dhash, value)
            if distance == 0:
                records.append(record)
                return
            if distance not in children:
                children[distance] = (record.dhash, [record], {})
                return
            node = children[distance]

    def query(self, value: int, maximum_distance: int) -> list[tuple[int, ImageRecord]]:
        found: list[tuple[int, ImageRecord]] = []

        def visit(node: tuple[int, list[ImageRecord], dict[int, tuple]]) -> None:
            node_value, records, children = node
            distance = self.distance(value, node_value)
            if distance <= maximum_distance:
                found.extend((distance, record) for record in records)
            low, high = distance - maximum_distance, distance + maximum_distance
            for edge, child in children.items():
                if low <= edge <= high:
                    visit(child)

        if self.root is not None:
            visit(self.root)
        return found


def write_rows(path: Path, rows: list[dict]) -> None:
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    with path.open("w", newline="", encoding="utf-8") as target:
        writer = csv.DictWriter(target, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--train_dir", required=True)
    parser.add_argument("--test_dir", required=True)
    parser.add_argument("--near_distance", type=int, default=4,
                        help="maximum dHash Hamming distance (0-64; 4 is conservative)")
    parser.add_argument("--output_dir", default="dataset_audit")
    args = parser.parse_args()
    if not 0 <= args.near_distance <= 64:
        parser.error("--near_distance must be between 0 and 64")

    train_dir, test_dir, out = Path(args.train_dir), Path(args.test_dir), Path(args.output_dir)
    if not train_dir.is_dir() or not test_dir.is_dir():
        raise SystemExit("Both --train_dir and --test_dir must be existing directories.")
    out.mkdir(parents=True, exist_ok=True)

    print("Hashing training images...")
    train = scan(train_dir)
    print("Hashing test images...")
    test = scan(test_dir)
    train_by_sha = defaultdict(list)
    for record in train:
        train_by_sha[record.sha256].append(record)

    exact_rows = []
    for record in test:
        for matching in train_by_sha.get(record.sha256, []):
            exact_rows.append({
                "train_file": matching.path, "train_label": matching.label,
                "test_file": record.path, "test_label": record.label,
                "sha256": record.sha256,
            })

    tree = HashTree()
    for record in train:
        tree.add(record)
    near_rows = []
    exact_pairs = {(row["train_file"], row["test_file"]) for row in exact_rows}
    for record in test:
        for distance, matching in tree.query(record.dhash, args.near_distance):
            pair = (matching.path, record.path)
            if pair not in exact_pairs and matching.sha256 != record.sha256:
                near_rows.append({
                    "train_file": matching.path, "train_label": matching.label,
                    "test_file": record.path, "test_label": record.label,
                    "dhash_distance": distance,
                })

    train_groups = defaultdict(list)
    test_groups = defaultdict(list)
    for record in train:
        if record.exif_group:
            train_groups[record.exif_group].append(record)
    for record in test:
        if record.exif_group:
            test_groups[record.exif_group].append(record)
    exif_rows = []
    for group in sorted(train_groups.keys() & test_groups.keys()):
        exif_rows.append({
            "exif_group": group,
            "train_images": len(train_groups[group]),
            "test_images": len(test_groups[group]),
            "train_labels": " | ".join(sorted({record.label for record in train_groups[group]})),
            "test_labels": " | ".join(sorted({record.label for record in test_groups[group]})),
        })

    write_rows(out / "exact_duplicates.csv", exact_rows)
    write_rows(out / "near_duplicates.csv", near_rows)
    write_rows(out / "cross_split_exif_groups.csv", exif_rows)
    summary = {
        "train_images": len(train), "test_images": len(test),
        "exact_cross_split_pairs": len(exact_rows),
        "near_cross_split_pairs": len(near_rows),
        "near_distance": args.near_distance,
        "cross_split_exif_groups": len(exif_rows),
        "train_class_counts": dict(sorted(Counter(record.label for record in train).items())),
        "test_class_counts": dict(sorted(Counter(record.label for record in test).items())),
        "interpretation": (
            "No matching EXIF group does not prove source independence. Use a manifest with "
            "field_id, plant_id, capture_session_id and source_id for a group-disjoint split."
        ),
    }
    (out / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({key: summary[key] for key in (
        "train_images", "test_images", "exact_cross_split_pairs", "near_cross_split_pairs",
        "cross_split_exif_groups")}, indent=2))
    print(f"Saved audit evidence to {out.resolve()}")


if __name__ == "__main__":
    main()
