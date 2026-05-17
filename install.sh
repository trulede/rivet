#!/bin/sh
set -e

# Repository configuration
REPO="go-rivet/rivet"

echo "🔍 Detecting host platform..."

# Detect Operating System
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
EXTENSION="tar.gz"

case "${OS}" in
    linux*)   OS="linux" ;;
    darwin*)  OS="darwin" ;;
    *) echo "❌ Unsupported Operating System: ${OS}"; exit 1 ;;
esac

# Detect CPU Architecture
ARCH=$(uname -m)
case "${ARCH}" in
    x86_64|amd64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    armv7l|armv7) ARCH="arm_v7" ;;
    i386|i686) ARCH="386" ;;
    *) echo "❌ Unsupported Architecture: ${ARCH}"; exit 1 ;;
esac

PLATFORM="${OS}_${ARCH}"
echo "✅ Found: ${PLATFORM}"

# Fetch latest release version from GitHub API (Corrected endpoint)
if [ -n "${RIVET_VERSION}" ]; then
    TARGET_VERSION="${RIVET_VERSION}"
    echo "📌 Using version requested via RIVET_VERSION environment variable: ${TARGET_VERSION}"
else
    echo "🌐 RIVET_VERSION not set. Fetching latest release version from GitHub API..."
    LATEST_RELEASE=$(curl -s "https://github.com{REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
    
    if [ -z "${LATEST_RELEASE}" ]; then
        echo "❌ Error: Could not resolve latest release version from GitHub."
        exit 1
    fi
    TARGET_VERSION="${LATEST_RELEASE}"
    echo "✅ Target Version: ${TARGET_VERSION}"
fi

# Download and extract binary (Corrected download URL structure)
FILE_NAME="rivet_${PLATFORM}.${EXTENSION}"
URL="https://github.com{REPO}/releases/download/${TARGET_VERSION}/${FILE_NAME}"
echo "📥 Downloading from: ${URL}"

# Create a clean temporary workspace
TMP_DIR=$(mktemp -d)
cd "${TMP_DIR}"

if ! curl -sSL -O "${URL}"; then
    echo "❌ Error: Download failed. Verify release asset exists for ${PLATFORM}."
    exit 1
fi

tar -xzf "${FILE_NAME}"
chmod +x "${BINARY_NAME}"

# Elevate and deploy binary to local user path
echo "⚙️ Installing ${BINARY_NAME} to /usr/local/bin/ (may require password)..."
if [ -w "/usr/local/bin" ]; then
    mv "${BINARY_NAME}" "/usr/local/bin/${BINARY_NAME}"
else
    sudo mv "${BINARY_NAME}" "/usr/local/bin/${BINARY_NAME}"
fi

# Clean up
cd - > /dev/null
rm -rf "${TMP_DIR}"

echo "🎉 Rivet ${TARGET_VERSION} installed successfully!"
/usr/local/bin/rivet --version
