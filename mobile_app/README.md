# CropVision Mobile Application

[![Flutter CI](https://github.com/CropVision-Team/Crop_Vision/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/CropVision-Team/Crop_Vision/actions/workflows/flutter-ci.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../LICENSE)

The **CropVision Mobile App** is a cross-platform client (Android, iOS, Web, Desktop) built with Flutter and Dart. It provides offline-first agronomic advisory, deep learning leaf disease diagnosis, G0–G3 damage severity estimation, interactive crop growth calendars, local APMC mandi market rate intelligence, and multi-lingual voice guidance in 10 languages.

---

## Architecture Overview

- **State Management**: BLoC Pattern (`DiagnosisBloc`, `MandiBloc`, `WeatherBloc`) + `Provider` for theme and persistent settings.
- **Offline Storage**: Local SQLite cache via `sqflite` with delta-synchronization when connectivity is restored.
- **Computer Vision Pipeline**:
  - Pre-capture leaf detection and non-leaf image rejection filter.
  - Severity estimation using green vegetative area index segmentation (G0 Healthy, G1 Mild, G2 Moderate, G3 Severe).
  - Multi-endpoint fallback REST client for model inference (`model/inference_server.py`).
- **Backend & Auth**: Supabase Auth (Email OTP / OAuth), PostgreSQL Row-Level Security (RLS), and Edge Functions.
- **Localization (i18n)**: 10 regional and international agricultural languages (`en`, `hi`, `bn`, `te`, `ta`, `mr`, `gu`, `pa`, `es`, `sw`).

---

## Prerequisites

- **Flutter SDK**: `>= 3.19.0` (Dart `>= 3.3.0`)
- **Android**: Android Studio with Android SDK API 24+ (Nougat or later)
- **iOS**: macOS with Xcode 15+ and CocoaPods
- **Python ML Server (Optional for local live inference)**: Python 3.10+ running `model/inference_server.py`

Verify your Flutter environment:
```bash
flutter doctor
```

---

## Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/CropVision-Team/Crop_Vision.git
   cd Crop_Vision/mobile_app
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**:
   By default, `mobile_app/lib/main.dart` contains fallback sandbox endpoints. For custom Supabase configurations, provide environment definitions at runtime:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
               --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_PUBLIC_KEY
   ```
   Or create a `.env` file in the project root following [`.env.example`](../.env.example).

---

## Running the Application

### Connect to Local ML Inference Server
Before launching the mobile app for live diagnosis, start the inference server in the `model/` directory:
```bash
# Terminal 1: Start Python inference server
cd ../model
python inference_server.py --port 8000
```

If testing on a physical Android device connected via USB, reverse the port so the phone can reach your computer's localhost:
```bash
adb reverse tcp:8000 tcp:8000
```

### Launch Flutter Client
```bash
# Debug mode on connected device
flutter run

# Specifically targeting Chrome (Web)
flutter run -d chrome

# Specifically targeting Android device
flutter run -d android
```

---

## Code Quality & Automated Tests

Run static analysis to guarantee zero linter warnings:
```bash
flutter analyze
```

Execute all automated unit, BLoC, and widget tests:
```bash
flutter test
```

Format code according to official Dart style conventions:
```bash
dart format lib test
```

---

## Production Build

### Android Release APK / App Bundle
```bash
# Build standalone APK
flutter build apk --release

# Build Google Play App Bundle
flutter build appbundle --release
```
The output APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

### iOS Release Build
```bash
flutter build ipa --release
```

### Web Release
```bash
flutter build web --release
```
