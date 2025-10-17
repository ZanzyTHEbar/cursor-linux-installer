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
        stable|latest)
            RELEASE_TRACK="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: bash install.sh [stable|latest] [--extract|--no-fuse]"
            exit 1
            ;;
    esac
done

# URL of the cursor.sh script in the GitHub repository
CURSOR_SCRIPT_URL="https://raw.githubusercontent.com/ZanzyTHEbar/cursor-linux-installer/personal/cursor.sh"

# Local bin directory
LOCAL_BIN="$HOME/.local/bin"

# Create ~/.local/bin if it doesn't exist
mkdir -p "$LOCAL_BIN"

# Download cursor.sh and save it as 'cursor' in ~/.local/bin
echo "Downloading Cursor installer script..."
curl -fsSL "$CURSOR_SCRIPT_URL" -o "$LOCAL_BIN/cursor"

# Make the script executable
chmod +x "$LOCAL_BIN/cursor"

echo "Cursor installer script has been placed in $LOCAL_BIN/cursor"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo "Warning: $LOCAL_BIN is not in your PATH."
    echo "To add it, run this command or add it to your shell profile:"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Run cursor --update to download and install Cursor
echo "Downloading and installing Cursor ($INSTALL_MODE mode)..."
if [ "$INSTALL_MODE" = "extracted" ]; then
    "$LOCAL_BIN/cursor" --extract --update "$RELEASE_TRACK"
else
    "$LOCAL_BIN/cursor" --update "$RELEASE_TRACK"
fi

echo "Installation complete. You can now run 'cursor' to start Cursor."

