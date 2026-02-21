"""Smoke and unit tests for PACKAGE_NAME.

These tests must pass on all three platforms (Linux / macOS / Windows)
without any external services or GUI display.
"""

from __future__ import annotations

import subprocess
import sys
from importlib.metadata import PackageNotFoundError, version


# ── import sanity ─────────────────────────────────────────────────────────────

def test_package_importable() -> None:
    """The top-level package must be importable."""
    import PACKAGE_NAME  # noqa: F401


def test_version_attribute_is_string() -> None:
    """__version__ must be a non-empty string."""
    import PACKAGE_NAME

    assert isinstance(PACKAGE_NAME.__version__, str)
    assert len(PACKAGE_NAME.__version__) > 0


def test_version_matches_metadata() -> None:
    """If installed, __version__ must match importlib.metadata."""
    import PACKAGE_NAME

    try:
        meta_version = version("PACKAGE_NAME")
        assert PACKAGE_NAME.__version__ == meta_version
    except PackageNotFoundError:
        pass  # Running from source checkout without install — acceptable


# ── CLI entry point ────────────────────────────────────────────────────────────

def test_main_help_exits_zero() -> None:
    """``PACKAGE_NAME --help`` must exit 0 and emit usage text."""
    result = subprocess.run(
        [sys.executable, "-m", "PACKAGE_NAME", "--help"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    assert "PACKAGE_NAME" in result.stdout


def test_main_version_exits_zero() -> None:
    """``PACKAGE_NAME --version`` must exit 0."""
    result = subprocess.run(
        [sys.executable, "-m", "PACKAGE_NAME", "--version"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0


def test_main_callable_returns_int() -> None:
    """main() must return an integer exit code."""
    from PACKAGE_NAME.__main__ import main

    code = main([])
    assert isinstance(code, int)
    assert code == 0


# ── packaging artefact tests (run in CI, skipped if files absent) ─────────────

import pytest
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent


def test_nfpm_yaml_exists_and_valid() -> None:
    """nfpm.yaml must exist and contain required fields."""
    nfpm = REPO_ROOT / "packaging" / "nfpm.yaml"
    if not nfpm.exists():
        pytest.skip("packaging/nfpm.yaml not present")

    import yaml  # type: ignore[import-untyped]

    data = yaml.safe_load(nfpm.read_text())
    assert "name" in data, "nfpm.yaml missing 'name'"
    assert "contents" in data, "nfpm.yaml missing 'contents'"
    assert isinstance(data["contents"], list)
    assert len(data["contents"]) > 0


def test_desktop_file_exists_and_valid() -> None:
    """Linux .desktop entry must contain required keys."""
    desktop = REPO_ROOT / "packaging" / "PACKAGE_NAME.desktop"
    if not desktop.exists():
        pytest.skip("packaging/PACKAGE_NAME.desktop not present")

    text = desktop.read_text()
    for required in ("[Desktop Entry]", "Name=", "Exec=", "Type=Application"):
        assert required in text, f".desktop file missing: {required!r}"


def test_pyinstaller_spec_exists() -> None:
    """A PyInstaller .spec file must exist in packaging/."""
    specs = list((REPO_ROOT / "packaging").glob("*.spec"))
    if not specs:
        pytest.skip("No .spec file found in packaging/")
    assert len(specs) >= 1
