.DEFAULT_GOAL := help

.PHONY: help dev build build-debug lint lint-fix format format-check \
        test test-unit rust-lint rust-format rust-test ci setup clean \
        storybook storybook-build

## Development ---------------------------------------------------------------

help: ## Show this help message
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Development:"
	@echo "  dev            Run tauri dev server"
	@echo "  build          Build for production"
	@echo "  build-debug    Build with debug symbols"
	@echo "  storybook      Launch Storybook dev server"
	@echo ""
	@echo "Linting & Formatting:"
	@echo "  lint           Run all linters (frontend + Rust)"
	@echo "  lint-fix       Auto-fix lint issues"
	@echo "  format         Format all code"
	@echo "  format-check   Check formatting without changes"
	@echo ""
	@echo "Testing:"
	@echo "  test           Run all tests (frontend + Rust)"
	@echo "  test-unit      Run frontend unit tests only"
	@echo ""
	@echo "Rust:"
	@echo "  rust-lint      Run cargo clippy"
	@echo "  rust-format    Run cargo fmt"
	@echo "  rust-test      Run cargo test"
	@echo ""
	@echo "CI & Setup:"
	@echo "  ci             Run full CI pipeline (lint, format-check, test, build)"
	@echo "  storybook-build Build Storybook static site"
	@echo "  setup          Install dependencies and git hooks"
	@echo "  clean          Remove build artifacts"
	@echo ""

dev: ## Run tauri dev server
	pnpm tauri dev

build: ## Build for production
	pnpm tauri build

build-debug: ## Build with debug symbols
	pnpm tauri build --debug

storybook: ## Launch Storybook dev server
	pnpm run storybook

## Linting & Formatting ------------------------------------------------------

lint: ## Run all linters (frontend + Rust)
	pnpm run frontend:lint
	cd src-tauri && cargo clippy -- -D warnings

lint-fix: ## Auto-fix lint issues
	cd src-nuxt && pnpm eslint . --fix
	cd src-tauri && cargo clippy --fix --allow-dirty

format: ## Format all code
	pnpm run format

format-check: ## Check formatting without changes
	pnpm run format:check
	cd src-tauri && cargo fmt -- --check

## Testing -------------------------------------------------------------------

test: ## Run all tests (frontend + Rust)
	pnpm run frontend:test
	cd src-tauri && cargo test

test-unit: ## Run frontend unit tests only
	pnpm run frontend:test

## Rust ----------------------------------------------------------------------

rust-lint: ## Run cargo clippy
	cd src-tauri && cargo clippy -- -D warnings

rust-format: ## Run cargo fmt
	cd src-tauri && cargo fmt

rust-test: ## Run cargo test
	cd src-tauri && cargo test

## CI & Setup ----------------------------------------------------------------

storybook-build: ## Build Storybook static site
	pnpm run storybook:build

ci: lint format-check test build ## Run full CI pipeline

setup: ## Install dependencies and git hooks
	pnpm run project:init
	pnpm lefthook install

clean: ## Remove build artifacts
	pnpm run clean
