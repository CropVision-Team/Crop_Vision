"""
Step 1: Download the actual PlantVillage dataset files.

IMPORTANT: load_dataset('mohanty/PlantVillage', 'color') does NOT work
directly - that HF dataset's 'text' column only lists file PATHS, not
actual image bytes (found via real testing). The real images are
inside a data.zip file in the same repository. This script downloads
that zip using snapshot_download instead.

Run: python 1_download_dataset.py
Then: python 2_extract_and_organize.py
Then: python train_mobilevit.py --data_dir ./dataset --epochs 1
"""

from huggingface_hub import snapshot_download

print("Downloading full PlantVillage repository (includes data.zip with actual images)...")
local_dir = snapshot_download(
    repo_id="mohanty/PlantVillage",
    repo_type="dataset",
    local_dir="./plantvillage_files",
)
print(f"Downloaded to: {local_dir}")
print("Next step: run 2_extract_and_organize.py")
