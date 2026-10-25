"""
Shared pytest fixtures - synthetic leaf images generated fresh on each
test run (deterministic seed so failures are reproducible), rather
than relying on committed JPEG files. Mirrors the same generation
logic used during manual Phase 2 testing.
"""

import cv2
import numpy as np
import pytest


@pytest.fixture
def healthy_leaf(tmp_path):
    rng = np.random.default_rng(42)
    img = np.full((400, 400, 3), (40, 140, 60), dtype=np.uint8)
    noise = rng.integers(-15, 15, img.shape, endpoint=True)
    img = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    path = tmp_path / "healthy.jpg"
    cv2.imwrite(str(path), img)
    return str(path)


def _blotched_leaf(tmp_path, filename, n_blotches, seed=1):
    rng = np.random.default_rng(seed)
    img = np.full((400, 400, 3), (40, 140, 60), dtype=np.uint8)
    for _ in range(n_blotches):
        cx, cy = rng.integers(30, 370, 2)
        r = int(rng.integers(15, 35))
        cv2.circle(img, (int(cx), int(cy)), r, (20, 60, 120), -1)
    noise = rng.integers(-10, 10, img.shape, endpoint=True)
    img = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    path = tmp_path / filename
    cv2.imwrite(str(path), img)
    return str(path)


@pytest.fixture
def mild_leaf(tmp_path):
    return _blotched_leaf(tmp_path, "mild.jpg", n_blotches=8, seed=2)


@pytest.fixture
def moderate_leaf(tmp_path):
    return _blotched_leaf(tmp_path, "moderate.jpg", n_blotches=25, seed=3)


@pytest.fixture
def critical_leaf(tmp_path):
    return _blotched_leaf(tmp_path, "critical.jpg", n_blotches=55, seed=4)


@pytest.fixture
def blurry_leaf(healthy_leaf, tmp_path):
    img = cv2.imread(healthy_leaf)
    blurred = cv2.GaussianBlur(img, (35, 35), 0)
    path = tmp_path / "blurry.jpg"
    cv2.imwrite(str(path), blurred)
    return str(path)


@pytest.fixture
def dark_leaf(healthy_leaf, tmp_path):
    img = cv2.imread(healthy_leaf)
    dark = (img.astype(np.float32) * 0.15).astype(np.uint8)
    path = tmp_path / "dark.jpg"
    cv2.imwrite(str(path), dark)
    return str(path)


@pytest.fixture
def overexposed_leaf(healthy_leaf, tmp_path):
    img = cv2.imread(healthy_leaf)
    bright = np.clip(img.astype(np.int16) + 180, 0, 255).astype(np.uint8)
    path = tmp_path / "overexposed.jpg"
    cv2.imwrite(str(path), bright)
    return str(path)


@pytest.fixture
def non_plant_image(tmp_path):
    rng = np.random.default_rng(5)
    img = rng.integers(100, 180, (400, 400, 3), dtype=np.uint8)
    img[:, :, 0] = rng.integers(150, 200)
    path = tmp_path / "non_plant.jpg"
    cv2.imwrite(str(path), img)
    return str(path)


@pytest.fixture
def low_resolution_image(tmp_path):
    img = np.full((100, 100, 3), (40, 140, 60), dtype=np.uint8)
    path = tmp_path / "low_res.jpg"
    cv2.imwrite(str(path), img)
    return str(path)
