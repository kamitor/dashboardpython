#!/usr/bin/env bash
# =============================================================================
# scripts/build_deb.sh — build a .deb package using nfpm
# =============================================================================
# Usage:
#   APP_VERSION=1.2.3 ./scripts/build_deb.sh
#
# Requires:
#   nfpm — https://nfpm.goreleaser.com/
#   Install: go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest
#   Or:      curl -sfL https://install.goreleaser.com/github.com/goreleaser/nfpm.sh | sh
#
# The script expects:
#   dist/${APP_NAME}  — PyInstaller onefile binary (run build_pyinstaller.sh first)
# =============================================================================
set -euo pipefail

APP_NAME="${APP_NAME:-PACKAGE_NAME}"    # TODO
APP_VERSION="${APP_VERSION:-0.0.0}"
ARCH="${NFPM_ARCH:-amd64}"

echo "==> Building .deb: ${APP_NAME} v${APP_VERSION} (${ARCH})"

# ── Validate binary exists ────────────────────────────────────────────────────
BINARY="dist/${APP_NAME}"
if [[ ! -f "$BINARY" ]]; then
  echo "ERROR: Binary not found at $BINARY"
  echo "       Run build_pyinstaller.sh (onefile) first."
  exit 1
fi

# ── Run nfpm ──────────────────────────────────────────────────────────────────
mkdir -p dist/release

export APP_NAME APP_VERSION NFPM_ARCH="$ARCH"

nfpm package \
  --packager deb \
  --config   packaging/nfpm.yaml \
  --target   "dist/release/${APP_NAME}-${APP_VERSION}-linux-${ARCH}.deb"

echo "==> Created dist/release/${APP_NAME}-${APP_VERSION}-linux-${ARCH}.deb"

# ── Verify package metadata ───────────────────────────────────────────────────
if command -v dpkg-deb &>/dev/null; then
  echo "==> Package info:"
  dpkg-deb --info "dist/release/${APP_NAME}-${APP_VERSION}-linux-${ARCH}.deb"
fi

echo "==> Done."
