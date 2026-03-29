# ThreadLenz

AI-powered e-commerce product photography app built with Flutter + Firebase.

## Quick Reference

- **Run analysis:** `flutter analyze` (must pass with 0 issues before any commit)
- **Build debug:** `flutter build apk --debug`
- **Install deps:** `flutter pub get`

## Key Conventions

See `.claude/skills/threadlenz-conventions.md` for the full guide covering:
- Branch naming (`feat_`, `ptch_`, `fix_`, `docs/`, `opt/`)
- Dart coding standards (debugPrint, withValues, final fields, single `_`)
- PR descriptions (user-facing release notes only, no code internals)
- CI/CD workflow (auto-versioning on merge based on branch prefix)
- Commit messages (imperative mood, no co-author tags)
- Firebase architecture (Auth, Firestore, Storage, AI)
