# =============================================================================
# scripts/build_nuitka.ps1 — Nuitka standalone build on Windows
# =============================================================================
# Usage:
#   $env:APP_VERSION = "1.2.3"
#   .\scripts\build_nuitka.ps1
#
# Requires:
#   pip install nuitka ordered-set zstandard
#   Visual Studio Build Tools or MSVC compiler
# =============================================================================
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$APP_NAME    = if ($env:APP_NAME)    { $env:APP_NAME }    else { "PACKAGE_NAME" }  # TODO
$APP_VERSION = if ($env:APP_VERSION) { $env:APP_VERSION } else { "0.0.0" }
$ARCH        = "x86_64"
$OS          = "windows"

Write-Host "==> Nuitka standalone build: $APP_NAME v$APP_VERSION on $OS-$ARCH"

$IconArgs = @()
if (Test-Path "assets\icon.ico") {
    $IconArgs = @("--windows-icon-from-ico=assets\icon.ico")
}

$CPUCount = (Get-WmiObject Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

python -m nuitka `
    --standalone `
    --onefile `
    @IconArgs `
    --windows-company-name="COMPANY_NAME" `
    --windows-product-name="$APP_NAME" `
    --windows-file-version="$APP_VERSION.0" `
    --windows-product-version="$APP_VERSION.0" `
    --windows-file-description="$APP_NAME" `
    --output-filename="$APP_NAME.exe" `
    --output-dir="dist\nuitka" `
    --assume-yes-for-downloads `
    --remove-output `
    --show-progress `
    --jobs=$CPUCount `
    "src\PACKAGE_NAME\__main__.py"   # TODO: adjust entry point

if ($LASTEXITCODE -ne 0) {
    Write-Error "Nuitka failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# ── Rename to canonical artifact name ────────────────────────────────────────
New-Item -ItemType Directory -Force -Path "dist\release" | Out-Null

$dest = "dist\release\$APP_NAME-$APP_VERSION-$OS-$ARCH-nuitka.exe"
Copy-Item "dist\nuitka\$APP_NAME.exe" $dest
Write-Host "==> Created $dest"
Write-Host "==> Done."
