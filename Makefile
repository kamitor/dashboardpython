# =============================================================================
# Makefile — developer convenience targets
# All targets delegate to nox or direct tool invocations.
# =============================================================================
.PHONY: help install lint fmt typecheck test build-sdist build-wheel \
        build-pyinstaller build-nuitka build-appimage build-deb build-rpm \
        build-dmg clean

APP_NAME   ?= PACKAGE_NAME
APP_VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
PYTHON     ?= python3

help:           ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\nTargets:\n"} \
	     /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install:        ## Install project in editable mode with dev deps
	$(PYTHON) -m pip install --upgrade pip
	pip install -e ".[dev]"

lint:           ## Run ruff linter
	ruff check . --output-format=concise

fmt:            ## Auto-format with ruff
	ruff format .
	ruff check . --fix

typecheck:      ## Run mypy
	mypy

test:           ## Run pytest
	pytest --tb=short -q

test-cov:       ## Run pytest with coverage
	pytest --cov=src/$(APP_NAME) --cov-report=term-missing --cov-report=html

build-sdist:    ## Build source distribution
	python -m build --sdist

build-wheel:    ## Build wheel
	python -m build --wheel

# ── Binary builds ─────────────────────────────────────────────────────────────
build-pyinstaller: ## PyInstaller onefile (current platform)
	APP_NAME=$(APP_NAME) APP_VERSION=$(APP_VERSION) BUILD_MODE=onefile \
	    bash scripts/build_pyinstaller.sh

build-pyinstaller-onedir: ## PyInstaller onedir (current platform)
	APP_NAME=$(APP_NAME) APP_VERSION=$(APP_VERSION) BUILD_MODE=onedir \
	    bash scripts/build_pyinstaller.sh

build-nuitka:   ## Nuitka standalone (current platform)
	APP_NAME=$(APP_NAME) APP_VERSION=$(APP_VERSION) \
	    bash scripts/build_nuitka.sh

build-appimage: ## AppImage (Linux only — run build-pyinstaller first)
	APP_NAME=$(APP_NAME) APP_VERSION=$(APP_VERSION) \
	    bash scripts/build_appimage.sh

build-deb:      ## .deb package via nfpm (Linux only)
	APP_NAME=$(APP_NAME) APP_VERSION=$(APP_VERSION) \
	    bash scripts/build_deb.sh

build-rpm:      ## .rpm package via nfpm (Linux only)
	APP_NAME=$(APP_NAME) APP_VERSION=$(APP_VERSION) \
	    bash scripts/build_rpm.sh

build-dmg:      ## DMG (macOS only — run build-pyinstaller-onedir first)
	APP_NAME=$(APP_NAME) APP_VERSION=$(APP_VERSION) \
	    bash scripts/build_dmg.sh

build-all:      ## Build everything for the current platform
	$(MAKE) build-pyinstaller build-nuitka
	@if [ "$(shell uname -s)" = "Linux" ]; then \
	    $(MAKE) build-appimage build-deb build-rpm; \
	fi
	@if [ "$(shell uname -s)" = "Darwin" ]; then \
	    $(MAKE) build-dmg; \
	fi

clean:          ## Remove build artifacts
	rm -rf build/ dist/ wheelhouse/ *.egg-info __pycache__ .mypy_cache .pytest_cache
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
