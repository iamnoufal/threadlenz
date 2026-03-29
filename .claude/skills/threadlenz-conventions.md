---
name: threadlenz-conventions
description: Project conventions for ThreadLenz — a Flutter AI photography app. Use this skill whenever working on this codebase to follow the correct branch naming, coding standards, PR format, CI/CD workflow, and commit conventions. Trigger this for any code changes, branch creation, PR creation, commit, or workflow questions in the ThreadLenz repo.
---

# ThreadLenz Project Conventions

ThreadLenz is a Flutter cross-platform app (Android, iOS, Web) for AI-powered e-commerce product photography. It uses Firebase (Auth, Firestore, Storage, AI) with Gemini models for image generation.

## Branch Naming

Branch names determine what happens in CI/CD. The prefix controls versioning — choose carefully.

| Prefix | Version Bump | When to Use |
|--------|-------------|-------------|
| `feat_` | **Major** (X.0.0) | New features, infrastructure changes, major additions |
| `ptch_` | **Minor** (0.X.0) | Enhancements to existing features, non-breaking improvements |
| `fix_` | **Patch** (0.0.X) | Bug fixes, small corrections, cost optimizations |
| `docs/` | No build/release | Documentation-only changes (README, CHANGELOG, etc.) |
| `opt/` or any other | No build/release | Non-release work (experiments, config changes) |

Rules:
- Use **underscores** in branch names, not hyphens (e.g., `feat_auth_login`, not `feat-auth-login`)
- Exception: `docs/` and `opt/` prefixes use slash separator
- Branch name should be descriptive of the change (e.g., `fix_cost_optimization`, `feat_v2_infrastructure`)

**Example:** `feat_auth_db_storage_impl` → triggers major version bump (v1.x.x → v2.0.0) on merge

## Coding Standards (Flutter/Dart)

The project uses `flutter_lints` (^5.0.0) with strict analysis. All code must pass `flutter analyze` with **zero issues** before committing.

### Required patterns

- **Logging:** Use `debugPrint()`, never `print()`. The `avoid_print` rule is enforced.
- **Opacity:** Use `.withValues(alpha: 0.7)`, never `.withOpacity(0.7)`. The latter is deprecated.
- **Final fields:** Prefer `final` for fields that are never reassigned. The `prefer_final_fields` lint is active.
- **Unused parameters:** Use single `_` for all unused callback parameters, not `__` or `___`. The `unnecessary_underscores` lint is enforced.
  ```dart
  // Correct
  errorWidget: (_, _, _) => const Icon(Icons.broken_image),
  placeholder: (_, _) => const CircularProgressIndicator(),

  // Wrong
  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
  ```
- **Singleton services:** Services use singleton pattern (`static final _instance`, factory constructor)
- **Platform checks:** Use `kIsWeb` from `package:flutter/foundation.dart` for web vs mobile branching

### Project structure

```
lib/
├── main.dart                 # Entry point + AuthGate
├── firebase_options.dart     # Firebase config (uses dotenv)
├── models/                   # Data models (ProjectModel, UserModel)
├── screens/                  # Full-page screens
├── services/                 # Business logic (auth, firestore, storage, AI)
├── theme/                    # AppTheme with emerald/gold color palette
└── widgets/                  # Reusable widgets
```

### Dependencies & environment

- Firebase credentials loaded from `.env` via `flutter_dotenv` — never hardcode API keys
- `.env` is in `.gitignore`; `.env.template` shows required variables
- Secrets in CI are base64-encoded GitHub secrets decoded at build time

## Commit Messages

- Write clear, concise commit messages that describe what changed and why
- No co-author tags (no `Co-Authored-By` lines)
- Use imperative mood ("Add auth service" not "Added auth service")
- First line is a short summary; add a blank line and details if needed

**Example:**
```
Add Google Auth, Cloud Firestore, and Firebase Storage infrastructure

Replace anonymous auth with Google Sign-In, migrate local SharedPreferences
storage to Cloud Firestore for project metadata and Firebase Storage for
images.
```

## Pull Request Descriptions

The PR body becomes the GitHub Release notes (the workflow copies PR title + body directly into the release). Write PR descriptions as **user-facing release notes**.

### Include
- **What's New** — new features described from the user's perspective
- **Improvements** — enhancements, dependency upgrades, performance gains

### Do NOT include
- Test plans or checklists
- File lists or code changes
- Internal implementation details
- New file names or service names
- Co-author tags or "Generated with" attributions

**Example PR body:**
```markdown
## What's New

- **Google Sign-In** — Sign in with your Google account to sync projects across devices
- **Cloud Storage** — All project images are now stored in Firebase Storage
- **Auth Screen** — New branded login screen with feature highlights

## Improvements

- Upgraded all Firebase dependencies to latest versions
- Images load efficiently with caching
- Project deletion now cleans up cloud storage files automatically
```

## CI/CD Workflows

Two GitHub Actions workflows exist:

### PR Build Check (`pr-build-check.yml`)
- Triggers on: PR opened, synchronized, reopened
- Runs: `flutter analyze` → build APK → build iOS (no codesign)
- Must pass before merge

### Release (`release.yml`)
- Triggers on: PR merged into master with `feat_`, `ptch_`, or `fix_` branch prefix
- Auto-computes next version from branch prefix and latest git tag
- Builds release APK + iOS zip
- Creates git tag and GitHub Release with:
  - **Title:** `Release vX.Y.Z`
  - **Body:** PR title + PR body + full changelog link
  - **Assets:** `app-release.apk`, `ios-app.zip`

### Pre-merge checklist

Before pushing code that will trigger CI:
1. Run `flutter analyze` locally — must show **0 issues**
2. Run `flutter build apk --debug` to verify compilation
3. Ensure no `.env`, credentials, or secrets are committed

## Firebase Architecture

| Service | Purpose |
|---------|---------|
| Firebase Auth | Google Sign-In authentication |
| Cloud Firestore (Standard) | User profiles, project metadata |
| Firebase Storage | Input and generated images |
| Firebase AI | Gemini models for prompt & image generation |

### Firestore schema
```
users/{uid}/
  ├── displayName, email, photoUrl, tokenBalance, createdAt, lastLoginAt
  └── projects/{projectId}/
        ├── prompts[], timestamp, userId
        ├── inputImageUrls[], generatedImageUrls[]
        └── inputImagePaths[], generatedImagePaths[] (legacy local)
```

### Storage structure
```
users/{uid}/projects/{projectId}/
  ├── inputs/input_0.jpg, input_1.jpg, ...
  └── generated/gen_0.jpg, gen_1.jpg, ...
```

## AI Models in Use

| Model | Purpose | Why |
|-------|---------|-----|
| `gemini-2.5-flash-lite` | Prompt generation | ~6x cheaper output tokens than flash |
| `gemini-2.5-flash-image` | Image generation (img2img) | Cheapest model supporting reference image input |
