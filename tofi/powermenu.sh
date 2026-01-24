#!/usr/bin/env bash
# Aggiunto Lock alla lista delle opzioni
options="Shutdown\nLock\nReboot\nSuspend\nLogout"

choice=$(echo -e "$options" | tofi --config ~/.config/tofi/configpowermenu)

case "$choice" in
    "Shutdown")
        systemctl poweroff
        ;;
    "Lock")
        # Esegue hyprlock
        hyprlock
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Suspend")
        # Spesso è meglio bloccare lo schermo PRIMA di sospendere
        hyprlock & sleep 1 && systemctl suspend
        ;;
    "Logout")
        pkill -KILL -u "$USER"
        ;;
    *)
        exit 0
        ;;
esac