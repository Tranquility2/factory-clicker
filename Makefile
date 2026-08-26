# Factory Clicker Build Automation Makefile
SHELL := /bin/bash
FLUTTER ?= $(shell which flutter 2>/dev/null || echo "$(HOME)/development/flutter/bin/flutter")

.PHONY: all default help --help analyze clean build-web build-linux run-web serve test-e2e

default: help

--help: help

help:
	@echo "Factory Clicker Makefile Targets:"
	@echo "  make build-web      - Compile production Web release (build/web)"
	@echo "  make build-linux    - Compile native Linux binary (build/linux/x64/release/bundle)"
	@echo "  make run-web        - Run Flutter web dev server"
	@echo "  make serve          - Serve production web build locally on port 8080"
	@echo "  make test-e2e       - Execute Playwright integration test suite"
	@echo "  make analyze        - Run static analysis checks"
	@echo "  make clean          - Clean build cache and temporary artifacts"
	@echo "  make all            - Run analyze and build-web"
	@echo ""
	@echo "Note: To build for Windows, run ./build-windows.ps1 in Windows PowerShell."

all: analyze build-web

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

run-web:
	@echo "==> Starting Flutter Web development server..."
	$(FLUTTER) run -d chrome

serve:
	@echo "==> Serving production web build at http://127.0.0.1:8080..."
	python3 -m http.server 8080 --directory build/web

test-e2e:
	@echo "==> Running Playwright E2E integration test suite..."
	npx playwright test
