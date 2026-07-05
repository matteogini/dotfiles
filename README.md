<h1 align="center">☁️ Sway Dotfiles</h1>

<p align="center">A clean, functional Linux setup centered around <b>Sway</b>.</p>

<div align="center">

![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff&style=for-the-badge)
![Sway](https://img.shields.io/badge/Sway-1793D1?logo=sway&logoColor=fff&style=for-the-badge)
![Fish](https://img.shields.io/badge/Fish-000?logo=fish&logoColor=fff&style=for-the-badge)

</div>

## 📸 Overview

<details open>
<summary><b>Click to expand screenshots</b></summary>

| Clean Desktop | Tiled Windows |
| :---: | :---: |
| <img src="preview/desktop.png" width="400"/> | <img src="preview/windows.png" width="400"/> |

| Terminal | App Launcher |
| :---: | :---: |
| <img src="preview/terminal.png" width="400"/> | <img src="preview/app-launcher.png" width="400"/> |

| Clipboard Manager | Power Menu |
| :---: | :---: |
| <img src="preview/clipboard.png" width="400"/> | <img src="preview/power-menu.png" width="400"/> |

</details>

## ✨ Features

- **Window Manager**: [Sway](https://swaywm.org/) - A dynamic tiling Wayland compositor that's a drop-in replacement for i3.
- **Terminal Emulator**: [Foot](https://codeberg.org/dnkl/foot) - A fast, lightweight, and minimalistic Wayland terminal emulator.
- **Application Launcher**: [Tofi](https://github.com/philj56/tofi) - A very fast and simple dmenu/rofi replacement for Wayland.
- **Shell**: [Fish](https://fishshell.com/) - With custom prompts, frozen key bindings, and useful aliases.
- **System Fetch**: [Fastfetch](https://github.com/fastfetch-cli/fastfetch)
- **Bar/OSD**: [Wob](https://github.com/francma/wob) - A lightweight overlay volume/backlight/progress/anything bar for Wayland.

## ⚙️ Structure

```text
.
├── bin/          # Custom scripts and binaries
├── fastfetch/    # Fastfetch config
├── fish/         # Fish shell config and functions
├── foot/         # Foot terminal config
├── nano/         # Nano editor config
├── sway/         # Sway configs and scripts
├── swaylock/     # Swaylock configuration
├── tofi/         # Tofi menus (app launcher, wifi, power)
└── wob/          # Wob (overlay bar) configuration
```

## 🛠️ Utilities
- `tofi-wifi.sh` & `tofi-bluetooth.sh`: Tofi-based GUIs to easily connect to networks and bluetooth devices.
- `pack_workspaces.py`: Custom script to organize Sway workspaces.
- `smart_clipboard.sh`: Quick clipboard management via wl-clipboard and tofi.

## 🚀 Installation
*(Assuming Arch Linux / Pacman-based distribution)*

1. Ensure the core packages are installed (`sway`, `swaylock`, `foot`, `fish`, `tofi`, `fastfetch`, `wob`, `wl-clipboard`).
2. Clone this repository into your `~/.config` or use the included `ricesync` script from `bin/` to sync the dotfiles.
3. Reload Sway.

> **Note**: This config relies on certain system tools like `brightnessctl`, `playerctl`, `nmcli` (NetworkManager), `bluetoothctl`, and `wpctl` (WirePlumber). Make sure you have them installed.
