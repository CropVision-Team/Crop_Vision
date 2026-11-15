# CropVision
## Mobile-Based Crop Disease Detection with Image Verification and Stage-Based Treatment Recommendation

### Final Year Project Report — B.E. / B.Tech (Computer Science / AI)

---

## Table of Contents

1. Abstract
2. Introduction
3. Problem Statement
4. Objectives
5. System Architecture
6. Technology Stack
7. Module Descriptions
8. Database Design
9. AI Model & Pipeline
10. Mobile Application
11. Testing & Validation
12. Known Limitations
13. Future Scope
14. Conclusion
15. Team
16. References

---

## 1. Abstract

CropVision is a mobile application designed to help farmers detect crop diseases early and receive stage-specific treatment recommendations. The system takes a photograph of a crop leaf, validates the image quality, classifies the disease using a deep learning model (MobileViT-Small), estimates disease severity on a G0–G3 scale using HSV colour segmentation, and presents actionable treatment advice retrieved from a structured database. A conversational AI assistant powered by the Google Gemini API is also included to answer follow-up questions in natural language. The entire pipeline — from image capture to recommendation — runs within the app, backed by a Supabase cloud database for history, reminders, and user authentication.

---

## 2. Introduction

Agriculture accounts for a significant share of India's GDP and employment. One of the major challenges farmers face is timely and accurate identification of crop diseases, which, if left undetected, can cause severe yield losses. Most farmers rely on visual inspection and manual consultation with agronomists, which is costly and often delayed. Smartphone penetration in rural areas has increased dramatically, creating an opportunity to deploy AI-powered diagnostic tools directly in the hands of farmers.

CropVision was built as a final year project to demonstrate a practical, end-to-end implementation of such a system. It combines modern deep learning (MobileViT, a transformer-based lightweight architecture), classical computer vision (HSV colour masking for severity estimation), a structured relational database for crop treatment knowledge, and a polished cross-platform Flutter mobile app.

---

## 3. Problem Statement

Crop disease detection in the field faces three main challenges:

- **Late detection:** By the time visible symptoms are identified, the infection has often progressed significantly.
- **Lack of expert access:** Farmers in remote areas cannot easily consult plant pathologists.
- **Generic advice:** Even when disease is identified, generic treatment suggestions fail to account for severity, leading to under- or over-treatment.

CropVision addresses all three by providing an instant, photo-based diagnosis with severity-graded treatment guidance.

---

## 4. Objectives

1. Build a mobile app that allows farmers to photograph crop leaves directly or upload from gallery.
2. Implement an image quality gate that rejects blurry, dark, or non-plant images before classification.
3. Train a MobileViT-Small model on the PlantVillage dataset to classify 38 disease/healthy classes across 14 crop types.
4. Implement HSV-based severity estimation producing G0 (healthy), G1 (mild), G2 (moderate), and G3 (critical) grades.
5. Store structured treatment and prevention recommendations in a Supabase PostgreSQL database (65 disease/severity combinations).
6. Integrate the Google Gemini API as an AI assistant for natural-language follow-up queries.
7. Maintain a full diagnosis history per user, with calendar-based crop growth stage tracking and reminder functionality.
8. Deploy the backend schema with proper Row-Level Security so each user can only access their own records.

---

## 5. System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP                        │
│                                                              │
│  Auth → Home → Capture → Results → History → Calendar → AI  │
└───────────────────────┬──────────────────────────────────────┘
                        │
           ┌────────────▼────────────┐
           │    IMAGE PIPELINE       │
           │  (Dart port of Python)  │
           │                         │
           │  1. Quality Gate        │  blur / brightness check
           │  2. Leaf Gate           │  HSV green-pixel ratio
           │  3. Upload to Supabase  │  Storage bucket
           │  4. Disease Classify    │  MobileViT (mocked → real)
           │  5. Severity Estimate   │  HSV G0–G3
           │  6. Treatment Lookup    │  Supabase DB query
           └────────────┬────────────┘
                        │
           ┌────────────▼────────────┐
           │   SUPABASE BACKEND      │
           │                         │
           │  PostgreSQL (RLS)        │
           │  Auth (email/password)   │
           │  Storage (leaf images)   │
           └────────────┬────────────┘
                        │
           ┌────────────▼────────────┐
           │   PYTHON BACKEND        │
           │   inference_server.py   │
           │   (FastAPI, port 8000)  │
           └─────────────────────────┘
```

The Python inference server is the bridge between the trained PyTorch model and the Flutter app. The Flutter app sends image bytes; the server returns a predicted class label and confidence score.

---

## 6. Technology Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| UI Components | Material 3, custom widgets |
| Auth & Database | Supabase (PostgreSQL 16 + Auth) |
| Storage | Supabase Storage |
| AI Model | MobileViT-Small via `timm` (PyTorch) |
| Inference Server | FastAPI (`inference_server.py`, port 8000) |
| Image Processing | OpenCV, PIL/Pillow, HSV colour masking |
| Severity Estimation | Custom HSV segmentation (`severity_estimation.py`) |
| AI Assistant | Google Gemini API |
| Calendar | `table_calendar` Flutter package |
| Testing | pytest (53 tests) |
| Documentation Website | Plain HTML/CSS/JS, served at port 3000 |

---

## 7. Module Descriptions

### 7.1 `model/image_verification.py`

Validates every image before it reaches the disease classifier. Checks are run in the order that makes physical sense — brightness is checked *before* blur, because a very dark image naturally has low Laplacian variance and would otherwise be misreported as blurry.

| Check | Method | Reject condition |
|---|---|---|
| Brightness | Mean pixel intensity | < 40 (too dark) or > 220 (overexposed) |
| Blur | Laplacian variance | < 100 |
| Plant content | HSV green/brown pixel ratio | < 15% of frame |
| Resolution | Width × Height | < 224 × 224 |

### 7.2 `model/severity_estimation.py`

Estimates disease severity from a leaf image using HSV colour segmentation.

**Formula:**
```
affected_percent = diseased_leaf_pixels / total_leaf_pixels × 100
```

`total_leaf_pixels` is the union of healthy-tissue AND diseased-tissue colour ranges — an important fix discovered during development: if only green pixels are counted in the denominator, necrotic brown areas are excluded, which silently deflates the percentage. A 25%-diseased leaf was measuring as ~3% before this fix.

| Stage | Threshold | Meaning |
|---|---|---|
| G0 | 0 – 2% | Healthy |
| G1 | 2 – 15% | Mild infection |
| G2 | 15 – 40% | Moderate infection |
| G3 | 40 – 100% | Critical — immediate action |

### 7.3 `model/pipeline.py`

Chains all steps into a single `run_diagnosis(image_path, expected_crop)` function:

```
Image → Image Verification → Disease Classification
      → Severity Estimation → Treatment Lookup → Result
```

Any failure at the verification stage stops execution and returns a rejection reason. This prevents the model from attempting to classify non-leaf images.

### 7.4 `model/inference_server.py` (port 8000)

A FastAPI server that loads the trained MobileViT checkpoint and exposes a `/predict` endpoint. The Flutter app sends a `multipart/form-data` request with the leaf image; the server returns JSON:

```json
{
  "class": "Tomato___Early_blight",
  "confidence": 0.97,
  "crop": "Tomato"
}
```

### 7.5 `model/train_mobilevit.py`

Full PyTorch training script for MobileViT-Small with:
- PlantVillage dataset (38 classes, 14 crop types)
- Proper 70/15/15 train/val/test split using separate dataset objects per split (to prevent augmentation leakage — a bug that was found and fixed during development where shared dataset objects caused the validation set to silently lose the training augmentation)
- Data augmentation: horizontal flip, rotation ±30°, random crop/resize, affine translation, brightness/contrast jitter, mild Gaussian blur, Gaussian noise, perspective distortion
- `timm` for pretrained MobileViT-Small weights
- Best checkpoint saved on validation accuracy

### 7.6 `model/treatment_recommendations.py`

Single source of truth for all treatment text — 65 disease/severity combinations across Tomato (10 classes), Potato (3 classes), Apple, Corn, and Grape. This file is the canonical source; both the SQL seed file (`backend/seed_treatment_guidelines.sql`) and the Dart data file (`lib/data/treatment_recommendations.dart`) are auto-generated from it, keeping all three in sync.

### 7.7 `model/crop_growth_calendar.py`

Estimates the current crop growth stage (seedling → vegetative → flowering → fruiting → maturity) based on days-since-planting and a per-crop typical calendar. This is a date-based estimate, not a visual one — the calendar drives the app's planting tracker feature, not the disease pipeline.

---

## 8. Database Design

All tables live in a Supabase PostgreSQL instance with Row-Level Security (RLS) enabled on every table.

### Tables

| Table | Purpose |
|---|---|
| `profiles` | One row per registered user (links to Supabase Auth) |
| `crops` | Reference table: 5 supported crop types |
| `diagnoses` | Stores every diagnosis: image URL, disease, severity, timestamp |
| `treatment_guidelines` | 65 disease/severity → treatment/prevention text rows |
| `reminders` | Per-user spray/treatment reminders with dates |
| `chat_messages` | Stores AI assistant conversation history per user |

### Security

- RLS is enabled on all 6 tables
- Users can only `SELECT`, `INSERT`, `UPDATE`, `DELETE` their own rows
- `crops` and `treatment_guidelines` are read-only for all authenticated users
- Storage bucket has per-user insert, select, and delete policies

### Indexes

Indexes on `(user_id, created_at)` for `diagnoses`, `reminders`, and `chat_messages` — matching the actual query patterns (always filtered by user, always ordered by timestamp).

---

## 9. AI Model & Pipeline

### Architecture
- **Model:** MobileViT-Small (Vision Transformer + MobileNet hybrid, optimised for mobile deployment)
- **Pretrained on:** ImageNet-1K
- **Fine-tuned on:** PlantVillage (colour variant)
- **Classes:** 38 (14 crop types × disease + healthy combinations)
- **Input size:** 256 × 256 RGB
- **Reported val_acc:** ≈ 98% after 1 epoch on PlantVillage

> **Note:** PlantVillage is a lab-photographed dataset with controlled lighting. Real-world field accuracy is expected to be lower; re-validation on collected field photos is recommended before clinical use.

### Data Augmentation Applied

| Augmentation | Parameter |
|---|---|
| Horizontal flip | 50% probability |
| Rotation | ±30° |
| Random crop/resize | Scale 0.8–1.0 |
| Affine translation | 8% in x and y |
| Brightness/contrast jitter | 25% range |
| Saturation/hue jitter | Conservative (0.2 / 0.02) |
| Gaussian blur | Applied 20% of the time |
| Gaussian noise | std = 0.02 |
| Perspective distortion | Scale 0.15, 30% probability |

---

## 10. Mobile Application

Built with Flutter for cross-platform deployment (Android & iOS from a single codebase).

### Screens

| Screen | Function |
|---|---|
| `auth_screen.dart` | Sign-in and sign-up with Supabase email auth |
| `home_screen.dart` | Dashboard with quick actions and recent diagnoses |
| `capture_screen.dart` | Camera/gallery capture → full pipeline → results |
| `result_screen.dart` | Displays disease name, severity, treatment & prevention |
| `history_screen.dart` | Diagnosis history list, filterable by crop |
| `calendar_screen.dart` | Crop growth stage calendar and reminder management |
| `assistant_screen.dart` | Gemini-powered AI chat assistant |

### Services

| Service | Role |
|---|---|
| `SupabaseService` | All database and storage operations |
| `InferenceService` | HTTP call to `inference_server.py` at port 8000 |
| `ImageVerificationService` | Dart port of `image_verification.py` |
| `SeverityEstimationService` | Dart port of `severity_estimation.py` |

### APK

A debug APK (`CropVision.apk`) is available in the project root. For production release, build a signed APK using:

```powershell
cd "c:\Users\Varun\Desktop\final year projct\mobile_app"
flutter build apk --release
```

---

## 11. Testing & Validation

### Automated Test Suite (53 tests, 0 failures)

```bash
cd model
python -m pytest tests/ -v
```

| Test File | Covers |
|---|---|
| `test_image_verification.py` | Valid/invalid images: blurry, dark, overexposed, non-plant, low-res, missing file |
| `test_severity_estimation.py` | G0–G3 thresholds, monotonicity, pixel-count bounds |
| `test_treatment_recommendations.py` | Known disease/severity combos, fallback behavior, healthy/severity contradiction |
| `test_pipeline_integration.py` | Full pipeline: rejection stops early, valid images complete, context-match logic |

### Pipeline Manual Tests

| Input | Expected Output | Result |
|---|---|---|
| `healthy_leaf.jpg` | G0 healthy, no disease | ✅ Pass |
| `diseased_leaf.jpg` | Tomato Early Blight, G2 Moderate | ✅ Pass |
| `critical_leaf.jpg` | G3 Critical + treatment text | ✅ Pass |
| `blurry_leaf.jpg` | Rejected at image quality gate | ✅ Pass |
| `dark_leaf.jpg` | Rejected — too dark | ✅ Pass |
| `non_plant.jpg` | Rejected — no crop leaf detected | ✅ Pass |

### Database Verification (run against real PostgreSQL 16)

```
CREATE TABLE ×6, ALTER TABLE, CREATE POLICY ×14, CREATE INDEX ×3 → all succeeded
seed_crops.sql:                INSERT 0 5   (5 crops)
seed_treatment_guidelines.sql: INSERT 0 65  (65 disease/severity entries)
RLS check: all 6 tables → relrowsecurity = true
```

---

## 12. Known Limitations

1. **Leaf/Non-Leaf gate is heuristic-based.** It uses HSV green/brown pixel ratios rather than a dedicated binary classifier. Unusual lighting or reflective surfaces can occasionally fool it.

2. **Severity thresholds are global defaults.** The per-crop override mechanism (`CROP_SEVERITY_THRESHOLD_OVERRIDES`) exists but is currently unpopulated — fine-tuning requires ~50–100 hand-checked photos per crop.

3. **Growth stage is date-based, not image-based.** The calendar infers stage from days-since-planting. Visual growth stage detection from a single leaf close-up is not currently implemented.

4. **Training was 1 epoch in the fastest verified run.** PlantVillage is a controlled-condition dataset; expect lower accuracy on real field photos with variable lighting and angles.

5. **The inference server requires a trained checkpoint.** A mock classifier is used in the current build. Replace `classify_disease_MOCK` in `pipeline.py` and `InferenceService` in the Flutter app once training is complete.

---

## 13. Future Scope

- Replace the HSV leaf-validity gate with a trained binary leaf/non-leaf classifier to improve robustness against non-plant backgrounds.
- Re-train the model on additional field photographs (not just PlantVillage lab images) to improve real-world accuracy.
- Add push notifications for reminders using `flutter_local_notifications`.
- Implement offline inference by bundling a TorchScript or TFLite model directly inside the app, removing the dependency on the inference server.
- Expand treatment database to include regional crop varieties and locally available pesticides.
- Add multi-language support (Tamil, Hindi, Kannada) for better accessibility in rural India.

---

## 14. Conclusion

CropVision demonstrates a complete, technically grounded implementation of a mobile crop disease detection system. The project covers the full stack: deep learning model training, classical computer vision for severity grading, a relational database with proper security policies, a Flutter mobile app, a REST inference server, and an AI assistant. All core components have been tested — 53 automated tests pass with zero failures, and the database schema was verified against a real PostgreSQL instance. The system is ready for integration with a trained model checkpoint and field validation.

---

## 15. Team

**Project Guide:** Ms. Suchithra M

| Student | Name |
|---|---|
| Student 1 | Varun Sivaselvan V S |
| Student 2 | Deepan S |
| Student 3 | Ripan Samui |
| Student 4 | Doreti Uday Kumar |

**Institution:** [Your College Name]
**Department:** Computer Science & Engineering / Artificial Intelligence
**Academic Year:** 2025–2026

---

## 16. References

1. Hughes, D., & Salathé, M. (2015). *An open access repository of images on plant health to enable the development of mobile disease diagnostics*. arXiv:1511.08060. (PlantVillage Dataset)

2. Mehta, S., & Rastegari, M. (2022). *MobileViT: Light-weight, General-purpose, and Mobile-friendly Vision Transformer*. ICLR 2022. arXiv:2110.02178.

3. Supabase. (2023). *Supabase Documentation*. https://supabase.com/docs

4. Google. (2024). *Gemini API Documentation*. https://ai.google.dev/docs

5. PyTorch. (2024). *PyTorch Documentation*. https://pytorch.org/docs

6. `timm` — PyTorch Image Models. Ross Wightman. https://github.com/huggingface/pytorch-image-models

7. Flutter. (2024). *Flutter Documentation*. https://docs.flutter.dev

8. Bradski, G. (2000). *The OpenCV Library*. Dr. Dobb's Journal of Software Tools.

9. FastAPI. (2024). *FastAPI Documentation*. https://fastapi.tiangolo.com

---

*Report generated for final year project submission. All source code available in the project repository.*
