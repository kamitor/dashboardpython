#!/usr/bin/env bash
# =============================================================================
# scripts/build_nuitka.sh — Nuitka standalone build on Linux/macOS
# =============================================================================
# Nuitka compiles Python to C and produces a smaller, faster standalone binary
# than PyInstaller, but builds take significantly longer.
#
# Usage:
#   APP_VERSION=1.2.3 ./scripts/build_nuitka.sh
#
# Requires:
#   pip install nuitka ordered-set zstandard
#   On Linux: patchelf, ccache (apt install patchelf ccache)
#   On macOS: Xcode Command Line Tools
# =============================================================================
set -euo pipefail

APP_NAME="${APP_NAME:-PACKAGE_NAME}"    # TODO
APP_VERSION="${APP_VERSION:-0.0.0}"

MACHINE="$(uname -m)"
case "$MACHINE" in
  x86_64)  ARCH="x86_64"  ;;
  aarch64) ARCH="aarch64" ;;
  arm64)   ARCH="arm64"   ;;
  *)       ARCH="$MACHINE" ;;
esac

OS="linux"
[[ "$(uname -s)" == "Darwin" ]] && OS="macos"

echo "==> Nuitka standalone build: ${APP_NAME} v${APP_VERSION} on ${OS}-${ARCH}"

ICON_ARG=""
if [[ "$OS" == "macos" ]] && [[ -f "assets/icon.icns" ]]; then
  ICON_ARG="--macos-app-icon=assets/icon.icns"
elif [[ -f "assets/icon.png" ]]; then
  ICON_ARG="--linux-icon=assets/icon.png"
fi

MACOS_ARGS=()
if [[ "$OS" == "macos" ]]; then
  MACOS_ARGS+=(
    "--macos-create-app-bundle"
    "--macos-app-name=${APP_NAME}"
    "--macos-app-version=${APP_VERSION}"
  )
fi

python -m nuitka \
  --standalone \
  --onefile \
  ${ICON_ARG:+"$ICON_ARG"} \
  "${MACOS_ARGS[@]}" \
  --output-filename="${APP_NAME}" \
  --output-dir=dist/nuitka \
  --assume-yes-for-downloads \
  --remove-output \
  --show-progress \
  --jobs="$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 2)" \
  "src/PACKAGE_NAME/__main__.py"   # TODO: adjust entry point

# ── Rename to canonical artifact name ────────────────────────────────────────
mkdir -p dist/release

DEST="dist/release/${APP_NAME}-${APP_VERSION}-${OS}-${ARCH}-nuitka"
cp "dist/nuitka/${APP_NAME}" "$DEST"
chmod +x "$DEST"

echo "==> Created ${DEST}"
echo "==> Done."
