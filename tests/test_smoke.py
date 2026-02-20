"""Smoke tests for the dashboard app (no GUI required)."""

import importlib
import sys
from unittest.mock import MagicMock


def _ensure_pyside6_mock():
    """If PySide6 isn't installed, inject a mock so app.main can be imported."""
    if "PySide6" not in sys.modules:
        try:
            import PySide6  # noqa: F401
        except ModuleNotFoundError:
            mock = MagicMock()
            sys.modules["PySide6"] = mock
            sys.modules["PySide6.QtWidgets"] = mock


def _load_main():
    """Import (or reload) app.main, mocking PySide6 if needed."""
    _ensure_pyside6_mock()
    mod = importlib.import_module("app.main")
    importlib.reload(mod)
    return mod


def test_import_main_module():
    """The app.main module should be importable without starting a GUI."""
    mod = _load_main()
    assert hasattr(mod, "MainWindow")
    assert hasattr(mod, "APP_VERSION")


def test_version_metadata_defaults(monkeypatch):
    """Without env vars, version metadata falls back to dev defaults."""
    monkeypatch.delenv("APP_VERSION", raising=False)
    monkeypatch.delenv("BUILD_NUMBER", raising=False)
    monkeypatch.delenv("COMMIT_SHA", raising=False)

    mod = _load_main()

    assert mod.APP_VERSION == "dev"
    assert mod.BUILD_NUMBER == "0"
    assert mod.COMMIT_SHA == "unknown"


def test_version_metadata_from_env(monkeypatch):
    """Env vars should propagate into version metadata."""
    monkeypatch.setenv("APP_VERSION", "v1.2.3")
    monkeypatch.setenv("BUILD_NUMBER", "42")
    monkeypatch.setenv("COMMIT_SHA", "abc1234def5678")

    mod = _load_main()

    assert mod.APP_VERSION == "1.2.3"
    assert mod.BUILD_NUMBER == "42"
    assert mod.COMMIT_SHA == "abc1234"


def test_app_name_from_repo_name(monkeypatch):
    """REPO_NAME should be converted to title-case APP_NAME."""
    monkeypatch.setenv("REPO_NAME", "my-cool-app")

    mod = _load_main()

    assert mod.APP_NAME == "My Cool App"
