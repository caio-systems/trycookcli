#!/usr/bin/env bash
set -euo pipefail

# TryCook CLI installer
# Usage: curl -fsSL https://trycook.ai/install.sh | sh

VERSION="${TRYCOOK_VERSION:-latest}"
INSTALL_DIR="${TRYCOOK_INSTALL_DIR:-$HOME/.trycook/bin}"
REPO="caio-systems/trycookcli"

# --- Detect platform ---

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$OS" in
  darwin) ;;
  linux) ;;
  *) echo "Error: Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64) ARCH="x64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) echo "Error: Unsupported architecture: $ARCH"; exit 1 ;;
esac

PLATFORM="${OS}-${ARCH}"
BINARY="trycook-${PLATFORM}"

# --- Resolve download URL ---

if [ "$VERSION" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${BINARY}"
  CHECKSUM_URL="https://github.com/${REPO}/releases/latest/download/checksums.txt"
else
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${BINARY}"
  CHECKSUM_URL="https://github.com/${REPO}/releases/download/v${VERSION}/checksums.txt"
fi

# --- Download ---

echo "Installing trycook (${PLATFORM})..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "  Downloading ${BINARY}..."
if ! curl -fsSL "$DOWNLOAD_URL" -o "${TMP_DIR}/${BINARY}"; then
  echo "Error: Failed to download ${DOWNLOAD_URL}"
  echo "Check that the release exists and your platform is supported."
  exit 1
fi

# --- Verify checksum ---

echo "  Verifying checksum..."
if curl -fsSL "$CHECKSUM_URL" -o "${TMP_DIR}/checksums.txt" 2>/dev/null; then
  EXPECTED="$(grep "${BINARY}" "${TMP_DIR}/checksums.txt" | awk '{print $1}')"
  if [ -n "$EXPECTED" ]; then
    if command -v shasum &>/dev/null; then
      ACTUAL="$(shasum -a 256 "${TMP_DIR}/${BINARY}" | awk '{print $1}')"
    elif command -v sha256sum &>/dev/null; then
      ACTUAL="$(sha256sum "${TMP_DIR}/${BINARY}" | awk '{print $1}')"
    else
      ACTUAL=""
      echo "  Warning: No sha256 tool found, skipping verification"
    fi
    if [ -n "$ACTUAL" ] && [ "$ACTUAL" != "$EXPECTED" ]; then
      echo "Error: Checksum mismatch!"
      echo "  Expected: ${EXPECTED}"
      echo "  Got:      ${ACTUAL}"
      exit 1
    fi
  fi
else
  echo "  Warning: Could not fetch checksums, skipping verification"
fi

# --- Install ---

mkdir -p "$INSTALL_DIR"
mv "${TMP_DIR}/${BINARY}" "${INSTALL_DIR}/trycook"
chmod +x "${INSTALL_DIR}/trycook"

echo "  Installed to ${INSTALL_DIR}/trycook"

# --- Add to PATH ---

SHELL_NAME="$(basename "$SHELL")"
PROFILE=""

case "$SHELL_NAME" in
  zsh)  PROFILE="$HOME/.zshrc" ;;
  bash)
    if [ -f "$HOME/.bash_profile" ]; then
      PROFILE="$HOME/.bash_profile"
    else
      PROFILE="$HOME/.bashrc"
    fi
    ;;
  fish) PROFILE="$HOME/.config/fish/config.fish" ;;
esac

if [ -n "$PROFILE" ]; then
  PATH_LINE="export PATH=\"${INSTALL_DIR}:\$PATH\""
  if [ "$SHELL_NAME" = "fish" ]; then
    PATH_LINE="set -gx PATH ${INSTALL_DIR} \$PATH"
  fi

  if ! grep -q "$INSTALL_DIR" "$PROFILE" 2>/dev/null; then
    echo "" >> "$PROFILE"
    echo "# TryCook CLI" >> "$PROFILE"
    echo "$PATH_LINE" >> "$PROFILE"
    echo "  Added ${INSTALL_DIR} to PATH in ${PROFILE}"
    echo "  Run 'source ${PROFILE}' or open a new terminal to use trycook"
  fi
fi

echo ""
echo "Done! Run 'trycook --help' to get started."
