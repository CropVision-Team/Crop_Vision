<div align="center">

# 🌾 CropVision

### Real-Time Edge-Native Crop Disease Detection with Severity Grading & Agronomic Advisory

[![Website](https://img.shields.io/badge/Website-g066website.vercel.app-red.svg?logo=vercel)](https://g066website.vercel.app/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B.svg?logo=flutter)](https://flutter.dev/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.x-EE4C2C.svg?logo=pytorch)](https://pytorch.org/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E.svg?logo=supabase)](https://supabase.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

**54,305 images · 14 crops · 38 classes · 98.56% test accuracy (10,555/10,709) · 5.8 MB model · 43 ms inference**

[🌐 Website](https://g066website.vercel.app/) · [📖 Documentation](#documentation) · [🚀 Quick Start](#quick-start) · [📊 Results](#model-performance) · [🤝 Contributing](CONTRIBUTING.md) · [📋 Changelog](CHANGELOG.md)

</div>

---

> 🌐 **Live Website / Web App:** [https://g066website.vercel.app/](https://g066website.vercel.app/)

## 📋 Overview

**CropVision** is an end-to-end, edge-native agricultural intelligence framework that enables real-time crop disease detection on mobile devices — completely offline, without internet connectivity. It combines validation-first pre-processing, lightweight Vision Transformers, biological hierarchical classification, and HSV-based lesion severity grading.

### Key Capabilities

| Feature | Description |
|---------|-------------|
| 🔍 **Image Verification** | On-device blur detection & leaf/non-leaf validation gates |
| 🧠 **Disease Classification** | MobileViT-Small with 38-class pathology identification |
| 📊 **Severity Grading** | HSV-based lesion area quantification (G0–G3 stages) |
| 💊 **Treatment Advisory** | FRAC-coded fungicide/bactericide + organic bio-control prescriptions |
| 📱 **Offline Inference** | PTQ INT8 quantized to 5.8 MB, runs at 43ms on budget phones |
| 🌍 **10 Languages** | Hindi, Bengali, Telugu, Tamil, Marathi, Gujarati, Punjabi, Spanish, Swahili |
| ☁️ **Cloud Telemetry** | PostGIS spatial outbreak tracking with Row-Level Security |

---

## 🏗️ Architecture

```
Image Capture → Quality Gate (blur/exposure) → Leaf Verification Gate (HSV)
    → Disease Classification (MobileViT-Small) → Severity Grading (G0–G3)
    → Treatment Recommendation → Diagnosis History + Cloud Sync
```

### System Framework

```mermaid
flowchart LR
    subgraph Edge ["Mobile Edge (Offline)"]
        CAM["Camera Capture"] --> QG["Quality Gate<br/>(Blur & Exposure)"]
        QG --> LV["Leaf Verification<br/>(HSV Gate)"]
        LV --> INF["TFLite Engine<br/>(5.8 MB / 43ms)"]
        INF --> SEV["HSV Severity<br/>(G0-G3)"]
        SEV --> RX["Treatment Advisory<br/>& Offline Storage"]
    end

    subgraph Cloud ["Cloud Tier"]
        API["FastAPI<br/>Gateway"]
        DB[("Supabase<br/>PostgreSQL")]
        GIS["PostGIS<br/>Outbreak Map"]
        API --> DB
        API --> GIS
    end

    RX -.->|WiFi / 4G Telemetry Sync| API
```

<p align="center">
  <img src="docs/research_figures/system_framework_flowchart.png" alt="CropVision System Architecture & Framework" width="100%" />
</p>

---

## 📂 Project Structure

```
CropVision/
├── model/                          # 🧠 Python + PyTorch ML pipeline
│   ├── architectures/              #    Model architectures (MobileViT-V2, EfficientNet, etc.)
│   ├── benchmarks/                 #    Performance benchmarking tools
│   ├── explainability/             #    GradCAM & Integrated Gradients
│   ├── quantization/               #    PTQ INT8 pipeline & exporters
│   ├── tests/                      #    pytest suite (53+ tests)
│   ├── train_cropvision.py         #    Primary training script
│   ├── train_mobilevit.py          #    MobileViT-Small fine-tuning
│   ├── evaluate_test.py            #    Held-out test evaluation
│   ├── image_verification.py       #    Quality + leaf validation gates
│   ├── severity_estimation.py      #    HSV-based G0–G3 grading
│   ├── treatment_recommendations.py #   FRAC treatment mapping
│   ├── pipeline.py                 #    End-to-end inference pipeline
│   ├── inference_server.py         #    FastAPI REST server
│   └── requirements.txt
│
├── mobile_app/                     # 📱 Flutter cross-platform app
│   ├── lib/
│   │   ├── blocs/                  #    BLoC state management
│   │   ├── screens/                #    UI screens (auth, capture, home, etc.)
│   │   ├── services/               #    Backend & inference services
│   │   ├── models/                 #    Data models
│   │   ├── widgets/                #    Reusable UI components
│   │   ├── l10n/                   #    Localization (10 languages)
│   │   └── theme/                  #    App theming
│   └── pubspec.yaml
│
├── backend/                        # ☁️ Supabase backend
│   ├── services/                   #    12 enterprise services
│   ├── database/                   #    Migration schemas
│   ├── edge-functions/             #    Serverless functions
│   ├── tests/                      #    Backend test suites
│   ├── supabase_schema.sql         #    Core schema with RLS
│   ├── seed_crops.sql              #    Crop seed data
│   └── seed_treatment_guidelines.sql
│
├── docs/                           # 📖 Documentation
│   ├── agronomy/                   #    Field guides & treatment protocols
│   ├── api/                        #    OpenAPI 3.1 specification
│   ├── architecture/               #    System design & RFC documents
│   ├── models/                     #    Model cards & evaluation protocol
│   └── research_figures/           #    Publication-quality figures
│
├── .github/                        # ⚙️ GitHub configuration
│   ├── workflows/                  #    CI/CD pipelines
│   ├── ISSUE_TEMPLATE/             #    Bug, feature, crop support templates
│   └── pull_request_template.md
│
├── CROPVISION_PROJECT_DOCUMENTATION.md  # Full research paper
├── MODEL_DOCUMENTATION.md          # Model & pipeline documentation
├── CONTRIBUTING.md                 # Contribution guidelines
├── CHANGELOG.md                    # Version history
├── CODE_OF_CONDUCT.md              # Community standards
├── SECURITY.md                     # Security policy
├── LICENSE                         # MIT License
└── .env.example                    # Environment variable template
```

---

## 🚀 Quick Start

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Python | ≥ 3.10 | ML pipeline |
| PyTorch | ≥ 2.0 | Model training & inference |
| Flutter | ≥ 3.19 | Mobile application |
| Supabase | — | Backend-as-a-Service |

### 1. Clone the Repository

```bash
git clone https://github.com/CropVision-Team/Crop_Vision.git
cd Crop_Vision
```

### 2. Python / ML Pipeline Setup

```bash
cd model
python -m venv venv

# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

Verify GPU availability (optional but recommended):
```bash
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
```

### 3. Flutter Mobile App Setup

```bash
cd mobile_app
flutter pub get
flutter doctor     # Check platform tooling
flutter analyze    # Verify code health
flutter run        # Launch on device/emulator
```

> **Configuration**: Pass your Supabase credentials at runtime:
> ```bash
> flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=xxx
> ```

### 4. Supabase Backend Setup

1. Create a project at [supabase.com](https://supabase.com)
2. Run SQL files in **SQL Editor** (in order):
   ```
   1. backend/supabase_schema.sql
   2. backend/seed_crops.sql
   3. backend/seed_treatment_guidelines.sql
   ```
3. Copy `.env.example` → `.env` and add your API keys
4. Enable Email/Password authentication in **Authentication → Providers**

### 5. Run Tests

```bash
# ML pipeline tests
cd model
pip install pytest
python -m pytest tests/ -v

# Dataset integrity audit
python audit_dataset.py --train_dir ./dataset --test_dir ./official_test
```

---

## 📊 Model Performance

Evaluation on the 10,709-image held-out PlantVillage test split (14 crops, 38 classes). Near-duplicate images between the training and test splits were removed with a 64-bit dHash check (Hamming distance ≤ 4) before testing. The test set was used once, after training finished.

> ⚠️ **Scope of these results**: PlantVillage contains laboratory-style, single-leaf photographs on plain backgrounds. The figures below measure performance on this benchmark, not on farmer photographs taken in the field. Field testing is the main open next step.

### Headline Results (MobileViT-Small)

| Metric | Score | Details |
|--------|:-----:|---------|
| **Test Accuracy** ⭐ | **98.56%** | **10,555 of 10,709 correct** across all 38 classes |
| **Macro-F1** | **0.9810** | Unweighted mean F1 over 38 classes |
| **Top-5 Accuracy** | **99.92%** | Top-5 pathological prediction match |
| **Expected Calibration Error** | **0.022** | Reliability calibration error |
| **Parameters / GFLOPs** | **5.6 M / 1.9** | 224 × 224 input |
| **INT8 TFLite Size** | **5.8 MB** | Reduced from 22.4 MB (full-integer PTQ) |
| **Inference Latency** | **43.0 ms** | Snapdragon 680-class CPU, ~48 MB RAM |

*The accuracy, macro-F1, top-5 and ECE values were measured on the full-precision checkpoint. The accuracy of the INT8 model on the same test set has not yet been measured.*

### Model Comparison

| Model | Acc. (%) | Macro-F1 | Params (M) | GFLOPs | INT8 (MB) | Latency (ms) | RAM (MB) |
|-------|:--------:|:--------:|:----------:|:------:|:---------:|:------------:|:--------:|
| **MobileViT-Small** ⭐ | **98.56** | **0.9810** | 5.60 | 1.9 | **5.8** | **43.0** | 48 |
| **DE-HVT** | 98.38 | 0.9798 | 5.21 | 3.6 | 7.7 | 66.4 | 78 |
| **XCiT-Nano-12** | 97.95 | 0.9765 | 3.05 | 4.5 | 3.1 | 82.0 | 48 |
| **DeiT-Tiny/16** | 97.74 | 0.9742 | 5.72 | 1.3 | 5.7 | 72.3 | 60 |
| **MobileViT-v2** | 98.15 | 0.9780 | 4.90 | 1.6 | 5.1 | 38.5 | 42 |
| **ConvNeXt** | 97.94 | 0.9750 | 3.70 | 1.1 | 3.9 | 32.0 | 38 |
| **EfficientNet-B0** | 97.82 | 0.9730 | 4.02 | 0.8 | 4.2 | 29.4 | 35 |
| **DenseNet121** | 96.80 | 0.9630 | 7.20 | 5.7 | 8.1 | 68.0 | 85 |
| **VGG16** | 94.20 | 0.9360 | 5.45 | 6.5 | 4.0 | 74.6 | 79 |
| **MobileNetV3-Large** | 95.50 | 0.9430 | 5.40 | 5.4 | 5.5 | 24.5 | 32 |

*Each model was trained once, so differences of a few tenths of a point (about ±0.23 points at 95% confidence for 98.56% on 10,709 images) should not be over-interpreted.*

### Per-Crop Results (MobileViT-Small)

| Crop | Classes | Images (Whole Dataset) | Accuracy (%) | Macro-F1 |
|------|:-------:|:----------------------:|:------------:|:--------:|
| **Blueberry** | 1 | 1,502 | 99.69 | 0.9970 |
| **Soybean** | 1 | 5,090 | 99.69 | 0.9972 |
| **Bell Pepper** | 2 | 2,475 | 99.55 | 0.9957 |
| **Squash** | 1 | 1,835 | 99.47 | 0.9948 |
| **Orange** | 1 | 5,507 | 99.39 | 0.9942 |
| **Raspberry** | 1 | 371 | 99.38 | 0.9939 |
| **Potato** | 3 | 2,152 | 99.26 | 0.9928 |
| **Cherry** | 2 | 1,906 | 99.12 | 0.9916 |
| **Strawberry** | 2 | 1,565 | 98.93 | 0.9896 |
| **Apple** | 4 | 3,171 | 98.85 | 0.9887 |
| **Grape** | 4 | 4,062 | 98.68 | 0.9871 |
| **Peach** | 2 | 2,657 | 98.53 | 0.9856 |
| **Tomato** | 10 | 18,160 | 98.24 | 0.9827 |
| **Corn (Maize)** | 4 | 3,852 | 98.11 | 0.9815 |
| **All** | **38** | **54,305** | **98.56** | **0.9810** |

*Most errors stay inside one crop and involve visually similar classes (e.g. corn cercospora leaf spot predicted as healthy corn, grape esca as healthy grape, tomato spider mites as tomato yellow leaf curl virus). A few errors cross crop boundaries; the crop head and consistency loss reduce these but do not remove them. No ablation without the crop head or the quality gates was run.*

### Limitations

- **Laboratory images only**: Accuracy on field photographs is unmeasured.
- **dHash deduplication**: The dHash check removes near-copies but not different-angle photographs of the same leaf, so the test score may be optimistic.
- **Single training run per model**: No repeated-run confidence intervals.
- **Hand-set thresholds**: Blur (100), leaf-coverage (18%) and severity thresholds are hand-set and not tuned on labelled field photographs.
- **Agronomic review needed**: Severity grades (G0–G3) have not been compared with plant-pathologist scores, and the advice table needs review by plant-protection specialists and a check against local pesticide registrations before use.

### Severity Grading (G0–G3)

| Stage | Diseased Area | Interpretation |
|-------|:------------:|----------------|
| **G0** | 0–2% | Healthy — no intervention needed |
| **G1** | 2–15% | Mild — organic protectants recommended |
| **G2** | 15–40% | Moderate — targeted chemical treatment |
| **G3** | 40–100% | Critical — emergency eradication required |

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Project Documentation](CROPVISION_PROJECT_DOCUMENTATION.md) | Full research paper with methodology, results, and analysis |
| [Model Documentation](MODEL_DOCUMENTATION.md) | Architecture, training, severity grading, and known limitations |
| [Evaluation Protocol](docs/models/evaluation_protocol.md) | Safety checks and field-test protocol for accuracy claims |
| [Model Cards](docs/models/model_cards.md) | Comprehensive model cards with calibration curves |
| [System Architecture](docs/architecture/system_architecture_spec.md) | RFC-0042: Edge-to-cloud topology specification |
| [API Specification](docs/api/) | OpenAPI 3.1 spec for CropVision cloud API |
| [Agronomy Field Guide](docs/agronomy/) | Clinical treatment protocols for 50+ plant conditions |
| [Contributing Guide](CONTRIBUTING.md) | How to contribute to CropVision |
| [Changelog](CHANGELOG.md) | Complete version history |

---

## 🧪 Model-Evaluation Safety Checks

Before presenting accuracy results, run the duplicate/source audit and follow
the field-test protocol:

```bash
cd model
python audit_dataset.py --train_dir ./dataset --test_dir ./official_test
```

See [docs/models/evaluation_protocol.md](docs/models/evaluation_protocol.md) for the complete protocol.

---

## 🧠 Model Training

### Download Dataset

```bash
pip install datasets
python -c "
from datasets import load_dataset
ds = load_dataset('mohanty/PlantVillage', 'color')
ds['train'].save_to_disk('./plantvillage_raw')
"
```

### Train MobileViT-Small

```bash
cd model
# Quick validation (2-3 epochs):
python train_mobilevit.py --data_dir ./dataset --epochs 3

# Full training run:
python train_mobilevit.py --data_dir ./dataset --epochs 50
```

---

## 🔌 Supported Crops & Diseases

<details>
<summary><b>14 Crops · 38 Classes</b> (click to expand)</summary>

| Crop | Disease Classes |
|------|-----------------|
| **Apple** (4) | Scab, Black Rot, Cedar Rust, Healthy |
| **Blueberry** (1) | Healthy |
| **Cherry** (2) | Powdery Mildew, Healthy |
| **Corn** (4) | Cercospora Leaf Spot, Common Rust, Northern Leaf Blight, Healthy |
| **Grape** (4) | Black Rot, Esca (Black Measles), Leaf Blight (Isariopsis), Healthy |
| **Orange** (1) | Huanglongbing (Citrus Greening) |
| **Peach** (2) | Bacterial Spot, Healthy |
| **Pepper Bell** (2) | Bacterial Spot, Healthy |
| **Potato** (3) | Early Blight, Late Blight, Healthy |
| **Raspberry** (1) | Healthy |
| **Soybean** (1) | Healthy |
| **Squash** (1) | Powdery Mildew |
| **Strawberry** (2) | Leaf Scorch, Healthy |
| **Tomato** (10) | Bacterial Spot, Early Blight, Late Blight, Leaf Mold, Septoria Leaf Spot, Spider Mites, Target Spot, Yellow Leaf Curl Virus, Mosaic Virus, Healthy |

</details>

---

## ⚠️ Known Placeholders

| File | Placeholder | Replace With |
|------|-------------|--------------|
| `mobile_app/lib/main.dart` | `YOUR_PROJECT` / `YOUR_ANON_KEY` | Real Supabase credentials |
| `mobile_app/lib/services/inference_service.dart` | Hardcoded 38 classes | Real TFLite model inference |
| `mobile_app/lib/screens/capture/capture_screen.dart` | Demo diagnosis | Real pipeline integration |
| `mobile_app/lib/screens/assistant_screen.dart` | Placeholder reply | Supabase Edge Function + LLM |
| `model/severity_estimation.py` | `SEVERITY_THRESHOLDS` | Tune against real photos per crop |

---

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before getting started.

```bash
# Fork → Clone → Branch → Code → Test → PR
git checkout -b feat/your-feature
# Make changes...
python -m pytest model/tests/ -v
git commit -m "feat(model): add your feature"
git push origin feat/your-feature
# Open a Pull Request!
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

- [PlantVillage Dataset](https://github.com/spMohanty/PlantVillage-Dataset) — Foundation image corpus
- [timm](https://github.com/huggingface/pytorch-image-models) — PyTorch Image Models library
- [Supabase](https://supabase.com) — Backend-as-a-Service platform
- [Flutter](https://flutter.dev) — Cross-platform mobile framework

---

<div align="center">

**CropVision** — Making crop disease detection accessible to every farmer 🌾

[⬆ Back to Top](#-cropvision)

</div>
