# =============================================================================
# scripts/build_pyinstaller.ps1 — build PyInstaller artifacts on Windows
# =============================================================================
# Usage:
#   $env:BUILD_MODE = "onefile"
#   $env:APP_VERSION = "1.2.3"
#   .\scripts\build_pyinstaller.ps1
# =============================================================================
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$APP_NAME    = if ($env:APP_NAME)    { $env:APP_NAME }    else { "PACKAGE_NAME" }  # TODO
$APP_VERSION = if ($env:APP_VERSION) { $env:APP_VERSION } else { "0.0.0" }
$BUILD_MODE  = if ($env:BUILD_MODE)  { $env:BUILD_MODE }  else { "onefile" }
$ARCH        = "x86_64"
$OS          = "windows"

Write-Host "==> Building $APP_NAME v$APP_VERSION [$BUILD_MODE] on $OS-$ARCH"

# ── Generate Windows version resource ────────────────────────────────────────
$parts = $APP_VERSION.Split(".")
$major = if ($parts.Count -gt 0) { [int]$parts[0] } else { 0 }
$minor = if ($parts.Count -gt 1) { [int]$parts[1] } else { 0 }
$patch = if ($parts.Count -gt 2) { [int]$parts[2] } else { 0 }

$versionContent = @"
# UTF-8
VSVersionInfo(
  ffi=FixedFileInfo(
    filevers=($major, $minor, $patch, 0),
    prodvers=($major, $minor, $patch, 0),
    mask=0x3f, flags=0x0, OS=0x40004, fileType=0x1, subtype=0x0,
    date=(0, 0)
  ),
  kids=[
    StringFileInfo([StringTable(u'040904B0', [
      StringStruct(u'CompanyName',      u'COMPANY_NAME'),
      StringStruct(u'FileDescription',  u'$APP_NAME'),
      StringStruct(u'FileVersion',      u'$APP_VERSION'),
      StringStruct(u'InternalName',     u'$APP_NAME'),
      StringStruct(u'OriginalFilename', u'$APP_NAME.exe'),
      StringStruct(u'ProductName',      u'$APP_NAME'),
      StringStruct(u'ProductVersion',   u'$APP_VERSION'),
    ])]),
    VarFileInfo([VarStruct(u'Translation', [1033, 1200])])
  ]
)
"@

New-Item -ItemType Directory -Force -Path "packaging" | Out-Null
$versionContent | Out-File -FilePath "packaging\windows-version.txt" -Encoding utf8

# ── Icon argument ────────────────────────────────────────────────────────────
$IconArgs = @()
if (Test-Path "assets\icon.ico") {
    $IconArgs = @("--icon", "assets\icon.ico")
}

# ── Build mode flag ──────────────────────────────────────────────────────────
$ModeFlag = if ($BUILD_MODE -eq "onefile") { "--onefile" } else { "--onedir" }

# ── Run PyInstaller ──────────────────────────────────────────────────────────
$env:APP_VERSION  = $APP_VERSION
$env:BUILD_MODE   = $BUILD_MODE

pyinstaller `
    $ModeFlag `
    --clean `
    --noconfirm `
    --name $APP_NAME `
    @IconArgs `
    --version-file "packaging\windows-version.txt" `
    "packaging\PACKAGE_NAME.spec"

if ($LASTEXITCODE -ne 0) {
    Write-Error "PyInstaller failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# ── Rename to canonical artifact name ────────────────────────────────────────
New-Item -ItemType Directory -Force -Path "dist\release" | Out-Null

if ($BUILD_MODE -eq "onefile") {
    $src  = "dist\$APP_NAME.exe"
    $dest = "dist\release\$APP_NAME-$APP_VERSION-$OS-$ARCH-onefile.exe"
    Copy-Item $src $dest
    Write-Host "==> Created $dest"
} else {
    # Create portable zip
    $src  = "dist\$APP_NAME"
    $dest = "dist\release\$APP_NAME-$APP_VERSION-$OS-$ARCH-portable.zip"
    Compress-Archive -Path "$src\*" -DestinationPath $dest -Force
    Write-Host "==> Created $dest"
}

Write-Host "==> Done."
