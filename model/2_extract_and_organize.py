"""
Step 2: Extract data.zip (downloaded by 1_download_dataset.py) and find
the 'color' subfolder inside (matching real leaf photos, as opposed to
'grayscale' or 'segmented' variants also in the same archive), then
copy it to ./dataset for train_mobilevit.py to use directly.
"""

import zipfile
import os
import shutil

zip_path = "./plantvillage_files/data.zip"
extract_dir = "./plantvillage_extracted"

if not os.path.exists(zip_path):
    print(f"ERROR: {zip_path} not found. Run 1_download_dataset.py first.")
    raise SystemExit(1)

print(f"Extracting {zip_path} (2+ GB, this can take several minutes)...")
with zipfile.ZipFile(zip_path, "r") as zf:
    zf.extractall(extract_dir)
print("Extraction complete.")

color_dir = None
for root, dirs, files in os.walk(extract_dir):
    if os.path.basename(root) == "color":
        color_dir = root
        break

if color_dir is None:
    print("Could NOT find a 'color' folder after extraction.")
    print("Folder structure found instead:")
    for root, dirs, files in os.walk(extract_dir):
        level = root.replace(extract_dir, "").count(os.sep)
        indent = "  " * level
        print(f"{indent}{os.path.basename(root)}/")
        if level < 3:
            for f in files[:3]:
                print(f"{indent}  {f}")
else:
    print(f"Found color images at: {color_dir}")
    subfolders = [d for d in os.listdir(color_dir) if os.path.isdir(os.path.join(color_dir, d))]
    print(f"Found {len(subfolders)} class folders, e.g.: {subfolders[:5]}")

    if os.path.exists("./dataset"):
        print("./dataset already exists - not overwriting. Delete it first for a fresh copy.")
    else:
        print("Copying into ./dataset (can take a few minutes)...")
        shutil.copytree(color_dir, "./dataset")
        print("Done! You can now run: python train_mobilevit.py --data_dir ./dataset --epochs 1")
