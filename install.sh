#!/bin/bash

# Install script for Rice dotfiles
# Automatically links/copies the configuration for faster porting to a new system

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/.local/bin"

echo "==================================="
echo "   Installing Rice Configuration"
echo "==================================="

# 1. Create necessary directories
echo "[*] Creating target directories..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$BIN_DIR"

# 2. Sync Configuration Directories
echo "[*] Syncing ~/.config directories..."
for dir in hypr kitty tofi waybar fish fastfetch foot ghostty wob; do
    if [ -d "$REPO_DIR/$dir" ]; then
        echo "    -> Syncing $dir"
        rsync -a "$REPO_DIR/$dir/" "$CONFIG_DIR/$dir/"
    fi
done

# 3. Setup Home files
echo "[*] Syncing home directory files..."
if [ -f "$REPO_DIR/.nanorc" ]; then
    echo "    -> Syncing .nanorc"
    cp "$REPO_DIR/.nanorc" "$HOME/.nanorc"
fi

# 4. Install local bin scripts
echo "[*] Installing ~/.local/bin scripts..."
if [ -d "$REPO_DIR/bin" ]; then
    for script in "$REPO_DIR/bin/"*; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            echo "    -> Installing $script_name"
            cp "$script" "$BIN_DIR/"
            chmod +x "$BIN_DIR/$script_name"
        fi
    done
fi

echo "==================================="
echo "   Installation Complete! 🎉"
echo "==================================="
echo "Note: Make sure $BIN_DIR is in your PATH."
