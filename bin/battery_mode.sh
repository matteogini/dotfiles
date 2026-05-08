#!/bin/bash

# Percorsi
CONFIG="$HOME/.config/hypr/modules/look_and_feel.conf"
START="### BEST BATTERY LIFE ###"
END="### MONITORS ###"

# Dati del monitor estratti dal tuo config
MONITOR="eDP-1"
RES="2880x1800"
POS="1920x634"
SCALE="2.0"

# Funzione per attivare il Risparmio (60Hz + No Animazioni)
enable_battery() {
    echo "Enabling..."
    # 1. Decommenta il blocco nel file
    sed -i "/$START/,/$END/ { /$START/! { /$END/! s/^#[[:space:]]*// } }" "$CONFIG"
    
    # 2. Cambia il refresh rate a 60Hz via software
    hyprctl keyword monitor "$MONITOR,$RES@60,$POS,$SCALE"
}

# Funzione per tornare a Performance (120Hz + Animazioni)
disable_battery() {
    echo "Disabling..."
    # 1. Commenta il blocco nel file
    sed -i "/$START/,/$END/ { /$START/! { /$END/! { /^[[:space:]]*#/! s/^/#/ } } }" "$CONFIG"
    
    # 2. Ripristina i 120Hz
    hyprctl keyword monitor "$MONITOR,$RES@120,$POS,$SCALE"
}

# LOGICA DI TOGGLE
# Controlla se la riga 'animations {' è commentata
if sed -n "/$START/,/$END/p" "$CONFIG" | grep -q "^#animations"; then
    enable_battery
else
    disable_battery
fi
pkill -USR2 waybar
