# my-app

> **Fork this template** to ship a Python desktop app to every platform automatically.

A GitHub template that packages and releases a Python application as:

| Platform | Artifacts |
|----------|-----------|
| Windows  | `.exe` |
| macOS    | `.app.zip`, `.dmg` |
| Linux    | `.AppImage`, `.deb`, `.rpm` |

Releases are fully automated via [Conventional Commits](https://www.conventionalcommits.org/) + [Release Please](https://github.com/googleapis/release-please-action).

---

## How it works

```
push to main  →  CI (lint + test)  →  Release Please PR
merge PR      →  GitHub Release created  →  Build workflow runs
                                          →  Artifacts attached to release
```

---

## Getting started

### 1. Fork and rename

Fork this repository, then update these files:

| File | What to change |
|------|---------------|
| `pyproject.toml` | `name`, `description` |
| `nfpm.yaml` | `maintainer`, `homepage` |
| `packaging/template.desktop` | `Name`, `Categories` |
| `app/main.py` | Replace with your application |
| `requirements.txt` | Your runtime dependencies |

### 2. Replace the app

All application code lives in `app/main.py`. The entry point must be `app/main.py` (matched in the PyInstaller build command in the workflow). Replace the example PySide6 app with your own.

### 3. Add icons (optional)

Place icons in `assets/`:

| File | Used by |
|------|---------|
| `assets/icon.ico` | Windows `.exe` |
| `assets/icon.icns` | macOS `.app` |
| `assets/icon.png` | Linux AppImage |

If omitted, the binary is built without an icon.

### 4. Enable release-please

Release Please needs write access to open PRs and create releases.

In your repository: **Settings → Actions → General → Workflow permissions** → set to **Read and write permissions**.

### 5. Ship a release

Commit using [Conventional Commit](https://www.conventionalcommits.org/) messages:

```bash
git commit -m "feat: add dark mode"
git commit -m "fix: crash on startup"
git push origin main
```

After CI passes, Release Please opens a release PR. Merging it:
1. Bumps the version in `pyproject.toml`
2. Creates a GitHub Release
3. Triggers the build workflow
4. Attaches `.exe`, `.dmg`, `.app.zip`, `.AppImage`, `.deb`, `.rpm` to the release

---

## Local development

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python app/main.py          # run the app
pytest                      # run tests
```

---

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | every push / PR | lint (ruff) + tests (pytest) |
| `release-please.yml` | CI passes on main | manage release PRs and build artifacts |
| `codeql.yml` | push / PR / weekly | security analysis |

---

## Project structure

```
├── app/
│   └── main.py                  # your application — edit this
├── assets/                      # icons (optional)
├── packaging/
│   └── template.desktop         # Linux desktop entry template
├── tests/
│   └── test_smoke.py
├── nfpm.yaml                    # Linux package config (.deb / .rpm)
├── requirements.txt             # runtime dependencies
└── pyproject.toml
```
