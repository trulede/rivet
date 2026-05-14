# Variables
BINARY_NAME=rivet
SRC_DIR=./cmd/rivet
BUILD_DIR=bin
MODULE_PATH = github.com/rivet/rivet/internal/version
GOLANGCI_LINT_VERSION := v1.64.5
GOTESTSUM_VERSION := v1.12.0

# Dynamic build information extracted from local environment
VERSION    ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "v0.1.0-dev")
COMMIT_SHA  = $(shell git rev-parse --short HEAD 2>/dev/null || echo "none")
BUILD_TIME  = $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Consolidate Linker Injection Flags (-X sets the string value at link time)
LD_FLAGS = -s -w -extldflags \"-static\" \
           -X '$(MODULE_PATH).Version=$(VERSION)' \
           -X '$(MODULE_PATH).CommitSHA=$(COMMIT_SHA)' \
           -X '$(MODULE_PATH).BuildTime=$(BUILD_TIME)'

# Dynamically locate the user's Go path or Go bin directory
GOPATH=$(shell go env GOPATH)
GOBIN=$(shell go env GOBIN)
ifeq ($(GOBIN),)
GOBIN=$(GOPATH)/bin
endif

.PHONY: all build clean run cross-compile test test-all generate mod lint install help

# Default target runs help to guide the user
all: help

## build: Build the binary for the current OS/Architecture
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 go build \
		-a \
		-tags "netgo osusergo" \
		-ldflags "$(LD_FLAGS)" \
		-o $(BUILD_DIR)/$(BINARY_NAME) $(SRC_DIR)
	@chmod +x $(BUILD_DIR)/$(BINARY_NAME)
	@echo "Binary built at $(BUILD_DIR)/$(BINARY_NAME)"

## run: Build and run the local binary immediately
run: build
	./$(BUILD_DIR)/$(BINARY_NAME)

## test: Run all project unit tests natively with race detection
test:
	@echo "Running tests..."
	gotestsum --format short-verbose -- ./... 

## test-all: Run unit tests and other integration/e2e tests
test-all:
	@echo "Running tests..."
	go test -v -race ./... -tags 'signals watch'

## lint: Lint (and fix) the code base
lint:
	@echo "Running golangci-lint..."
	golangci-lint run --fix ./...

## generate: Generate golden fixture files
generate:
	@echo "==> Cleaning old golden fixtures..."
	find ./testdata -name '*.golden' -delete 2>/dev/null || true
	@echo "==> Generating new golden fixtures via go test..."
	GOLDIE_UPDATE='true' GOLDIE_TEMPLATE='true' go test ./...

## mod: Download dependencies and tidy module files
mod:
	@echo "==> Downloading Go modules..."
	go mod download
	@echo "==> Tidying go.mod and go.sum..."
	go mod tidy
	@echo "==> Verifying dependency integrity..."
	go mod verify

## deps: Install all required CLI tools and download Go module dependencies
deps: 
	@echo "==> Verifying and installing system tool dependencies..."
	@mkdir -p $(GOBIN)
	# Install golangci-lint if missing
	@if ! command -v golangci-lint >/dev/null 2>&1; then \
		echo "Installing golangci-lint $(GOLANGCI_LINT_VERSION)..."; \
		curl -sSfL githubusercontent.com | sh -s -- -b $(GOBIN) $(GOLANGCI_LINT_VERSION); \
	else \
		echo "✓ golangci-lint is already installed."; \
	fi
	# Install gotestsum if missing (required for test summaries and test-watch)
	@if ! command -v gotestsum >/dev/null 2>&1; then \
		echo "Installing gotestsum $(GOTESTSUM_VERSION)..."; \
		CGO_ENABLED=0 go install github.com; \
	else \
		echo "✓ gotestsum is already installed."; \
	fi
	@echo "==> All dependencies successfully installed and verified."

## clean: Remove all build artifacts
clean:
	@echo "Cleaning build directory..."
	rm -rf $(BUILD_DIR)

## cross-compile: Cross-compile binaries for Linux, macOS, and Windows
cross-compile: clean test
	@echo "==> Cross-compiling for multiple platforms..."
	@mkdir -p $(BUILD_DIR)
	
	# Linux (Explicit static flags for safety)
	@echo "Building for Linux (amd64)..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-a \
		-tags "netgo osusergo" \
		-ldflags "$(LD_FLAGS)" \
		-o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 $(SRC_DIR)
	@chmod +x $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64
	
	# macOS (Apple Silicon - CGO_ENABLED=0 handles static linking inherently)
	@echo "Building for macOS (arm64)..."
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build \
		-a \
		-tags "netgo osusergo" \
		-ldflags "$(LD_FLAGS)" \
		-o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 $(SRC_DIR)
	@chmod +x $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64

	# Windows (CGO_ENABLED=0 handles static linking inherently)
	@echo "Building for Windows (amd64)..."
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build \
		-a \
		-tags "netgo osusergo" \
		-ldflags "$(LD_FLAGS)" \
		-o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe $(SRC_DIR)

	# Raspberry Pi / Embedded Linux (Modern 64-bit OS - Pi 3, 4, 5, Zero 2W)
	@echo "Building for Embedded Linux (ARM64)..."
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build \
		-a \
		-tags "netgo osusergo" \
		-ldflags "$(LD_FLAGS)" \
		-o $(BUILD_DIR)/$(BINARY_NAME)-linux-arm64 $(SRC_DIR)
	@chmod +x $(BUILD_DIR)/$(BINARY_NAME)-linux-arm64

	# Raspberry Pi / Embedded Linux (Legacy 32-bit hardware float - Pi 2, 3, Zero W)
	@echo "Building for Embedded Linux (ARMv7 32-bit)..."
	CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 go build \
		-a \
		-tags "netgo osusergo" \
		-ldflags "$(LD_FLAGS)" \
		-o $(BUILD_DIR)/$(BINARY_NAME)-linux-armv7 $(SRC_DIR)
	@chmod +x $(BUILD_DIR)/$(BINARY_NAME)-linux-armv7
	@echo "==> Cross-compilation complete."

## install: Install the binary to the standard user Go bin directory
install: build
	@echo "Installing $(BINARY_NAME) to $(GOBIN)..."
	@mkdir -p $(GOBIN)
	@cp $(BUILD_DIR)/$(BINARY_NAME) $(GOBIN)/$(BINARY_NAME)
	@echo "Installation successful."

## help: Show this help screen
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/## //' | awk -F: '{printf "  %-15s %s\n", $$1, $$2}'
