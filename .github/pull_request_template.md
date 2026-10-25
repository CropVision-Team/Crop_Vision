## Description

<!-- Provide a brief description of the changes in this PR -->

## Type of Change

- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 Documentation update
- [ ] 🧪 Test addition/update
- [ ] 🔧 Refactoring (no functional changes)
- [ ] 🌾 New crop/disease support

## Component(s) Affected

- [ ] `model/` — ML pipeline
- [ ] `mobile_app/` — Flutter application
- [ ] `backend/` — Supabase schema/services
- [ ] `docs/` — Documentation
- [ ] `.github/` — CI/CD workflows

## Changes Made

<!-- List the specific changes made -->

1.
2.
3.

## Testing

### Tests Run

- [ ] `python -m pytest model/tests/ -v` — All tests pass
- [ ] `flutter analyze` — No issues found
- [ ] `flutter test` — All tests pass
- [ ] Manual testing performed

### Test Results

```
Paste test output here
```

## Cross-File Consistency (if modifying crop/disease data)

- [ ] `model/supported_crops.py` updated
- [ ] `model/treatment_recommendations.py` updated
- [ ] `backend/seed_crops.sql` regenerated
- [ ] `backend/seed_treatment_guidelines.sql` regenerated
- [ ] `mobile_app/lib/data/treatment_recommendations.dart` regenerated
- [ ] Cross-file name consistency test passes

## Screenshots (if applicable)

<!-- Add screenshots of UI changes or model output -->

## Checklist

- [ ] My code follows the project's coding standards
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] No sensitive data (API keys, credentials) in the diff
- [ ] Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)

## Related Issues

<!-- Link related issues using "Fixes #123" or "Relates to #456" -->

Fixes #
