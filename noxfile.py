"""Nox configuration — automation for testing, linting, and building.

Run all default sessions:
    nox

Run a specific session:
    nox -s tests-3.12
    nox -s lint
    nox -s build
"""

from __future__ import annotations

import nox

nox.options.sessions = ["lint", "tests"]
nox.options.reuse_existing_virtualenvs = True

PYTHON_VERSIONS = ["3.10", "3.11", "3.12", "3.13"]
PACKAGE = "PACKAGE_NAME"  # TODO


@nox.session
def lint(session: nox.Session) -> None:
    """Run ruff linter and formatter check."""
    session.install("ruff")
    session.run("ruff", "check", ".", "--output-format=concise")
    session.run("ruff", "format", "--check", ".")


@nox.session
def typecheck(session: nox.Session) -> None:
    """Run mypy type checker."""
    session.install("mypy", "-e", ".[dev]")
    session.run("mypy")


@nox.session(python=PYTHON_VERSIONS)
def tests(session: nox.Session) -> None:
    """Run the test suite."""
    session.install("-e", ".[dev]")
    session.run(
        "pytest",
        "--tb=short",
        "--strict-markers",
        "-q",
        *session.posargs,
    )


@nox.session
def coverage(session: nox.Session) -> None:
    """Run tests with coverage reporting."""
    session.install("-e", ".[dev]")
    session.run(
        "pytest",
        f"--cov=src/{PACKAGE}",
        "--cov-report=term-missing",
        "--cov-report=html:htmlcov",
        "--cov-fail-under=80",
    )


@nox.session
def build(session: nox.Session) -> None:
    """Build sdist and wheel."""
    session.install("build")
    session.run("python", "-m", "build")


@nox.session
def pyinstaller(session: nox.Session) -> None:
    """Build PyInstaller onefile binary for the current platform."""
    session.install("-e", ".", "pyinstaller")
    session.run(
        "bash",
        "scripts/build_pyinstaller.sh",
        external=True,
        env={"BUILD_MODE": "onefile"},
    )
