#!/bin/bash

# Percorsi
CONFIG="$HOME/.config/hypr/modules/look_and_feel.conf"
START="### BEST BATTERY LIFE ###"
END="### MONITORS ###"

# Dati del monitor (Dinamici)
MONITOR_INFO=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true)')
MONITOR=$(echo "$MONITOR_INFO" | jq -r '.name')
WIDTH=$(echo "$MONITOR_INFO" | jq -r '.width')
HEIGHT=$(echo "$MONITOR_INFO" | jq -r '.height')
RES="${WIDTH}x${HEIGHT}"
POS="$(echo "$MONITOR_INFO" | jq -r '.x')x$(echo "$MONITOR_INFO" | jq -r '.y')"
SCALE=$(echo "$MONITOR_INFO" | jq -r '.scale')

# Funzione per attivare il Risparmio (120Hz + VRR + No Eye Candy)
# Manteniamo 120Hz perché permette al driver di allineare meglio i frame (48Hz floor)
enable_battery() {
    echo "Enabling Battery Savings (120Hz VRR + No Effects)..."
    sed -i "/$START/,/$END/ { /$START/! { /$END/! s/^#[[:space:]]*// } }" "$CONFIG"
    hyprctl keyword monitor "$MONITOR,$RES@120,$POS,$SCALE,vrr,1"
    
    hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { rounding = 0, shadow = { enabled = false }, blur = { enabled = false } } })'
}

disable_battery() {
    echo "Restoring Performance Mode (120Hz VRR + Animations)..."
    sed -i "/$START/,/$END/ { /$START/! { /$END/! { /^[[:space:]]*#/! s/^/#/ } } }" "$CONFIG"
    hyprctl keyword monitor "$MONITOR,$RES@120,$POS,$SCALE,vrr,1"
    
    hyprctl eval '
    local theme = require("theme")
    hl.config({
        animations = { enabled = true },
        decoration = {
            rounding = theme.rounding,
            shadow = { enabled = theme.shadow_enabled },
            blur = { enabled = theme.blur_enabled }
        }
    })
    ' >> /tmp/battery_mode.log 2>&1
}

# LOGICA DI TOGGLE
echo "Running toggle check..." >> /tmp/battery_mode.log
if sed -n "/$START/,/$END/p" "$CONFIG" | grep -q "^#animations"; then
    echo "Enabling battery" >> /tmp/battery_mode.log
    enable_battery >> /tmp/battery_mode.log 2>&1
else
    echo "Disabling battery" >> /tmp/battery_mode.log
    disable_battery >> /tmp/battery_mode.log 2>&1
fi

# Notifica Quickshell per aggiornare l'interfaccia
quickshell ipc call qsIpc refreshBatteryMode
