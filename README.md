# Cursor Linux Installer

Cursor is an excellent AI-powered code editor, but it doesn't treat Linux as a first-class citizen. Unlike macOS and Windows, which have distribution-specific installers, Linux users are left with an AppImage that doesn't integrate well with the system. This means no `cursor` or `code` commands in your terminal, making it less convenient to use.

This repository aims to solve that problem by providing a set of shell scripts that will:

1. Download and install Cursor for you
2. Provide a `cursor` command that you can run from your shell
3. Allow you to easily update Cursor when new versions are released

## Installation

You can install the Cursor Linux Installer using either curl or wget. Choose the method you prefer:

### Using curl

```bash
# Install stable version (default, AppImage mode)
curl -fsSL https://raw.githubusercontent.com/ZanzyTHEbar/cursor-linux-installer/personal/install.sh | bash

# Install latest version
curl -fsSL https://raw.githubusercontent.com/ZanzyTHEbar/cursor-linux-installer/personal/install.sh | bash -s -- latest

# Install in extracted mode (no FUSE required)
curl -fsSL https://raw.githubusercontent.com/ZanzyTHEbar/cursor-linux-installer/personal/install.sh | bash -s -- stable --extract
```

### Using wget

```bash
# Install stable version (default, AppImage mode)
wget -qO- https://raw.githubusercontent.com/ZanzyTHEbar/cursor-linux-installer/personal/install.sh | bash

# Install latest version
wget -qO- https://raw.githubusercontent.com/ZanzyTHEbar/cursor-linux-installer/personal/install.sh | bash -s -- latest

# Install in extracted mode (no FUSE required)
wget -qO- https://raw.githubusercontent.com/ZanzyTHEbar/cursor-linux-installer/personal/install.sh | bash -s -- stable --extract
```

The installation script will:

1. Download the `cursor.sh` script and save it as `cursor` in `~/.local/bin/`
2. Make the script executable
3. Download and install the latest version of Cursor

## Uninstalling

To uninstall the Cursor Linux Installer, you can run the uninstall script:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ZanzyTHEbar/cursor-linux-installer/personal/uninstall.sh)"
```

or

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/ZanzyTHEbar/cursor-linux-installer/personal/uninstall.sh)"

```

The uninstall script will:

1. Remove the `cursor` script from `~/.local/bin/`
2. Remove the Cursor AppImage
3. Ask if you want to remove the Cursor configuration files

## Usage

After installation, you can use the `cursor` command to launch Cursor or update it:

- To launch Cursor: `cursor`
- To update Cursor: `cursor --update [options]`
  - Update to stable version: `cursor --update` or `cursor --update stable`
  - Update to latest version: `cursor --update latest`
  - Additional arguments can be passed after `--update` to control the update behavior
- To check Cursor version: `cursor --version` or `cursor -v`
  - Shows the installed version of Cursor if available
  - Returns an error if Cursor is not installed or version cannot be determined

## Installation Modes

The installer supports two installation modes:

### AppImage Mode (Default)

The default mode installs Cursor as an AppImage. This requires FUSE2 to be installed on your system.

**Requirements:**

- FUSE2 (automatically installed by the script on Debian/Ubuntu, Fedora, and Arch)

**Advantages:**

- Smaller disk footprint
- Standard AppImage format

**Usage:**

```bash
cursor --update stable
```

### Extracted Mode (FUSE-Free)

This mode fully extracts the AppImage and installs Cursor as a native application, **eliminating the need for FUSE**. This is ideal for:

- Systems without FUSE support
- Restricted environments (containers, some cloud instances)
- Users who prefer traditional installations

**Advantages:**

- No FUSE dependency
- Works in restricted environments
- Native application structure
- Potentially better compatibility

**Usage:**

```bash
# Install in extracted mode
cursor --extract

# Update in extracted mode
cursor --extract --update stable

# Set as default via environment variable
export CURSOR_INSTALL_MODE=extracted
cursor --update stable
```

**Note:** The extracted installation is stored in `~/.local/share/cursor/` and takes up more disk space (~500MB) compared to the AppImage.

## Note

If you encounter a warning that `~/.local/bin` is not in your PATH, you can add it by running:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

or add it to your shell profile (e.g., `.bashrc`, `.zshrc`, etc.):

```bash
echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
```

## License

This software is released under the MIT License.

## Contributing

If you find a bug or have a feature request, please open an issue on GitHub.

If you want to contribute to the project, please fork the repository and submit a pull request.
