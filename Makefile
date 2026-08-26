# Factory Clicker Build Automation Makefile
SHELL := /bin/bash
FLUTTER ?= $(shell which flutter 2>/dev/null || echo "$(HOME)/development/flutter/bin/flutter")

.PHONY: all help analyze clean build-web build-linux build-windows run-web serve test-e2e

all: analyze build-web

help:
	@echo "Factory Clicker Makefile Targets:"
	@echo "  make build-web      - Compile production Web release (build/web)"
	@echo "  make build-linux    - Compile native Linux binary (build/linux/x64/release/bundle)"
	@echo "  make build-windows  - Compile native Windows binary (build/windows/x64/runner/Release)"
	@echo "  make run-web        - Run Flutter web dev server"
	@echo "  make serve          - Serve production web build locally on port 8080"
	@echo "  make test-e2e       - Execute Playwright integration test suite"
	@echo "  make analyze        - Run static analysis checks"
	@echo "  make clean          - Clean build cache and temporary artifacts"

analyze:
	@echo "==> Running Flutter static analysis..."
	$(FLUTTER) analyze

clean:
	@echo "==> Cleaning build artifacts..."
	$(FLUTTER) clean
	rm -rf build/ test-results/ .playwright-mcp/

build-web:
	@echo "==> Building Flutter Web release..."
	$(FLUTTER) build web --release

build-linux:
	@echo "==> Building Flutter Linux native binary..."
	$(FLUTTER) build linux --release

build-windows:
	@echo "==> Building Flutter Windows native binary..."
	@if [ "$$(uname -s)" = "Linux" ]; then \
		echo "Note: When building for Windows from WSL/Linux, run this on host Windows PowerShell:"; \
		echo "      flutter build windows --release"; \
		if command -v powershell.exe >/dev/null 2>&1; then \
			echo "Attempting build via host PowerShell..."; \
			powershell.exe -Command "flutter build windows --release" || echo "Please install Flutter on Windows host or use GitHub Actions."; \
		fi; \
	else \
		$(FLUTTER) build windows --release; \
	fi

run-web:
	@echo "==> Starting Flutter Web development server..."
	$(FLUTTER) run -d chrome

serve:
	@echo "==> Serving production web build at http://127.0.0.1:8080..."
	python3 -m http.server 8080 --directory build/web

test-e2e:
	@echo "==> Running Playwright E2E integration test suite..."
	npx playwright test
