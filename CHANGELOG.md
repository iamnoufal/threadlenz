# Changelog

## v1.0.5 (2026-03-28)

### Features
- On-demand image generation (1 at a time, max 6 per project)
- Feedback textbox to guide subsequent image generations
- Multi-photo selection from gallery
- Project delete from history and detail screens
- Back to Home button on result screen

### Improvements
- Single prompt generation instead of 4 (faster, fewer tokens)
- Stronger diversity instructions for distinct variations
- Fixed duplicate project entries in history
- Fixed prompt visibility on home, history, and detail screens

### Fixes
- Resolved all `flutter analyze` warnings
- Replaced deprecated `withOpacity` with `withValues`
- Replaced `print` with `debugPrint`
- Removed unused settings icon

### CI/CD
- PR build checks (Android + iOS) on PR open
- Auto-release on merge based on branch prefix (`feat_`, `ptch_`, `fix_`)

## v1.0.0 (Initial Release)

- Product image upload (1-4 angles)
- AI prompt generation via Gemini 2.5 Flash
- Image generation via Gemini 2.5 Flash Image
- 4 parallel image generation with diversity instructions
- Project history with local storage
- Cross-platform support (Android, iOS, Web)
