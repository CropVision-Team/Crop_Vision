# CropVision — Model & Pipeline Documentation

Written to satisfy the specification's requirement: *"Before final
delivery, provide model metrics, test cases, and limitations."*

---

## 1. Architecture (Validation-First Pipeline)

```
Capture/Upload → Image Quality Gate → Leaf/Non-Leaf Gate →
Crop & Disease Classification → G0–G3 Severity Decision →
Recommendation Mapping → Diagnosis History
```

No image reaches disease classification without first passing the
two validation gates. Implementation: `model/pipeline.py` (`run_diagnosis`),
mirrored in `mobile_app/lib/screens/capture/capture_screen.dart`.

**G0–G3 disease severity and the 5 crop growth stages are separate,
independent outputs** — implemented in different files
(`model/severity_estimation.py` vs `model/crop_growth_calendar.py`), computed
from different inputs (disease-affected leaf-area % vs. days-since-
planting), and never conflated in the UI.

---

## 2. G0–G3 Severity: Documented Method

**Formula:** `affected_percent = diseased_leaf_pixels / total_leaf_pixels × 100`

1. Convert image to HSV.
2. Segment "diseased" pixels (brown/yellow/necrotic hue ranges) and
   "healthy" pixels (green hue range).
3. `total_leaf_pixels` = union of both masks (not healthy-only — see
   the code comment in `_segment_leaf_mask` explaining why: excluding
   diseased pixels from the denominator silently deflates the
   percentage, verified empirically during development).
4. Map the percentage to a stage using the thresholds below.

**Default thresholds** (`model/severity_estimation.py`,
`DEFAULT_SEVERITY_THRESHOLDS`):

| Stage | Range | Meaning |
|---|---|---|
| G0 | 0–2% | Healthy |
| G1 | 2–15% | Mild |
| G2 | 15–40% | Moderate |
| G3 | 40–100% | Critical |

**Configurability:** thresholds can be overridden per-crop via
`CROP_SEVERITY_THRESHOLD_OVERRIDES` (same file) — empty by default;
populate it once specific crops have been validated against a
hand-checked photo set, since a single global cutoff may not fit
every crop/disease combination equally well.

This mirrors current plant-pathology severity-grading practice
(percentage-of-leaf-area methods) rather than an arbitrary bucket
assignment.

---

## 3. Data Augmentation (Mandatory Per Spec)

Implemented in `model/train_mobilevit.py`, `build_transforms(train=True)`.
Applied ONLY to the training split — validation and test images are
never augmented, so reported accuracy reflects real, unmodified
photos.

| Requirement | Implementation |
|---|---|
| Horizontal flip | `RandomHorizontalFlip()` |
| Rotation ±10–30° | `RandomRotation(30)` |
| Random crop and resize | `RandomResizedCrop(scale=(0.8, 1.0))` |
| Zoom in/out | Same `RandomResizedCrop` (scale range covers both) |
| Small translation/shift | `RandomAffine(translate=(0.08, 0.08))` |
| Brightness variation | `ColorJitter(brightness=0.25)` |
| Contrast variation | `ColorJitter(contrast=0.25)` |
| Slight darker/lighter | Covered by the brightness jitter range |
| Mild blur | `RandomApply([GaussianBlur], p=0.2)` |
| Small noise variation | Custom `add_gaussian_noise()`, std=0.02 |
| Conservative color jitter | `ColorJitter(saturation=0.2, hue=0.02)` |
| Perspective/affine variation | `RandomPerspective(distortion_scale=0.15, p=0.3)` |

All parameters are intentionally mild/conservative per the spec's
explicit instruction not to use unrealistic augmentation strengths.

---

## 4. Train / Validation / Test Split

A genuine 3-way split (not just train/val):

- **Train** (~70%): used for gradient updates, with augmentation.
- **Validation** (~15%): used for checkpoint selection (best `val_acc`
  wins), no augmentation.
- **Test** (~15%): held out completely — never influences training or
  checkpoint selection. Evaluated exactly once, at the end of
  `train_mobilevit.py`, and that number (`FINAL TEST SET ACCURACY`) is
  what should be reported/documented, not `val_acc`.

**Bug fixed during development:** an earlier version of the training
script created one `ImageFolder` dataset object, split it into
train/val via `random_split`, then set the validation subset's
`.transform` — but because `random_split`'s subsets share the same
underlying dataset object, this silently overwrote the transform for
*both* subsets, meaning the training set lost all augmentation without
any error or warning. Fixed by constructing separate dataset objects
per split, joined by one shared seeded index split (see `split_indices()`
and the module docstring in `train_mobilevit.py`).

---

## 5. Model & Reported Metrics

- **Architecture:** MobileViT-Small (via `timm`), fine-tuned from
  ImageNet-pretrained weights.
- **Dataset:** PlantVillage, 14 crops, 38 disease/healthy classes.
- **Result from actual training run:** `val_acc ≈ 0.98` after 1 epoch.
  *(Fill in the FINAL TEST SET ACCURACY here once you re-run training
  with this corrected script — the earlier 98%+ numbers were measured
  under the pre-fix script, i.e. without augmentation and without a
  proper train/val/test split, so they should be re-measured and
  reported from a fresh run for the final submission.)*

---

## 6. Test Cases (Per Spec Section 9)

Recommended manual test set before final delivery — one example of
each:

| Case | Expected gate behavior |
|---|---|
| Clear, healthy leaf | Passes both gates → classified healthy, G0 |
| Clear, diseased leaf | Passes both gates → disease name + G1–G3 |
| Mild symptoms | Passes gates → correct disease, low-percentage G1 |
| Blurry photo | **Rejected at Image Quality Gate** |
| Very dark photo | **Rejected at Image Quality Gate** |
| Non-plant object (e.g. a laptop) | Should be **rejected at the
  Leaf/Non-Leaf Gate** — during development this specific case (a
  laptop photo) was observed to incorrectly pass the leaf-check
  heuristic; see Limitations below. |

---

## 7. Known Limitations (Honest Disclosure)

- **Leaf/Non-Leaf gate is a color-heuristic, not a trained classifier.**
  It checks green/brown pixel ratios via HSV thresholds rather than a
  dedicated "is this a leaf" model. During testing, a laptop screen's
  glare/reflection colors were observed to occasionally pass this
  check. A more robust version would train a dedicated binary
  leaf/non-leaf classifier on a labeled dataset including diverse
  non-plant negative examples (spec Section 6-A mentions this as a
  recommended dataset addition).
- **Severity thresholds are global defaults, not yet crop-validated.**
  The per-crop override mechanism exists (Section 2) but is currently
  empty — populate it once enough hand-labeled photos per crop are
  available to justify different cutoffs.
- **Growth-stage detection is date-based, not image-based.** The
  crop-calendar module infers growth stage from days-since-planting
  and a typical per-crop calendar, not from visually analyzing plant
  structure in the photo — a single leaf close-up cannot reliably show
  whole-plant growth stage (flowering, fruiting), and no labeled
  growth-stage image dataset was available to train that separately.
- **Growth calendar day-ranges are generalized estimates**, not
  measured from this project's own data — they vary by variety,
  climate, and region in reality.
- **Training was run for 1 epoch** in the fastest validated run,
  achieving ~98% validation accuracy on this dataset — PlantVillage is
  a comparatively "easy," lab-photographed dataset, so this accuracy
  will likely not fully transfer to messier real-world field photos.
