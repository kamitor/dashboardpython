#!/usr/bin/env bash
# =============================================================================
# scripts/build_dmg.sh — create a macOS DMG from a PyInstaller .app bundle
# =============================================================================
# Usage (macOS only):
#   APP_VERSION=1.2.3 ./scripts/build_dmg.sh
#
# Requires:
#   create-dmg:   brew install create-dmg
#   Or:           npm install -g create-dmg
#   PyInstaller .app bundle already built (build_pyinstaller.sh)
#
# The .app is expected at: dist/${APP_NAME}.app
# =============================================================================
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: build_dmg.sh must run on macOS." >&2
  exit 1
fi

APP_NAME="${APP_NAME:-PACKAGE_NAME}"    # TODO
APP_VERSION="${APP_VERSION:-0.0.0}"
ARCH="${ARCH:-$(uname -m)}"

echo "==> Building DMG: ${APP_NAME} v${APP_VERSION} on macOS-${ARCH}"

APP_BUNDLE="dist/${APP_NAME}.app"
if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "ERROR: .app bundle not found at $APP_BUNDLE"
  echo "       Run: BUILD_MODE=onedir ./scripts/build_pyinstaller.sh"
  exit 1
fi

DMG_NAME="${APP_NAME}-${APP_VERSION}-macos-${ARCH}.dmg"
mkdir -p dist/release

# ── Option A: create-dmg (recommended, prettier) ─────────────────────────────
if command -v create-dmg &>/dev/null; then
  create-dmg \
    --volname "${APP_NAME} ${APP_VERSION}" \
    --volicon "assets/icon.icns" \
    --window-pos  200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 175 190 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 425 190 \
    "dist/release/${DMG_NAME}" \
    "$APP_BUNDLE"

# ── Option B: hdiutil (macOS built-in, plain) ────────────────────────────────
else
  echo "   create-dmg not found; using hdiutil fallback."
  STAGING="dist/dmg-staging"
  rm -rf "$STAGING"
  mkdir -p "$STAGING"
  cp -r "$APP_BUNDLE" "$STAGING/"

  hdiutil create \
    -volname "${APP_NAME} ${APP_VERSION}" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "dist/release/${DMG_NAME}"

  rm -rf "$STAGING"
fi

echo "==> Created dist/release/${DMG_NAME}"

# ── Optional: staple notarization ticket ─────────────────────────────────────
# Uncomment after notarization is complete (see README § macOS Signing):
# xcrun stapler staple "dist/release/${DMG_NAME}"

echo "==> Done."
