"""CLI entry point for PACKAGE_NAME.

Invokable as:
    PACKAGE_NAME --help
    python -m PACKAGE_NAME --help
"""

from __future__ import annotations

import argparse
import sys
from typing import Sequence

from PACKAGE_NAME import __version__


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="PACKAGE_NAME",
        description="TODO: describe your application",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
    )
    # TODO: add your subcommands / arguments here
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    """Main entry point.  Returns an exit code (0 = success)."""
    parser = build_parser()
    args = parser.parse_args(list(argv) if argv is not None else None)
    _ = args

    # TODO: implement your application logic here
    print(f"PACKAGE_NAME {__version__}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
