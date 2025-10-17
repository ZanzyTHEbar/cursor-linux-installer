#!/usr/bin/env bash

set -e

echo "Uninstalling Cursor..."

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
    echo "Removing Cursor AppImage..."
    rm -f "$cursor_appimage"
else
    echo "Cursor AppImage not found."
fi

# Remove the cursor script from ~/.local/bin
echo "Removing Cursor script..."
rm -f "$HOME/.local/bin/cursor"

# Remove icons
echo "Removing Cursor icons..."
find "$HOME/.local/share/icons/hicolor" -name "cursor.png" -delete

# Remove desktop file
echo "Removing Cursor desktop file..."
rm -f "$HOME/.local/share/applications/cursor.desktop"

echo "Cursor has been uninstalled."

# Optionally, ask the user if they want to remove configuration files
read -r -p "Do you want to remove Cursor configuration files? (y/N) " remove_config
if [[ $remove_config =~ ^[Yy]$ ]]; then
    echo "Removing Cursor configuration files..."
    rm -rf "$HOME/.config/Cursor"
    echo "Configuration files removed."
fi

echo "Uninstallation complete."

