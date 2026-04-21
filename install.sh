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
SMOKE_TIMEOUT_SECONDS=5
DOWNLOAD_URL=""

smoke_binary() {
  local binary_path="$1"
  local smoke_home="${TMP_DIR}/smoke-home"
  local stdout_file="${TMP_DIR}/smoke-stdout.txt"
  local stderr_file="${TMP_DIR}/smoke-stderr.txt"
  local status_file="${TMP_DIR}/smoke-status.txt"
  local timeout_file="${TMP_DIR}/smoke-timeout.txt"
  local pid
  local watchdog_pid
  local status

  mkdir -p "$smoke_home"

  (
    HOME="$smoke_home" \
      NO_COLOR=1 \
      API_URL='' \
      SANDBOX_KEY='' \
      WORKSPACE_ID='' \
      CONNECTION_ID='' \
      TRYCOOK_API_URL='' \
      "$binary_path" --help >"$stdout_file" 2>"$stderr_file"
    echo "$?" > "$status_file"
  ) 2>/dev/null &
  pid="$!"

  (
    sleep "$SMOKE_TIMEOUT_SECONDS"
    if kill -0 "$pid" 2>/dev/null; then
      echo "timed out after ${SMOKE_TIMEOUT_SECONDS}s" > "$timeout_file"
      kill -9 "$pid" 2>/dev/null || true
    fi
  ) &
  watchdog_pid="$!"

  wait "$pid" 2>/dev/null || true

  kill "$watchdog_pid" 2>/dev/null || true
  wait "$watchdog_pid" 2>/dev/null || true

  if [ -f "$timeout_file" ]; then
    echo "Error: Downloaded binary failed smoke check: $(<"$timeout_file")"
    return 1
  fi

  status="1"
  if [ -f "$status_file" ]; then
    status="$(<"$status_file")"
  fi

  if [ "$status" != "0" ]; then
    echo "Error: Downloaded binary failed smoke check with exit ${status}"
    sed -n '1,80p' "$stderr_file"
    return 1
  fi

  if ! grep -q "USAGE" "$stdout_file"; then
    echo "Error: Downloaded binary did not print expected help output"
    sed -n '1,80p' "$stdout_file"
    return 1
  fi
}

download_release_asset() {
  local asset_name="$1"
  local output_path="$2"
  local tag
  local url

  if [ "$VERSION" = "latest" ]; then
    url="https://github.com/${REPO}/releases/latest/download/${asset_name}"
    if curl -fsSL "$url" -o "$output_path"; then
      DOWNLOAD_URL="$url"
      return 0
    fi
    return 1
  fi

  for tag in "trycookcli-v${VERSION}" "v${VERSION}"; do
    url="https://github.com/${REPO}/releases/download/${tag}/${asset_name}"
    if curl -fsSL "$url" -o "$output_path"; then
      DOWNLOAD_URL="$url"
      return 0
    fi
  done

  return 1
}

download_checksum_asset() {
  local output_path="$1"
  local tag
  local url

  if [ "$VERSION" = "latest" ]; then
    url="https://github.com/${REPO}/releases/latest/download/checksums.txt"
    if curl -fsSL "$url" -o "$output_path"; then
      return 0
    fi
    return 1
  fi

  for tag in "trycookcli-v${VERSION}" "v${VERSION}"; do
    url="https://github.com/${REPO}/releases/download/${tag}/checksums.txt"
    if curl -fsSL "$url" -o "$output_path"; then
      return 0
    fi
  done

  return 1
}

# --- Resolve download URL ---

if [ "$VERSION" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${BINARY}"
else
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/trycookcli-v${VERSION}/${BINARY}"
fi

# --- Download ---

echo "Installing trycook (${PLATFORM})..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "  Downloading ${BINARY}..."
if ! download_release_asset "${BINARY}" "${TMP_DIR}/${BINARY}"; then
  echo "Error: Failed to download ${DOWNLOAD_URL}"
  echo "Check that the release exists and your platform is supported."
  exit 1
fi

# --- Verify checksum ---

echo "  Verifying checksum..."
if download_checksum_asset "${TMP_DIR}/checksums.txt" 2>/dev/null; then
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
chmod +x "${TMP_DIR}/${BINARY}"

echo "  Verifying binary..."
if ! smoke_binary "${TMP_DIR}/${BINARY}"; then
  echo "  Platform: ${PLATFORM}"
  echo "  Release URL: ${DOWNLOAD_URL}"
  echo "  Existing trycook install was not changed. Please retry after a fixed release is published."
  exit 1
fi

mv "${TMP_DIR}/${BINARY}" "${INSTALL_DIR}/trycook"

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
