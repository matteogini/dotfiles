#!/usr/bin/env bash
options="Shutdown\nReboot\nSuspend\nLogout"

choice=$(echo -e "$options" | tofi --config ~/.config/tofi/configpowermenu)

case "$choice" in
    "Shutdown")
        systemctl poweroff
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Suspend")
        systemctl suspend
        ;;
    "Logout")
        pkill -KILL -u "$USER"
        ;;
    *)
        exit 0
        ;;
esac