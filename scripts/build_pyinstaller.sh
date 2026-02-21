#!/usr/bin/env bash
# =============================================================================
# scripts/build_pyinstaller.sh — build PyInstaller artifacts on Linux/macOS
# =============================================================================
# Usage:
#   BUILD_MODE=onefile  ./scripts/build_pyinstaller.sh
#   BUILD_MODE=onedir   ./scripts/build_pyinstaller.sh
#
# Environment variables:
#   APP_NAME     — binary name (default: PACKAGE_NAME)      # TODO
#   APP_VERSION  — version string (default: 0.0.0)
#   BUILD_MODE   — onefile | onedir  (default: onefile)
#   ARCH         — output arch label (default: auto-detected)
# =============================================================================
set -euo pipefail

APP_NAME="${APP_NAME:-PACKAGE_NAME}"          # TODO
APP_VERSION="${APP_VERSION:-0.0.0}"
BUILD_MODE="${BUILD_MODE:-onefile}"

# ── Architecture label ───────────────────────────────────────────────────────
if [[ -z "${ARCH:-}" ]]; then
  MACHINE="$(uname -m)"
  case "$MACHINE" in
    x86_64)  ARCH="x86_64"  ;;
    aarch64) ARCH="aarch64" ;;
    arm64)   ARCH="arm64"   ;;
    *)       ARCH="$MACHINE" ;;
  esac
fi

# ── OS label ────────────────────────────────────────────────────────────────
OS="linux"
if [[ "$(uname -s)" == "Darwin" ]]; then
  OS="macos"
  # On macOS with universal2 Python, override arch label
  ARCH="${ARCH:-universal2}"
fi

echo "==> Building ${APP_NAME} v${APP_VERSION} [${BUILD_MODE}] on ${OS}-${ARCH}"

# ── Icon resolution ──────────────────────────────────────────────────────────
ICON_ARG=()
if [[ "$OS" == "macos" ]] && [[ -f "assets/icon.icns" ]]; then
  ICON_ARG=(--icon "assets/icon.icns")
elif [[ -f "assets/icon.png" ]]; then
  ICON_ARG=(--icon "assets/icon.png")
elif [[ -f "assets/icon.ico" ]]; then
  ICON_ARG=(--icon "assets/icon.ico")
fi

# ── Build ────────────────────────────────────────────────────────────────────
export APP_VERSION BUILD_MODE

EXTRA_ARGS=()
if [[ "$BUILD_MODE" == "onefile" ]]; then
  EXTRA_ARGS+=(--onefile)
else
  EXTRA_ARGS+=(--onedir)
fi

pyinstaller \
  "${EXTRA_ARGS[@]}" \
  --clean \
  --noconfirm \
  --name "${APP_NAME}" \
  "${ICON_ARG[@]}" \
  packaging/PACKAGE_NAME.spec   # uses APP_VERSION + BUILD_MODE from env

# ── Rename output to canonical artifact name ─────────────────────────────────
mkdir -p dist/release

if [[ "$BUILD_MODE" == "onefile" ]]; then
  if [[ "$OS" == "macos" ]]; then
    # Zip the .app bundle
    cd dist
    zip -r "release/${APP_NAME}-${APP_VERSION}-${OS}-${ARCH}.app.zip" \
        "${APP_NAME}.app"
    cd ..
    echo "==> Created dist/release/${APP_NAME}-${APP_VERSION}-${OS}-${ARCH}.app.zip"
  else
    cp "dist/${APP_NAME}" \
       "dist/release/${APP_NAME}-${APP_VERSION}-${OS}-${ARCH}-onefile"
    echo "==> Created dist/release/${APP_NAME}-${APP_VERSION}-${OS}-${ARCH}-onefile"
  fi
else
  tar -czf "dist/release/${APP_NAME}-${APP_VERSION}-${OS}-${ARCH}.tar.gz" \
      -C dist "${APP_NAME}/"
  echo "==> Created dist/release/${APP_NAME}-${APP_VERSION}-${OS}-${ARCH}.tar.gz"
fi

echo "==> Done."
