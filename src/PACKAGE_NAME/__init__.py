"""PACKAGE_NAME — TODO: describe your package.

Replace PACKAGE_NAME throughout this repository before use.
"""

from __future__ import annotations

# Version is injected by hatch-vcs at build time from the git tag.
# During development, it falls back to "0.0.0.dev0".
try:
    from importlib.metadata import version, PackageNotFoundError

    __version__: str = version("PACKAGE_NAME")
except PackageNotFoundError:  # running from source checkout
    __version__ = "0.0.0.dev0"

__all__ = ["__version__"]
