#!/usr/bin/env bash
options="Shutdown\nLock\nReboot\nSuspend\nLogout"

choice=$(echo -e "$options" | tofi --config ~/.config/tofi/configpowermenu)

case "$choice" in
    "Shutdown") systemctl poweroff ;;
    "Lock") swaylock -f -c 000000 ;;
    "Reboot") systemctl reboot ;;
    "Suspend") swaylock -f -c 000000 & sleep 1 && systemctl suspend ;;
    "Logout") swaymsg exit ;;
esac
