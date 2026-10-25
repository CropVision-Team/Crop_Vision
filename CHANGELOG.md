# Changelog

All notable changes to the CropVision project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.4.0] — 2026-10-25

### Added
- `CONTRIBUTING.md` — comprehensive contribution guide with coding standards
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1
- `LICENSE` — MIT License
- `SECURITY.md` — vulnerability reporting policy
- `CHANGELOG.md` — version history from project inception
- GitHub Issue templates: Bug Report, Feature Request, New Crop Support
- Pull Request template with cross-file consistency checklist
- CI/CD workflows: ML pipeline tests, Flutter analysis, documentation checks
- `CROPVISION_PROJECT_DOCUMENTATION.md` — full research paper documentation
- Research figure generators and publication assets

### Changed
- Enhanced `README.md` with badges, shields, visual structure, and quick-start guide
- Updated `.gitignore` with comprehensive exclusion rules
- Improved `FUNDING.yml` placeholder configuration

---

## [1.3.0] — 2026-10-20

### Added

#### ML Pipeline & Model Architectures
- MobileViT-V2 and EfficientNet-Agri deep learning architectures (`model/architectures/`)
- ConvNeXt-Crop and EdgeViT-Lite model implementations
- Ensemble classifier with multi-model voting
- GradCAM and Integrated Gradients explainability modules
- PTQ INT8 quantization pipeline for on-device deployment
- ONNX and TFLite model export utilities
- Benchmark suite and calibration evaluator
- Model evaluation with confusion matrix generation
- Model comparison tools (`compare_models.py`)

#### Enterprise Backend Services
- Diagnosis Coordinator and Agronomic Advisory Engine
- Weather Epidemiology Service for outbreak prediction
- Mandi Market Intelligence with APMC price data
- IoT Soil Telemetry Pipeline for sensor integration
- Pest Vision Pipeline for entomological diagnosis
- Satellite Remote Sensing Service (NDVI analysis)
- Crop Phenology Engine for growth stage tracking
- Offline Delta Sync Service (CRDT-based)
- Farmer Notification Dispatcher
- Pesticide Compliance Auditor (FRAC validation)
- Community Agronomy Forum backend

#### Database Migrations
- Core Farmer Identity & Parcel Geometry schemas
- Plant Disease Diagnostic Telemetry tables
- Chemical Registry & Spray Compliance tracking
- Meteorological Stations & Microclimate Risk data
- APMC Mandi Register & Commodity Pricing
- Soil IoT Sensors & Time-Series Readings
- Satellite Remote Sensing & Vegetation Health
- Farmer Community Knowledge Hub
- PostgreSQL Row-Level Security Policies
- Timescale partitioning & high-throughput buffers

#### Mobile App (Offline-First Architecture)
- `OfflineDatabaseService` and `WeatherService`
- `MandiService` and `AudioGuidanceService`
- `LeafDetectorService` and `DiagnosisBloc`
- `WeatherBloc` and `MandiBloc` state management
- `DiagnosisGaugeWidget` and `TreatmentCardWidget` UI components

#### Localization
- Agricultural translations for 10 languages:
  English, Hindi (हिन्दी), Bengali (বাংলা), Telugu (తెలుగు),
  Tamil (தமிழ்), Marathi (मराठी), Gujarati (ગુજરાતી),
  Punjabi (ਪੰਜਾਬੀ), Spanish (Español), Swahili (Kiswahili)

#### Agronomic Knowledge Base
- Treatment datasets for 10 disease groups across all supported crops
- Registry of 500 APMC market yards with GPS coordinates
- Phenological fertilizer dosage matrix (10 crops × 5 soil types)
- Lifecycle and economic injury database for 100 crop pests
- Georeferenced registry of 800 agro-meteorological observatories
- FRAC resistance management handbook

#### Documentation
- OpenAPI 3.1 specification for CropVision v2.4 cloud API
- Field guide manual for 50 plant conditions
- RFC-0042: Edge-to-cloud topology and CRDT sync specification
- Comprehensive model cards with calibration curves
- Ethical AI evaluation benchmarks

#### Tests
- 14 automated test suites covering:
  - Model architectures deep validation
  - Quantization parity checks
  - Agricultural augmentation correctness
  - Calibration metrics verification
  - Diagnosis coordinator integration
  - Weather epidemiology pipeline
  - Treatment advisor logic
  - Offline delta sync protocols
  - Mandi intelligence aggregation
  - Soil telemetry pipeline
  - Auth flow verification
  - Crop calendar accuracy
  - Diagnosis bloc state management
  - Treatment calculator precision

### Fixed
- Repaired generated mobile service state handlers (`8e2d5eb`)

---

## [1.2.0] — 2026-10-19

### Added
- Email OTP verification flow and Supabase auth handlers
- Resilient multi-source dataset downloader with integrity checks
- MobileViT training upgrade: mixed precision and cosine decay scheduler
- Dedicated CropVision training, evaluation, and checkpoint comparison tools

### Changed
- Refined leaf capture workflow and camera preview aspect ratio
- Updated `.gitignore` for dataset downloads and image dumps

---

## [1.1.0] — 2026-10-09

### Added
- Crop growth calendar module for seasonal tracking
- Augmentation preview generator for training visualization

### Changed
- Improved diagnosis result handling in mobile app
- Enhanced training pipeline with better augmentation strategies
- Updated training guidance documentation

---

## [1.0.0] — 2026-10-03

### Added

#### Core ML Pipeline (`model/`)
- PlantVillage dataset fetching and organization modules
- Supported crops dictionary with 14 crops and 38 disease classes
- MobileViT-Small architecture and training pipeline
- Leaf verification & non-leaf image filter module
- Disease severity estimation (HSV-based G0–G3 grading)
- Treatment recommendation rules engine
- Crop growth stage tracking calendar
- Unified inference pipeline (`pipeline.py`)
- REST API inference server (`inference_server.py`)
- Dataset audit tool for leakage detection
- pytest test suite (53 tests)
- `requirements.txt` for reproducible environments

#### Flutter Mobile App (`mobile_app/`)
- Flutter app project initialization
- Core data models and crop growth constants
- App theme and reusable UI components
- Supabase service client and auth screens
- Inference and severity estimation services
- All application UI screens (capture, home, history, calendar, assistant)
- Multi-platform native runners (Android, iOS, Web, Desktop)
- Dart ports of Python image verification and severity estimation

#### Supabase Backend (`backend/`)
- Relational schema for profiles, diagnoses, reminders, chat messages
- Seed data for 5 supported crop varieties
- Treatment guidelines dataset (65 disease/severity entries)
- Leaf storage bucket policies
- AI assistant edge function endpoint
- Row-Level Security policies on all 6 tables
- Performance indexes on query-pattern columns

#### Documentation
- Comprehensive project README with setup instructions
- ML model architecture documentation (`MODEL_DOCUMENTATION.md`)

### Fixed
- Image verification: brightness checked before blur to prevent dark images from being misreported as blurry
- Severity estimation: leaf mask now includes diseased tissue (brown/necrotic pixels) in the denominator
- Training script: separate dataset objects per split to prevent shared transform overwrite
- Cross-file name consistency: `Corn___Cercospora_leaf_spot` matched across all source files
- RLS enabled on `crops` and `treatment_guidelines` tables (were missing)
- `crops` table seeded (was empty despite foreign key references)
- Storage delete policy added (previously orphaned files on diagnosis removal)

---

## [0.1.0] — 2026-10-03

### Added
- Initial project structure and workspace configuration
- `.gitignore` rules for Python, Flutter, and ML artifacts
- `.env.example` with Supabase and API key placeholders
- App logo integration on login and dashboard screens

[1.4.0]: https://github.com/CropVision-Team/Crop_Vision/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/CropVision-Team/Crop_Vision/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/CropVision-Team/Crop_Vision/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/CropVision-Team/Crop_Vision/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/CropVision-Team/Crop_Vision/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/CropVision-Team/Crop_Vision/releases/tag/v0.1.0
