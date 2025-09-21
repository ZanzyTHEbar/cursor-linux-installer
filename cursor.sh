#!/usr/bin/env bash

set -e

ROOT=$(dirname "$(dirname "$(readlink -f $0)")")

function check_fuse() {
    # Set command prefix based on whether we're root
    local cmd_prefix=""
    if [ "$EUID" -ne 0 ]; then
        cmd_prefix="sudo"
    fi

    # Check and install FUSE using the appropriate package manager
    if command -v apt-get &>/dev/null; then
        if ! dpkg -l | grep -q "^ii.*fuse "; then
            echo "Installing FUSE..."
            $cmd_prefix apt-get update
            $cmd_prefix apt-get install -y fuse
        else
            echo "FUSE is already installed."
        fi
    elif command -v dnf &>/dev/null; then
        if ! rpm -q fuse >/dev/null 2>&1; then
            echo "Installing FUSE..."
            $cmd_prefix dnf install -y fuse
        else
            echo "FUSE is already installed."
        fi
    elif command -v pacman &>/dev/null; then
        if ! pacman -Qi fuse2 >/dev/null 2>&1; then
            echo "Installing FUSE..."
            $cmd_prefix pacman -S fuse2
        else
            echo "FUSE is already installed."
        fi
    else
        echo "Unsupported package manager. Please install FUSE manually."
        echo "You can install FUSE using your system's package manager:"
        echo "  - Debian/Ubuntu: ${cmd_prefix}apt-get install fuse"
        echo "  - Fedora: ${cmd_prefix}dnf install fuse"
        echo "  - Arch Linux: ${cmd_prefix}pacman -S fuse2"
        exit 1
    fi

    # Verify FUSE2 is functional
    if ! fusermount -V >/dev/null 2>&1; then
        echo "Warning: FUSE2 verification failed. AppImage may not run." >&2
        return 1
    fi
    echo "FUSE2 is ready."
}

function get_arch() {
    local arch=$(uname -m)
    if [ "$arch" == "x86_64" ]; then
        echo "x64"
    elif [ "$arch" == "aarch64" ]; then
        echo "arm64"
    else
        echo "Unsupported architecture: $arch" >&2
        exit 1
    fi
}

function find_cursor_appimage() {
    local search_dirs=("$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin")
    for dir in "${search_dirs[@]}"; do
        local appimage=$(find "$dir" -name "cursor.appimage" -print -quit 2>/dev/null)
        if [ -n "$appimage" ]; then
            echo "$appimage"
            return 0
        fi
    done
    return 1
}

function get_install_dir() {
    local search_dirs=("$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin")
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return 0
        fi
    done
    echo "No suitable installation directory found" >&2
    exit 1
}

function get_fallback_download_info() {
    local arch=$(get_arch)
    local fallback_hash="d750e54bba5cffada6d7b3d18e5688ba5e944ad9"  # From 1.6.27 (Sep 17, 2025; update periodically)
    local fallback_version="1.6.27"
    echo "URL=https://downloads.cursor.com/production/$fallback_hash/linux/$arch/Cursor-$fallback_version-${arch}.AppImage"
    echo "VERSION=$fallback_version"
    return 1  # Still error, but usable URL
}

function get_download_info() {
    local temp_html=$(mktemp)
    local release_track=${1:-stable} # Default to stable if not specified
    local arch=$(get_arch)  # x64 or arm64
    local platform="linux-${arch}"
    local api_url="https://cursor.com/api/download?platform=$platform&releaseTrack=$release_track"

    echo "Fetching download info for $release_track track..."
    if ! curl -sL "$api_url" -o "$temp_html"; then
        rm -f "$temp_html"
        get_fallback_download_info "curl failed on $api_url"
        return 1
    fi

    # Scrape for AppImage URL (matches pattern in UI hrefs)
    local download_url=$(grep -o 'https://downloads\.cursor\.com/[^[:space:]]*\.AppImage' "$temp_html" | head -1 | sed 's/["'\'']\?$//')  # Strip quotes/trailing

    rm -f "$temp_html"

    if [ -z "$download_url" ]; then
        get_fallback_download_info "No AppImage URL found in response"
        return 1
    fi

    # Extract version from filename (e.g., Cursor-1.6.35-x86_64.AppImage → 1.6.35)
    local version=$(basename "$download_url" | sed -E 's/.*Cursor-([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

    if [ -z "$version" ]; then
        version="unknown"  # Rare fallback
    fi

    echo "URL=$download_url"
    echo "VERSION=$version"
    return 0
}

function install_cursor() {
    local install_dir="$1"
    local release_track=${2:-stable} # Default to stable if not specified
    local temp_file=$(mktemp)
    local current_dir=$(pwd)
    local download_info=$(get_download_info "$release_track")
    local message=$(echo "$download_info" | grep "MESSAGE=" | sed 's/^MESSAGE=//')

    if [ -n "$message" ]; then
        echo "$message"
        return 1
    fi

    # Check for FUSE before proceeding with installation
    check_fuse

    local download_url=$(echo "$download_info" | grep "URL=" | sed 's/^URL=//')
    local version=$(echo "$download_info" | grep "VERSION=" | sed 's/^VERSION=//')

    echo "Downloading $version Cursor AppImage..."
    if ! curl -L "$download_url" -o "$temp_file"; then
        echo "Failed to download Cursor AppImage" >&2
        rm -f "$temp_file"
        return 1
    fi

    chmod +x "$temp_file"
    mv "$temp_file" "$install_dir/cursor.appimage"

    # Ensure execution permissions persist post-move (robust against FS quirks)
    chmod +x "$install_dir/cursor.appimage"
    if [ -x "$install_dir/cursor.appimage" ]; then
        echo "Execution permissions confirmed for $install_dir/cursor.appimage"
    else
        echo "Warning: Failed to set execution permissions—check filesystem." >&2
        return 1
    fi

    # Store version information in a simple file
    echo "$version" >"$install_dir/.cursor_version"

    echo "Extracting icons and desktop file..."
    local temp_extract_dir=$(mktemp -d)
    cd "$temp_extract_dir"

    # Extract icons
    "$install_dir/cursor.appimage" --appimage-extract "usr/share/icons" >/dev/null 2>&1
    # Extract desktop file
    "$install_dir/cursor.appimage" --appimage-extract "cursor.desktop" >/dev/null 2>&1

    # Copy icons
    local icon_dir="$HOME/.local/share/icons/hicolor"
    mkdir -p "$icon_dir"
    cp -r squashfs-root/usr/share/icons/hicolor/* "$icon_dir/"

    # Copy desktop file
    local apps_dir="$HOME/.local/share/applications"
    mkdir -p "$apps_dir"
    cp squashfs-root/cursor.desktop "$apps_dir/"

    # Update desktop file to point to the correct AppImage location
    sed -i "s|Exec=.*|Exec=$install_dir/cursor.appimage --no-sandbox|g" "$apps_dir/cursor.desktop"

    # Fix potential icon name mismatch in the extracted desktop file
    sed -i 's/^Icon=co.anysphere.cursor/Icon=cursor/' "$apps_dir/cursor.desktop"

    # Clean up
    cd "$current_dir"
    rm -rf "$temp_extract_dir"

    echo "Cursor has been installed to $install_dir/cursor.appimage"
    echo "Icons and desktop file have been extracted and placed in the appropriate directories"
}

function update_cursor() {
    echo "Updating Cursor..."
    local arch=$(get_arch)
    local current_appimage=$(find_cursor_appimage)
    local install_dir
    local release_track=${1:-stable} # Default to stable if not specified

    if [ -n "$current_appimage" ]; then
        install_dir=$(dirname "$current_appimage")
    else
        install_dir=$(get_install_dir)
    fi

    install_cursor "$install_dir" "$release_track"
}

function launch_cursor() {
    local cursor_appimage=$(find_cursor_appimage)

    if [ -z "$cursor_appimage" ]; then
        echo "Error: Cursor AppImage not found. Running update to install it."
        update_cursor
        cursor_appimage=$(find_cursor_appimage)
    fi

    # Create a log file to capture output and errors
    local log_file="/tmp/cursor_appimage.log"

    # Run the AppImage in the background using nohup, redirecting output and errors to a log file
    nohup "$cursor_appimage" --no-sandbox "$@" >"$log_file" 2>&1 &

    # Capture the process ID (PID) of the background process
    local pid=$!

    # Wait briefly (1 second) to allow the process to start
    sleep 1

    # Check if the process is still running
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "Error: Cursor AppImage failed to start. Check the log for details."
        cat "$log_file"
    else
        echo "Cursor AppImage is running."
    fi
}

function get_version() {
    local cursor_appimage=$(find_cursor_appimage)
    if [ -z "$cursor_appimage" ]; then
        echo "Cursor is not installed"
        return 1
    fi

    local install_dir=$(dirname "$cursor_appimage")
    local version_file="$install_dir/.cursor_version"

    if [ -f "$version_file" ]; then
        local version=$(cat "$version_file")
        if [ -n "$version" ]; then
            echo "Cursor version: $version"
            return 0
        else
            echo "Version information is empty"
            return 1
        fi
    else
        echo "Version information not available"
        return 1
    fi
}

# Parse command-line arguments
if [ "$1" == "--version" ] || [ "$1" == "-v" ]; then
    get_version
    exit $?
elif [ "$1" == "--update" ]; then
    update_cursor "$2"
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: cursor [--update <stable|latest> | --version]"
    echo "  --update: Update Cursor to the specified version"
    echo "  --version, -v: Show the installed version of Cursor"
    exit 0
else
    launch_cursor "$@"
fi

exit $?
