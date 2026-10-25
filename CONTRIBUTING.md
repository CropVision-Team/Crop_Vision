# Contributing to CropVision

Thank you for your interest in contributing to **CropVision** — an edge-native crop disease detection framework! Whether you're fixing a bug, improving documentation, adding crop coverage, or building new features, this guide will help you get started.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Branching Strategy](#branching-strategy)
- [Commit Conventions](#commit-conventions)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Adding New Crop/Disease Support](#adding-new-cropdisease-support)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold a respectful and inclusive environment.

---

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/<your-username>/CropVision.git
   cd CropVision
   ```
3. **Add the upstream** remote:
   ```bash
   git remote add upstream https://github.com/CropVision-Team/CropVision.git
   ```
4. Create a **feature branch** from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   ```

---

## Development Setup

### Python / ML Pipeline

```bash
cd model
python -m venv venv
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### Flutter Mobile App

```bash
cd mobile_app
flutter pub get
flutter analyze    # Check for issues before committing
flutter test       # Run unit tests
```

### Supabase Backend

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run SQL files in order:
   - `backend/supabase_schema.sql`
   - `backend/seed_crops.sql`
   - `backend/seed_treatment_guidelines.sql`
3. Copy `.env.example` → `.env` and fill in your credentials

---

## Project Structure

```
CropVision/
├── model/              # Python + PyTorch ML pipeline
│   ├── architectures/  # Model architecture definitions
│   ├── tests/          # pytest test suite
│   └── requirements.txt
├── mobile_app/         # Flutter cross-platform application
│   ├── lib/
│   │   ├── blocs/      # Business logic components
│   │   ├── screens/    # UI screens
│   │   ├── services/   # Backend & inference services
│   │   └── models/     # Data models
│   └── pubspec.yaml
├── backend/            # Supabase schema, seeds & edge functions
│   ├── services/       # Enterprise backend services
│   ├── database/       # Migration schemas
│   └── tests/          # Backend test suites
├── docs/               # Documentation & research figures
└── .github/            # CI workflows, templates, funding
```

---

## Branching Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code. Protected — requires PR reviews |
| `feat/<name>` | New features (e.g., `feat/rice-disease-support`) |
| `fix/<name>` | Bug fixes (e.g., `fix/severity-threshold-potato`) |
| `docs/<name>` | Documentation changes |
| `test/<name>` | Test additions or improvements |
| `refactor/<name>` | Code refactoring without behavior changes |

---

## Commit Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/). Each commit message must follow this format:

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation changes only |
| `test` | Adding or updating tests |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `chore` | Build process, tooling, or dependency updates |
| `ci` | CI/CD pipeline changes |

### Scopes

| Scope | Area |
|-------|------|
| `model` | ML pipeline, training, inference |
| `mobile` | Flutter application |
| `backend` | Supabase schema, services, edge functions |
| `agronomy` | Treatment recommendations, crop data |
| `docs` | Documentation and research figures |

### Examples

```
feat(model): add EfficientNet-V2 architecture for crop classification
fix(mobile): resolve camera permission crash on Android 14
docs(agronomy): update Tomato Late Blight treatment for G3 severity
test(model): add cross-validation tests for severity estimation
```

---

## Pull Request Process

1. **Sync** with upstream before pushing:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```
2. **Push** your branch and open a PR against `main`
3. Fill out the **PR template** completely
4. Ensure all **CI checks pass** (lint, tests, build)
5. Request review from at least **one maintainer**
6. Address all review comments
7. Squash-merge after approval

### PR Checklist

- [ ] Code follows the project's coding standards
- [ ] Tests added/updated for the changes
- [ ] Documentation updated if needed
- [ ] All existing tests still pass
- [ ] Commit messages follow conventional commits
- [ ] No sensitive data (API keys, credentials) in the diff

---

## Coding Standards

### Python (ML Pipeline)

- **Formatter**: Use `black` with default settings
- **Linter**: Use `flake8` with max line length 100
- **Type hints**: Required for all public functions
- **Docstrings**: Google-style docstrings for all modules, classes, and functions
- **Imports**: Group as stdlib → third-party → local, separated by blank lines

### Dart (Flutter App)

- **Formatter**: Use `dart format`
- **Linter**: Follow `analysis_options.yaml` rules
- **Naming**: Use `lowerCamelCase` for variables/functions, `UpperCamelCase` for classes
- **Null safety**: All new code must be null-safe

### SQL (Backend)

- **Keywords**: UPPERCASE (`CREATE TABLE`, `SELECT`, etc.)
- **Naming**: `snake_case` for tables and columns
- **RLS**: All new tables MUST have Row-Level Security enabled

---

## Testing Requirements

### ML Pipeline Tests

```bash
cd model
python -m pytest tests/ -v
```

All PRs affecting `model/` must:
- Maintain ≥90% pass rate on existing tests
- Add tests for any new functionality
- Include cross-file consistency checks for crop/disease names

### Flutter Tests

```bash
cd mobile_app
flutter test
```

### Backend Tests

```bash
cd backend
python -m pytest tests/ -v
```

---

## Adding New Crop/Disease Support

To add support for a new crop or disease class:

1. **Update `model/supported_crops.py`** — Add the crop and its disease classes
2. **Update `model/treatment_recommendations.py`** — Add G1/G2/G3 treatment entries
3. **Regenerate seed files**:
   - `backend/seed_crops.sql`
   - `backend/seed_treatment_guidelines.sql`
4. **Regenerate Dart data** — `mobile_app/lib/data/treatment_recommendations.dart`
5. **Add test images** — At least 5 representative images per new class
6. **Run cross-file consistency tests** to verify name alignment
7. **Document** the addition in the PR description

---

## Reporting Bugs

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- Steps to reproduce
- Expected vs. actual behavior
- Environment details (OS, Python version, Flutter version)
- Screenshots or error logs if applicable
- Crop/disease class involved (if relevant)

---

## Suggesting Features

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md) and describe:

- The problem your feature would solve
- Your proposed solution
- Which crops or agricultural contexts it applies to
- Any alternatives you've considered

---

## Recognition

All contributors are recognized in [CHANGELOG.md](CHANGELOG.md). We value every contribution, no matter how small!

---

## Questions?

If you have questions about contributing, open a [Discussion](https://github.com/CropVision-Team/CropVision/discussions) or reach out to the maintainers.

Thank you for helping make agriculture smarter and more accessible! 🌾
