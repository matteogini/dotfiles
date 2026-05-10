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
    
    # 1. Decommenta il blocco nel file (disabilita animazioni/blur/shadows)
    sed -i "/$START/,/$END/ { /$START/! { /$END/! s/^#[[:space:]]*// } }" "$CONFIG"
    
    # 2. Assicura 120Hz con VRR attivo
    hyprctl keyword monitor "$MONITOR,$RES@120,$POS,$SCALE,vrr,1"
}

# Funzione per tornare a Performance (120Hz + VRR + Eye Candy)
disable_battery() {
    echo "Restoring Performance Mode (120Hz VRR + Animations)..."
    
    # 1. Commenta il blocco nel file (riabilita animazioni/blur/shadows)
    sed -i "/$START/,/$END/ { /$START/! { /$END/! { /^[[:space:]]*#/! s/^/#/ } } }" "$CONFIG"
    
    # 2. Ripristina i 120Hz
    hyprctl keyword monitor "$MONITOR,$RES@120,$POS,$SCALE,vrr,1"
}

# LOGICA DI TOGGLE
# Controlla se la riga 'animations {' è commentata per capire lo stato attuale
if sed -n "/$START/,/$END/p" "$CONFIG" | grep -q "^#animations"; then
    enable_battery
else
    disable_battery
fi

# Notifica Waybar per aggiornare eventuali icone/moduli
pkill -USR2 waybar
