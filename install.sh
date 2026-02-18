#!/usr/bin/env bash

set -e

# Parse arguments
RELEASE_TRACK="stable"
INSTALL_MODE="appimage"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --extract|--no-fuse)
            INSTALL_MODE="extracted"
            shift
            ;;
        --stable|--latest)
            RELEASE_TRACK="${1#--}"
            shift
            ;;
        stable|latest)
            RELEASE_TRACK="$1"
            shift
            ;;
        *)
    echo "Unknown option: $1"
    echo "Usage: bash install.sh [stable|latest] [--extract|--no-fuse]"
    echo "Environment overrides: REPO_OWNER, REPO_NAME, REPO_BRANCH"
            exit 1
            ;;
    esac
done

# Determine whether to use local cursor.sh or download from GitHub
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOCAL_CURSOR_SH="$SCRIPT_DIR/cursor.sh"

# Repo URL parameters (override via env for release workflows)
REPO_OWNER=${REPO_OWNER:-watzon}
REPO_BRANCH=${REPO_BRANCH:-main}
REPO_NAME=${REPO_NAME:-cursor-linux-installer}
BASE_RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}"
CURSOR_SCRIPT_URL="$BASE_RAW_URL/cursor.sh"
LIB_DIR="$HOME/.local/share/cursor-installer"
LIB_PATH="$SCRIPT_DIR/lib.sh"
SHARED_LIB="$LIB_DIR/lib.sh"
LIB_URL="$BASE_RAW_URL/lib.sh"
SHIM_PATH="$SCRIPT_DIR/shim.sh"
SHARED_SHIM="$LIB_DIR/shim.sh"
SHIM_URL="$BASE_RAW_URL/shim.sh"
SHIM_HELPER_LOCAL="$SCRIPT_DIR/scripts/ensure-shim.sh"
SHIM_HELPER="$LIB_DIR/ensure-shim.sh"
SHIM_HELPER_URL="$BASE_RAW_URL/scripts/ensure-shim.sh"

# Source shared helpers (local repo, installed lib, or download)
if [ -f "$LIB_PATH" ]; then
    # shellcheck disable=SC1090
    source "$LIB_PATH"
    mkdir -p "$LIB_DIR"
    cp "$LIB_PATH" "$SHARED_LIB"
elif [ -f "$SHARED_LIB" ]; then
    # shellcheck disable=SC1090
    source "$SHARED_LIB"
else
    mkdir -p "$LIB_DIR"
    curl -fsSL "$LIB_URL" -o "$SHARED_LIB" || {
        echo "Failed to download lib.sh from GitHub" >&2
        exit 1
    }
    # shellcheck disable=SC1090
    source "$SHARED_LIB"
fi

# Local bin directory
LOCAL_BIN="$HOME/.local/bin"
CLI_NAME="cursor-installer"
CLI_PATH="$LOCAL_BIN/$CLI_NAME"
LEGACY_CLI="$LOCAL_BIN/cursor"

# Create ~/.local/bin if it doesn't exist
mkdir -p "$LOCAL_BIN"

# Remove legacy installer CLI if present to avoid conflicts
if [ -f "$LEGACY_CLI" ] && grep -q "install_cursor_extracted" "$LEGACY_CLI"; then
    log_warn "Removing legacy 'cursor' installer CLI to avoid conflicts."
    safe_remove "$LEGACY_CLI" "legacy cursor installer CLI"
fi

# Place cursor-installer CLI into ~/.local/bin from local file or GitHub
log_step "Preparing cursor-installer CLI script..."
if [ -f "$LOCAL_CURSOR_SH" ]; then
    log_info "Using local cursor.sh from repository"
    cp "$LOCAL_CURSOR_SH" "$CLI_PATH"
else
    log_info "Downloading cursor.sh from GitHub..."
curl -fsSL "$CURSOR_SCRIPT_URL" -o "$CLI_PATH" || {
    echo "Failed to download cursor.sh from GitHub" >&2
    exit 1
}
fi

# Make the script executable
chmod +x "$CLI_PATH"

log_ok "Cursor installer script has been placed in $CLI_PATH"

log_step "Ensuring cursor shim..."
SHIM_READY=true
if [ -f "$SHIM_PATH" ]; then
    cp "$SHIM_PATH" "$SHARED_SHIM"
elif [ -f "$SHARED_SHIM" ]; then
    :
else
    log_info "Downloading shim.sh from GitHub..."
    if ! curl -fsSL "$SHIM_URL" -o "$SHARED_SHIM"; then
        log_warn "Failed to download shim.sh; shim update skipped."
        SHIM_READY=false
    fi
fi

if [ "$SHIM_READY" = true ]; then
    if [ -f "$SHIM_HELPER_LOCAL" ]; then
        cp "$SHIM_HELPER_LOCAL" "$SHIM_HELPER"
    else
        log_info "Downloading ensure-shim.sh from GitHub..."
        if ! curl -fsSL "$SHIM_HELPER_URL" -o "$SHIM_HELPER"; then
            log_warn "Failed to download ensure-shim.sh; shim update skipped."
            SHIM_READY=false
        fi
    fi
fi

if [ "$SHIM_READY" = true ]; then
    chmod +x "$SHIM_HELPER" "$SHARED_SHIM" || true
    if ! "$SHIM_HELPER"; then
        log_warn "Shim update failed; continuing installation."
    fi
fi

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    log_warn "$LOCAL_BIN is not in your PATH."
    log_info "To add it, run this or add it to your shell profile:"
    log_info "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Run cursor --update to download and install Cursor
log_step "Downloading and installing Cursor ($INSTALL_MODE mode) from ${REPO_OWNER}/${REPO_NAME}@${REPO_BRANCH}..."
if [ "$INSTALL_MODE" = "extracted" ]; then
    "$CLI_PATH" --extract --update "$RELEASE_TRACK"
else
    "$CLI_PATH" --update "$RELEASE_TRACK"
fi

log_ok "Installation complete. You can now run '$CLI_NAME' to start Cursor."

