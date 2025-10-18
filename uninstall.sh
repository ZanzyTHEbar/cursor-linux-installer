#!/usr/bin/env bash

set -e

# Color and logging helpers
if [ -t 1 ]; then
    BOLD="\033[1m"; RESET="\033[0m"; RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"
else
    BOLD=""; RESET=""; RED=""; GREEN=""; YELLOW=""; BLUE=""
fi
log_info()  { echo -e "${BLUE}[*]${RESET} $*"; }
log_ok()    { echo -e "${GREEN}[✓]${RESET} $*"; }
log_warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
log_error() { echo -e "${RED}[x]${RESET} $*"; }
log_step()  { echo -e "${BOLD}$*${RESET}"; }

log_step "Uninstalling Cursor..."

# Function to find the Cursor AppImage
function find_cursor_appimage() {
    local search_dirs=("$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin")
    for dir in "${search_dirs[@]}"; do
        local appimage
        appimage=$(find "$dir" -name "cursor.appimage" -print -quit 2>/dev/null)
        if [ -n "$appimage" ]; then
            echo "$appimage"
            return 0
        fi
    done
    return 1
}

# Remove the Cursor AppImage
cursor_appimage=$(find_cursor_appimage)
if [ -n "$cursor_appimage" ]; then
    log_step "Removing Cursor AppImage..."
    rm -f "$cursor_appimage"
else
    log_warn "Cursor AppImage not found."
fi

# Remove the cursor script from ~/.local/bin
log_step "Removing Cursor script..."
rm -f "$HOME/.local/bin/cursor"

# Remove icons
log_step "Removing Cursor icons..."
find "$HOME/.local/share/icons/hicolor" -name "cursor.png" -delete

# Remove desktop file
log_step "Removing Cursor desktop file..."
rm -f "$HOME/.local/share/applications/cursor.desktop"

log_ok "Cursor has been uninstalled."

# Optionally, ask the user if they want to remove configuration files
read -r -p "Do you want to remove Cursor configuration files? (y/N) " remove_config
if [[ $remove_config =~ ^[Yy]$ ]]; then
    log_step "Removing Cursor configuration files..."
    rm -rf "$HOME/.config/Cursor"
    log_ok "Configuration files removed."
fi

log_ok "Uninstallation complete."

