# dashboardpython

A GitHub template for shipping cross-platform Python desktop apps with PySide6, PyInstaller, and release-please.

## Features

- **PySide6 GUI** with build metadata baked into the title bar
- **PyInstaller** one-file builds for Windows, macOS, and Linux
- **release-please** for automated versioning, changelogs, and GitHub Releases
- **CI pipeline** with ruff linting/formatting and pytest
- **Dependabot** for pip and GitHub Actions dependency updates
- **Auto-update check** against the latest GitHub Release

## Quick Start

1. Click **"Use this template"** on GitHub to create your own repo
2. Clone your new repo locally
3. Customize the app (see checklist below)
4. Push — CI runs automatically, and releases are created via conventional commits

## Project Structure

```
app/
  main.py            # Application entry point and GUI
tests/
  test_smoke.py      # Smoke tests (import, metadata, env vars)
assets/              # Place icon.ico / icon.icns here for branded builds
.github/
  workflows/
    ci.yml           # Lint, format check, and tests on every push/PR
    release-please.yml  # Versioning, changelog, and cross-platform builds
  dependabot.yml     # Automated dependency updates
pyproject.toml       # Project metadata, ruff and pytest config
requirements.txt     # Runtime dependencies (used by CI)
```

## Customization Checklist

- [ ] Rename the project in `pyproject.toml` (`name`, `description`)
- [ ] Update `requirements.txt` with your dependencies
- [ ] Replace `app/main.py` with your application logic
- [ ] Add your icon to `assets/` (`icon.ico` for Windows, `icon.icns` for macOS)
- [ ] Update this README

## CI/CD Pipeline

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| **CI** | Push & PRs | Ruff lint, ruff format check, pytest |
| **Release** | Push to `main` | release-please opens/updates a release PR; on merge, builds all 3 platforms and attaches artifacts to the GitHub Release |

### How Releases Work

1. Write commits using [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, etc.)
2. release-please automatically opens a PR that bumps the version in `pyproject.toml` and updates `CHANGELOG.md`
3. Merge that PR to create a GitHub Release with built executables for all platforms

### Keeping in Sync

If release-please pushes a version-bump commit while you have local changes:

```bash
git pull --rebase    # always rebase before pushing
git push
```

Or work on **feature branches** and create PRs — this avoids sync issues entirely.

## Local Development

```bash
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install pytest ruff

python app/main.py              # Run the app
pytest                          # Run tests
ruff check .                    # Lint
ruff format --check .           # Format check
```
