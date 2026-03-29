# Contributing to ThreadLenz

## Branch Naming Convention

Branch names determine the release version bump when merged to `master`:

| Prefix | Version Bump | Example |
|---|---|---|
| `feat_` | Major | v1.2.3 -> v2.0.0 |
| `ptch_` | Minor | v1.2.3 -> v1.3.0 |
| `fix_` | Patch | v1.2.3 -> v1.2.4 |
| `docs/`, `ci/`, etc. | No release | No version change |

## Development Workflow

1. Create a branch from `master` with the appropriate prefix
2. Make your changes
3. Ensure `flutter analyze` passes with **no issues**
4. Push and open a PR against `master`
5. CI will run a build check on the PR
6. On merge, a release is automatically created (if branch prefix matches)

## Code Style

- Follow standard Dart/Flutter conventions
- Use `debugPrint()` instead of `print()` in production code
- Use `withValues(alpha:)` instead of deprecated `withOpacity()`
- Run `flutter analyze` before pushing — zero issues required

## Project Setup

See [README.md](README.md) for setup instructions.
