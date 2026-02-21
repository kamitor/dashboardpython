#!/usr/bin/env bash
# =============================================================================
# scripts/build_appimage.sh — build an AppImage on Linux
# =============================================================================
# Produces a self-contained AppImage that runs on any x86_64 / aarch64 Linux
# distribution with glibc ≥ 2.28 (manylinux_2_28 baseline).
#
# Usage:
#   APP_VERSION=1.2.3 ./scripts/build_appimage.sh
#
# Dependencies installed automatically:
#   linuxdeploy, linuxdeploy-plugin-appimage, appimagetool
#
# The script expects a PyInstaller onefile binary at:
#   dist/PACKAGE_NAME  (produced by build_pyinstaller.sh onefile first)
# =============================================================================
set -euo pipefail

APP_NAME="${APP_NAME:-PACKAGE_NAME}"    # TODO
APP_VERSION="${APP_VERSION:-0.0.0}"
ARCH="$(uname -m)"                      # x86_64 or aarch64

echo "==> Building AppImage: ${APP_NAME} v${APP_VERSION} on ${ARCH}"

# ── Download linuxdeploy tools ────────────────────────────────────────────────
TOOLS_DIR="${HOME}/.local/bin"
mkdir -p "$TOOLS_DIR"

_download_tool() {
  local name="$1" url="$2"
  local dest="${TOOLS_DIR}/${name}"
  if [[ ! -x "$dest" ]]; then
    echo "    Downloading ${name}..."
    curl -fsSL "$url" -o "$dest"
    chmod +x "$dest"
  fi
}

case "$ARCH" in
  x86_64)
    _download_tool linuxdeploy \
      "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
    _download_tool linuxdeploy-plugin-appimage \
      "https://github.com/linuxdeploy/linuxdeploy-plugin-appimage/releases/download/continuous/linuxdeploy-plugin-appimage-x86_64.AppImage"
    ;;
  aarch64)
    _download_tool linuxdeploy \
      "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-aarch64.AppImage"
    _download_tool linuxdeploy-plugin-appimage \
      "https://github.com/linuxdeploy/linuxdeploy-plugin-appimage/releases/download/continuous/linuxdeploy-plugin-appimage-aarch64.AppImage"
    ;;
  *)
    echo "ERROR: Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

export PATH="${TOOLS_DIR}:${PATH}"
export ARCH   # consumed by linuxdeploy-plugin-appimage

# ── Verify PyInstaller binary exists ─────────────────────────────────────────
BINARY="dist/${APP_NAME}"
if [[ ! -f "$BINARY" ]]; then
  echo "ERROR: Binary not found at $BINARY"
  echo "       Run build_pyinstaller.sh (onefile) first."
  exit 1
fi

# ── Build AppDir ──────────────────────────────────────────────────────────────
APPDIR="dist/${APP_NAME}.AppDir"
rm -rf "$APPDIR"
mkdir -p "${APPDIR}/usr/bin"
mkdir -p "${APPDIR}/usr/share/applications"
mkdir -p "${APPDIR}/usr/share/icons/hicolor/256x256/apps"

cp "$BINARY" "${APPDIR}/usr/bin/${APP_NAME}"
chmod +x "${APPDIR}/usr/bin/${APP_NAME}"

# Desktop file
cp "packaging/${APP_NAME}.desktop" "${APPDIR}/usr/share/applications/"

# Icon
if [[ -f "assets/icon.png" ]]; then
  cp "assets/icon.png" \
     "${APPDIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
else
  # Placeholder 1×1 PNG so linuxdeploy doesn't fail
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' \
    > "${APPDIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
fi

# ── Package into AppImage ─────────────────────────────────────────────────────
OUTPUT_NAME="${APP_NAME}-${APP_VERSION}-linux-${ARCH}.AppImage"

linuxdeploy \
  --appdir "$APPDIR" \
  --desktop-file "${APPDIR}/usr/share/applications/${APP_NAME}.desktop" \
  --icon-file "${APPDIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png" \
  --output appimage

# linuxdeploy names the output based on the desktop Name= field
PRODUCED_APPIMAGE="$(find . -maxdepth 1 -name "*.AppImage" | head -1)"
if [[ -z "$PRODUCED_APPIMAGE" ]]; then
  echo "ERROR: AppImage was not produced." >&2
  exit 1
fi

mkdir -p dist/release
mv "$PRODUCED_APPIMAGE" "dist/release/${OUTPUT_NAME}"
chmod +x "dist/release/${OUTPUT_NAME}"

echo "==> Created dist/release/${OUTPUT_NAME}"

# ── Smoke test ────────────────────────────────────────────────────────────────
echo "==> Smoke testing AppImage..."
"dist/release/${OUTPUT_NAME}" --version
echo "==> Smoke test passed."
echo "==> Done."
