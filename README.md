# PACKAGE_NAME

> **Repository template** — replace every `PACKAGE_NAME`, `ORGANIZATION`,
> `PYPI_PROJECT_NAME`, `COMPANY_NAME`, and `SIGNING_IDENTITY` before use.

A production-ready Python project template that builds, tests, bundles,
signs (scaffolded), and releases professional artifacts for **Windows**,
**macOS** (Intel + Apple Silicon), and **Linux** — using SSH-only Git
operations and no long-lived tokens.

---

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Repository Structure](#2-repository-structure)
3. [SSH-Only Setup](#3-ssh-only-setup)
4. [How to Use This Template](#4-how-to-use-this-template)
5. [Local Development](#5-local-development)
6. [How to Release](#6-how-to-release)
7. [Artifact Inventory](#7-artifact-inventory)
8. [Tooling Trade-offs](#8-tooling-trade-offs)
9. [macOS Signing & Notarization](#9-macos-signing--notarization)
10. [Windows SmartScreen](#10-windows-smartscreen)
11. [Linux Distribution Strategy](#11-linux-distribution-strategy)
12. [SSH Workflow Security](#12-ssh-workflow-security)
13. [Enabling PyPI Publishing](#13-enabling-pypi-publishing)
14. [Artifact Verification](#14-artifact-verification)

---

## 1. Quick Start

```bash
git clone git@github.com:ORGANIZATION/PACKAGE_NAME.git
cd PACKAGE_NAME
python -m pip install -e ".[dev]"
pytest
make help
```

---

## 2. Repository Structure

```
.
├── .editorconfig
├── .github/
│   ├── dependabot.yml              # keeps action SHA pins + pip deps current
│   └── workflows/
│       ├── ci.yml                  # lint + test matrix (every push/PR)
│       └── release.yml             # full build + sign + release (v* tags)
├── .gitignore
├── LICENSE
├── Makefile                        # developer convenience targets
├── noxfile.py                      # nox automation sessions
├── packaging/
│   ├── PACKAGE_NAME.desktop        # Linux desktop entry
│   ├── PACKAGE_NAME.spec           # PyInstaller spec (all platforms)
│   ├── nfpm.yaml                   # nfpm config → .deb + .rpm
│   ├── macos/
│   │   └── entitlements.plist      # macOS hardened-runtime entitlements
│   └── wix/
│       └── Product.wxs             # WiX 4 MSI scaffold
├── pyproject.toml                  # project metadata, build, tools config
├── README.md
├── scripts/
│   ├── build_appimage.sh           # AppImage (Linux)
│   ├── build_deb.sh                # .deb via nfpm
│   ├── build_dmg.sh                # DMG (macOS)
│   ├── build_nuitka.ps1            # Nuitka (Windows)
│   ├── build_nuitka.sh             # Nuitka (Linux/macOS)
│   ├── build_pyinstaller.ps1       # PyInstaller (Windows)
│   ├── build_pyinstaller.sh        # PyInstaller (Linux/macOS)
│   └── build_rpm.sh                # .rpm via nfpm
├── src/
│   └── PACKAGE_NAME/
│       ├── __init__.py
│       ├── __main__.py             # CLI entry point
│       └── py.typed                # PEP 561 marker
└── tests/
    ├── __init__.py
    ├── conftest.py
    └── test_package.py
```

---

## 3. SSH-Only Setup

This repository enforces SSH for all Git operations.
**HTTPS remotes and PATs are not used anywhere.**

### 3a. Generate an SSH key

```bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519_github
```

### 3b. Add the key to ssh-agent

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github
```

Persist across reboots — add to `~/.ssh/config`:

```
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    AddKeysToAgent yes
```

### 3c. Add your public key to GitHub

```bash
cat ~/.ssh/id_ed25519_github.pub
# GitHub → Settings → SSH and GPG keys → New SSH key
```

### 3d. Test the connection

```bash
ssh -T git@github.com
# Expected: "Hi USERNAME! You've successfully authenticated..."
```

### 3e. Create a repository Deploy Key (for GitHub Actions)

A Deploy Key allows Actions to check out the repository over SSH without
a personal access token.

```bash
# Generate a dedicated CI key (separate from your personal key)
ssh-keygen -t ed25519 -C "ci-deploy-key" -f ~/.ssh/deploy_key -N ""

# Add PUBLIC key as Deploy Key in GitHub:
# Repository → Settings → Deploy keys → Add deploy key
# Title: "GitHub Actions deploy key"
# Key:   cat ~/.ssh/deploy_key.pub
# Allow write access: NO (read-only is sufficient)

# Add PRIVATE key as a repository secret:
# Repository → Settings → Secrets and variables → Actions → New secret
# Name:  DEPLOY_KEY
# Value: cat ~/.ssh/deploy_key   (the private key)
```

### 3f. Why SSH instead of HTTPS?

| Concern | HTTPS + PAT | SSH deploy key |
|---------|-------------|----------------|
| Token scope | PAT can access all repos | Deploy key is single-repo |
| Token lifetime | Long-lived, manual rotation | Instant revocation |
| Secret exposure | PAT in env = broad blast radius | Private key scoped to one op |
| Audit trail | Actions attributed to user | Isolated to this repo |

---

## 4. How to Use This Template

### Step 1 — Clone and rename

```bash
git clone git@github.com:ORGANIZATION/PACKAGE_NAME.git my-new-project
cd my-new-project
```

### Step 2 — Replace all TODO markers globally

| Marker | Replace with |
|--------|-------------|
| `PACKAGE_NAME` | Python package name (e.g. `myapp`) — must be a valid identifier |
| `ORGANIZATION` | GitHub org or username |
| `PYPI_PROJECT_NAME` | PyPI project name (may use hyphens) |
| `COMPANY_NAME` | Company / author name |
| `SIGNING_IDENTITY` | macOS Developer ID string |

```bash
OLD=PACKAGE_NAME; NEW=myapp

# Replace in all text files
find . -type f \( -name "*.py" -o -name "*.toml" -o -name "*.yml" \
                -o -name "*.yaml" -o -name "*.sh" -o -name "*.ps1" \
                -o -name "*.md" -o -name "*.wxs" -o -name "*.plist" \
                -o -name "*.desktop" -o -name "Makefile" \) \
       ! -path "./.git/*" \
       -exec sed -i "s/${OLD}/${NEW}/g" {} +

# Rename directories and files
mv src/${OLD}   src/${NEW}
mv packaging/${OLD}.spec    packaging/${NEW}.spec
mv packaging/${OLD}.desktop packaging/${NEW}.desktop
```

### Step 3 — Set repository secrets

Settings → Secrets and variables → Actions → New repository secret:

- `DEPLOY_KEY` (**mandatory**) — SSH deploy key private key
- macOS signing secrets (optional — see §9)
- Windows signing secrets (optional — see §10)

### Step 4 — Configure PyPI Trusted Publisher (optional — see §13)

### Step 5 — Push and verify CI

```bash
git add -A
git commit -m "chore: initialise from template"
git push origin main
```

---

## 5. Local Development

```bash
make install        # pip install -e ".[dev]"
make lint           # ruff check
make fmt            # ruff format + ruff check --fix
make typecheck      # mypy
make test           # pytest
make test-cov       # pytest + coverage report
make build-sdist    # python -m build --sdist
make build-wheel    # python -m build --wheel

# Binary builds (current platform)
make build-pyinstaller          # PyInstaller onefile
make build-pyinstaller-onedir   # PyInstaller onedir → tar.gz
make build-nuitka               # Nuitka standalone
make build-appimage             # AppImage (Linux only)
make build-deb                  # .deb (Linux only)
make build-rpm                  # .rpm (Linux only)
make build-dmg                  # DMG (macOS only)
```

With nox (manages separate virtualenvs per Python version):

```bash
nox                  # lint + tests on all Python versions
nox -s tests-3.12
nox -s lint
nox -s coverage
nox -s build
```

---

## 6. How to Release

```bash
# Ensure main is clean and tests pass
git checkout main && git pull origin main
pytest

# Tag a release (semver)
git tag v1.2.3
git push origin v1.2.3   # SSH — not HTTPS
```

The `release.yml` workflow triggers automatically and:

1. Runs the full test matrix (blocks if any fail)
2. Builds wheels for CPython 3.10–3.13 via cibuildwheel:
   - Linux: x86_64 + aarch64 (manylinux_2_28)
   - macOS: universal2
   - Windows: AMD64
3. Builds PyInstaller + Nuitka standalone binaries
4. Packages AppImage, .deb, .rpm, tar.gz (Linux)
5. Packages .app.zip, DMG (macOS)
6. Packages onefile .exe, portable .zip, MSI scaffold (Windows)
7. Generates SLSA provenance + SBOM attestations (Sigstore keyless)
8. Creates a GitHub Release with all 15+ artifacts
9. Publishes wheels to PyPI via OIDC

**Pre-release** tags (`v1.2.3-beta.1`, `v2.0.0-rc.1`) automatically
create GitHub pre-releases.

### Artifact naming convention

```
PACKAGE_NAME-VERSION-OS-ARCH[-FORMAT][.ext]

myapp-1.2.0-linux-x86_64-onefile
myapp-1.2.0-linux-x86_64.AppImage
myapp-1.2.0-linux-x86_64.deb
myapp-1.2.0-linux-x86_64.rpm
myapp-1.2.0-linux-x86_64.tar.gz
myapp-1.2.0-linux-x86_64-nuitka
myapp-1.2.0-macos-universal2.app.zip
myapp-1.2.0-macos-universal2.dmg
myapp-1.2.0-macos-arm64-nuitka
myapp-1.2.0-windows-x86_64-onefile.exe
myapp-1.2.0-windows-x86_64-portable.zip
myapp-1.2.0-windows-x86_64-nuitka.exe
myapp-1.2.0-windows-x86_64.msi
```

---

## 7. Artifact Inventory

| Format | Platform | Tool | Notes |
|--------|----------|------|-------|
| `.whl` | All | cibuildwheel | CPython 3.10–3.13 |
| `.tar.gz` sdist | All | build | Source distribution |
| onefile binary | Linux, macOS | PyInstaller | Single executable |
| onedir `.tar.gz` | Linux | PyInstaller | Directory bundle |
| `.AppImage` | Linux | linuxdeploy | Universal, no install |
| `.deb` | Debian/Ubuntu | nfpm | `apt install` |
| `.rpm` | RHEL/Fedora | nfpm | `dnf install` |
| `.app.zip` | macOS | PyInstaller | Zipped bundle |
| `.dmg` | macOS | create-dmg | Drag-to-Applications |
| onefile `.exe` | Windows | PyInstaller | Single executable |
| portable `.zip` | Windows | PyInstaller | Onedir zip |
| `.msi` | Windows | WiX 4 | System installer |
| Nuitka binary | All | Nuitka | Optimized standalone |

---

## 8. Tooling Trade-offs

### Wheels vs Standalone Binaries

**Wheels** (`pip install PACKAGE_NAME`):
- Require Python on the target machine
- Smaller download, integrates with pip / virtual envs
- Best for: libraries, developer CLI tools, CI pipelines

**Standalone binaries** (PyInstaller / Nuitka):
- Bundle the interpreter — zero Python requirement
- Larger file (30–100 MB typical)
- Best for: end-user GUI/CLI apps, enterprise distribution, non-Python users

### PyInstaller vs Nuitka

| Aspect | PyInstaller 6.x | Nuitka |
|--------|-----------------|--------|
| Build time | Fast (2–5 min) | Slow (10–40 min) |
| Output size | Larger | Smaller |
| Runtime speed | Unchanged | Faster (C-compiled) |
| Startup time | Slower (extraction in onefile) | Faster |
| Compatibility | Very broad | Broad (rare edge cases) |
| Debugging | Easier | Harder |
| Best use | CI/dev, rapid releases | Final production artifact |

**Recommendation**: run PyInstaller for smoke tests in every CI push; use
Nuitka only for the release artifact.

**macOS note**: onefile mode is not recommended for signed/notarized macOS
apps (requires sandbox-incompatible temp directory writes). Use onedir
(`.app` bundle) for production macOS distribution.

### AppImage vs .deb vs .rpm vs tar.gz (Linux)

| Format | Pros | Cons | Target |
|--------|------|------|--------|
| AppImage | No install, any distro, portable | No pkg manager, no auto-update | Universal desktop |
| .deb | `apt`, auto-update, PATH | Debian/Ubuntu only | Ubuntu-primary apps |
| .rpm | `dnf`, auto-update, PATH | RHEL/Fedora only | Enterprise Linux |
| tar.gz | Universal, works headless | No integration, no update | Servers, scripts |

**Recommendation**: release AppImage + .deb + .rpm for desktop apps.
Release tar.gz for server/headless tools.

---

## 9. macOS Signing & Notarization

**Required for distribution without Gatekeeper warnings** on macOS 10.15+.

### Prerequisites

- Apple Developer account ($99/year)
- Developer ID Application certificate (from Xcode / Keychain Access)
- App-specific password (appleid.apple.com → Security → App-Specific Passwords)

### Enable in the workflow

Uncomment the signing and notarization steps in `release.yml`, then set:

```
MACOS_CERTIFICATE           base64 -w0 MyCert.p12
MACOS_CERTIFICATE_PWD       password used when exporting the .p12
MACOS_KEYCHAIN_PASSWORD     any random string for the temp keychain
APPLE_ID                    developer@example.com
APPLE_TEAM_ID               ABCDE12345
APPLE_APP_SPECIFIC_PASSWORD xxxx-xxxx-xxxx-xxxx
```

### Manual test (local)

```bash
# Sign
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: COMPANY_NAME (TEAMID)" \
    --entitlements packaging/macos/entitlements.plist \
    --options runtime \
    dist/PACKAGE_NAME.app

# Notarize
ditto -c -k --keepParent dist/PACKAGE_NAME.app dist/submit.zip
xcrun notarytool submit dist/submit.zip \
    --apple-id "dev@example.com" --team-id "TEAMID" \
    --password "xxxx-xxxx-xxxx-xxxx" --wait

# Staple
xcrun stapler staple dist/PACKAGE_NAME.app
```

### Entitlements

Edit `packaging/macos/entitlements.plist`. Only enable what your app
actually needs — unnecessary entitlements delay notarization review.
The hardened runtime (`com.apple.security.cs.hardened-runtime`) is
**always required** for notarization.

---

## 10. Windows SmartScreen

Unsigned executables downloaded from the internet trigger:
> *"Windows protected your PC — Windows Defender SmartScreen prevented
> an unrecognised app from starting."*

**Eliminating SmartScreen warnings**:
1. Obtain an **EV (Extended Validation) code signing certificate**
   (~$300–500/year from DigiCert, Sectigo, or GlobalSign)
2. Uncomment the signing block in `release.yml`
3. Set `WINDOWS_CERTIFICATE` (base64 PFX) and `WINDOWS_CERT_PASSWORD`

EV certificates immediately establish reputation with SmartScreen.
Standard OV certificates require a "warm-up" period (~thousands of downloads).

**Timestamp always** (prevents breakage after cert expiry):
```
signtool sign /tr http://timestamp.digicert.com /td sha256 ...
```

---

## 11. Linux Distribution Strategy

### Desktop apps

1. **AppImage** — widest compatibility, zero install friction
2. **.deb** — native Ubuntu/Debian experience
3. **.rpm** — native Fedora/RHEL experience
4. **Flatpak** (not in template) — sandboxed, Flathub listing

### CLI / server tools

1. **tar.gz** — extract anywhere, no root, no package manager
2. **.deb** / **.rpm** — `/usr/bin` PATH integration, system uninstall

### glibc compatibility baseline

This template targets **manylinux_2_28** (glibc 2.28):
- Ubuntu 20.04 LTS+
- Debian 10 (Buster)+
- RHEL/CentOS 8+
- Fedora 29+

For older targets (RHEL 7 / glibc 2.17), change in `pyproject.toml`:
```toml
[tool.cibuildwheel.linux]
manylinux-x86_64-image = "manylinux2014"
```
And build PyInstaller inside the `manylinux2014` container.

---

## 12. SSH Workflow Security

### SHA-pinned actions (supply-chain hardening)

In March 2025, the `tj-actions/changed-files` attack moved Git tags to
malicious commits, compromising 23,000+ repositories instantly.

**This template pins every third-party action to a full commit SHA.**
Version tag comments (`# v4.2.2`) are for human readability only.
Dependabot opens weekly PRs to update SHA pins.

```yaml
# Correct: immutable SHA pin with version comment
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

# Wrong: mutable tag (can be hijacked)
- uses: actions/checkout@v4
```

### Principle of least privilege

```yaml
permissions: {}              # repo-wide default: nothing

jobs:
  test:
    permissions:
      contents: read         # checkout only

  attest:
    permissions:
      contents:     read
      id-token:     write    # OIDC for Sigstore
      attestations: write    # write attestations

  release:
    permissions:
      contents: write        # create release + upload assets

  publish-pypi:
    permissions:
      id-token: write        # OIDC for PyPI — no password/token
```

### No long-lived credentials

| Old pattern | This template |
|-------------|---------------|
| PAT with `repo` scope | SSH deploy key (read-only, single repo) |
| PyPI API token in secrets | OIDC trusted publishing (no secret) |
| macOS p12 in env var | Secret used only in signing step, then deleted |

### Verify artifact provenance

```bash
gh attestation verify \
    myapp-1.2.0-linux-x86_64.AppImage \
    --repo ORGANIZATION/PACKAGE_NAME
```

---

## 13. Enabling PyPI Publishing

Uses **OIDC Trusted Publishing** — no tokens, no passwords, no rotation.

### One-time PyPI configuration

1. Log in to [pypi.org](https://pypi.org) → Your project → **Publishing**
2. **Add a new trusted publisher**:
   - Publisher: GitHub Actions
   - Owner: `ORGANIZATION`
   - Repository: `PACKAGE_NAME`
   - Workflow: `release.yml`
   - Environment: `pypi`

### GitHub environment setup

Settings → Environments → New environment → `pypi`

Add deployment protection:
- Deployment branches: tag pattern `v*`
- (Optional) Required reviewers before publishing

The `publish-pypi` job is already configured with `environment: pypi` and
`permissions: id-token: write`. No secrets needed.

---

## 14. Artifact Verification

All release artifacts are attested with SLSA Build Provenance Level 2 and
a signed SBOM via GitHub's Sigstore integration.

```bash
# Verify provenance of any artifact
gh attestation verify myapp-1.2.0-linux-x86_64.AppImage \
    --repo ORGANIZATION/PACKAGE_NAME

# List all attestations for this repo
gh attestation ls --repo ORGANIZATION/PACKAGE_NAME

# Verify a wheel
gh attestation verify myapp-1.2.0-cp312-cp312-manylinux_2_28_x86_64.whl \
    --repo ORGANIZATION/PACKAGE_NAME
```

---

## License

MIT — see [LICENSE](LICENSE).
