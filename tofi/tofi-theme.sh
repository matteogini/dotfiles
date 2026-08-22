#!/bin/bash
WALLPAPER_DIR="$HOME/.config/sway/wallpaper"
SWAY_CONFIG="$HOME/.config/sway/config"
DOTFILES_SWAY_CONFIG="$HOME/Projects/dotfiles/sway/config"

SELECTED_WALL=$(ls -1 "$WALLPAPER_DIR" | tofi --prompt-text="Theme: ")

if [ -z "$SELECTED_WALL" ]; then
    exit 0
fi

WALLPAPER_PATH="$WALLPAPER_DIR/$SELECTED_WALL"

# Apply wallpaper immediately
swaymsg output "*" bg "\"$WALLPAPER_PATH\"" fit "#000000"

# Make it persistent in sway configs (escaping | in sed)
sed -i "s|^output \* bg .*$|output * bg \"$WALLPAPER_PATH\" fit #000000|" "$SWAY_CONFIG"
if [ -f "$DOTFILES_SWAY_CONFIG" ]; then
    sed -i "s|^output \* bg .*$|output * bg \"$WALLPAPER_PATH\" fit #000000|" "$DOTFILES_SWAY_CONFIG"
fi
