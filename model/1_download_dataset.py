
"""Download and organize the official PlantVillage color dataset.

Creates:
    model/dataset/<class_name>/...       Training images
    model/official_test/<class_name>/... Official test images

This bypasses the text-only Hugging Face auto-converted dataset view.
"""

from pathlib import Path, PurePosixPath
from urllib.request import Request, urlopen
from zipfile import ZipFile
import shutil
import re
import sys


BASE_URL = "https://huggingface.co/datasets/mohanty/PlantVillage/resolve/main"
WORK_DIR = Path("./plantvillage_download")
ARCHIVE = WORK_DIR / "data.zip"
SOURCE_DIR = WORK_DIR / "extracted"
TRAIN_LIST = WORK_DIR / "color_train.txt"
TEST_LIST = WORK_DIR / "color_test.txt"

TRAIN_DIR = Path("./dataset")
TEST_DIR = Path("./official_test")


def safe_name(name: str) -> str:
    """Keep class names safe for Windows folders."""
    return re.sub(r'[<>:"/\\|?*]', "_", name).strip()


def download_file(url: str, destination: Path) -> None:
    """Download a file, showing progress and checking HTTP errors."""
    destination.parent.mkdir(parents=True, exist_ok=True)

    if destination.exists() and destination.stat().st_size > 0:
        print(f"Already downloaded: {destination}")
        return

    print(f"\nDownloading: {url}")
    request = Request(url, headers={"User-Agent": "CropVision-dataset-downloader"})

    try:
        with urlopen(request, timeout=60) as response, destination.open("wb") as out:
            total = int(response.headers.get("Content-Length", 0))
            downloaded = 0

            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break

                out.write(chunk)
                downloaded += len(chunk)

                if total:
                    percent = downloaded * 100 / total
                    print(
                        f"\r  {downloaded / (1024**2):.1f} MB "
                        f"({percent:.1f}%)",
                        end="",
                        flush=True,
                    )
                else:
                    print(
                        f"\r  {downloaded / (1024**2):.1f} MB",
                        end="",
                        flush=True,
                    )

        print("\nDownload complete.")

        if destination.stat().st_size == 0:
            destination.unlink(missing_ok=True)
            raise RuntimeError(f"Downloaded file is empty: {destination}")

    except Exception:
        destination.unlink(missing_ok=True)
        raise


def safe_extract(zip_path: Path, destination: Path) -> None:
    """Extract an archive while preventing paths outside the target folder."""
    destination.mkdir(parents=True, exist_ok=True)
    root = destination.resolve()

    with ZipFile(zip_path) as archive:
        for member in archive.infolist():
            target = (destination / member.filename).resolve()

            if target != root and root not in target.parents:
                raise RuntimeError(
                    f"Unsafe path found in archive: {member.filename}"
                )

        print(f"Extracting {zip_path}...")
        archive.extractall(destination)

    print("Extraction complete.")


def locate_image(source_root: Path, relative_path: str) -> Path:
    """Find an image listed in the official split file."""
    normalized = PurePosixPath(relative_path.strip())

    if normalized.is_absolute() or ".." in normalized.parts:
        raise RuntimeError(f"Unexpected image path: {relative_path}")

    # Try the exact path first.
    candidate = source_root.joinpath(*normalized.parts)
    if candidate.is_file():
        return candidate

    # Some archives contain an extra top-level directory.
    matches = list(source_root.rglob(normalized.name))
    expected_parent = normalized.parent.name

    for match in matches:
        if match.parent.name == expected_parent:
            return match

    raise FileNotFoundError(
        f"Image listed in split file was not found: {relative_path}"
    )


def export_split(
    split_file: Path,
    source_root: Path,
    output_dir: Path,
) -> int:
    """Copy split-listed images into ImageFolder class directories."""
    if not split_file.is_file():
        raise FileNotFoundError(f"Split list not found: {split_file}")

    lines = [
        line.strip().replace("\\", "/")
        for line in split_file.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]

    if not lines:
        raise RuntimeError(f"Split list is empty: {split_file}")

    count = 0

    for index, relative_path in enumerate(lines, start=1):
        parts = PurePosixPath(relative_path).parts

        # Expected format: raw/color/<class_name>/<filename>
        if len(parts) < 4 or parts[0] != "raw" or parts[1] != "color":
            raise RuntimeError(
                f"Unexpected split entry: {relative_path}"
            )

        class_name = safe_name(parts[2])
        source_file = locate_image(source_root, relative_path)

        class_dir = output_dir / class_name
        class_dir.mkdir(parents=True, exist_ok=True)

        destination = class_dir / source_file.name

        if destination.exists():
            raise RuntimeError(f"Duplicate destination file: {destination}")

        shutil.copy2(source_file, destination)
        count += 1

        if index % 1000 == 0 or index == len(lines):
            print(f"  {output_dir}: {index}/{len(lines)} images")

    return count


def main() -> None:
    WORK_DIR.mkdir(parents=True, exist_ok=True)

    # Protect existing data. Never delete files automatically.
    for folder in (TRAIN_DIR, TEST_DIR):
        if folder.exists() and any(folder.iterdir()):
            raise SystemExit(
                f"\nSTOP: {folder} already contains files.\n"
                "Check its contents before running again. "
                "This script will not overwrite your data."
            )

    try:
        download_file(f"{BASE_URL}/data.zip", ARCHIVE)
        download_file(f"{BASE_URL}/splits/color_train.txt", TRAIN_LIST)
        download_file(f"{BASE_URL}/splits/color_test.txt", TEST_LIST)

        if not SOURCE_DIR.exists() or not any(SOURCE_DIR.iterdir()):
            safe_extract(ARCHIVE, SOURCE_DIR)

        print("\nPreparing official training images...")
        train_count = export_split(TRAIN_LIST, SOURCE_DIR, TRAIN_DIR)

        print("\nPreparing official test images...")
        test_count = export_split(TEST_LIST, SOURCE_DIR, TEST_DIR)

        train_classes = {
            p.name for p in TRAIN_DIR.iterdir() if p.is_dir()
        }
        test_classes = {
            p.name for p in TEST_DIR.iterdir() if p.is_dir()
        }

        print("\n========== DATASET SUMMARY ==========")
        print(f"Training images: {train_count}")
        print(f"Official test images: {test_count}")
        print(f"Training classes: {len(train_classes)}")
        print(f"Test classes: {len(test_classes)}")
        print(f"Class folders match: {train_classes == test_classes}")
        print(f"Training folder: {TRAIN_DIR.resolve()}")
        print(f"Test folder: {TEST_DIR.resolve()}")

        if train_count != 43596 or test_count != 10709:
            print(
                "\nWARNING: Counts differ from the expected official split. "
                "Check the output before training."
            )

        if len(train_classes) != 38 or train_classes != test_classes:
            raise RuntimeError(
                "The class folders are incomplete or inconsistent."
            )

        print("\nDataset export completed. Check train_mobilevit.py next.")

    except Exception as exc:
        print(f"\nERROR: {exc}", file=sys.stderr)
        print(
            "No training was started. Send the complete error output "
            "so the download source can be corrected if necessary.",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
