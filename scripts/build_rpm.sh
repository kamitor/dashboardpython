#!/usr/bin/env bash
# =============================================================================
# scripts/build_rpm.sh — build an .rpm package using nfpm
# =============================================================================
# Usage:
#   APP_VERSION=1.2.3 ./scripts/build_rpm.sh
#
# Requires: nfpm (see build_deb.sh)
# =============================================================================
set -euo pipefail

APP_NAME="${APP_NAME:-PACKAGE_NAME}"    # TODO
APP_VERSION="${APP_VERSION:-0.0.0}"
ARCH="${NFPM_ARCH:-amd64}"

echo "==> Building .rpm: ${APP_NAME} v${APP_VERSION} (${ARCH})"

BINARY="dist/${APP_NAME}"
if [[ ! -f "$BINARY" ]]; then
  echo "ERROR: Binary not found at $BINARY"
  echo "       Run build_pyinstaller.sh (onefile) first."
  exit 1
fi

mkdir -p dist/release

export APP_NAME APP_VERSION NFPM_ARCH="$ARCH"

nfpm package \
  --packager rpm \
  --config   packaging/nfpm.yaml \
  --target   "dist/release/${APP_NAME}-${APP_VERSION}-linux-${ARCH}.rpm"

echo "==> Created dist/release/${APP_NAME}-${APP_VERSION}-linux-${ARCH}.rpm"

if command -v rpm &>/dev/null; then
  echo "==> Package info:"
  rpm --query --info \
      --package "dist/release/${APP_NAME}-${APP_VERSION}-linux-${ARCH}.rpm"
fi

echo "==> Done."
