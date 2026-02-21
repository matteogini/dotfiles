#!/bin/bash

# --- 1. GESTIONE ARGOMENTI ---
if [ -n "$1" ]; then
    THEME_NAME="$1"
else
    THEME_NAME=$(ls ~/.config/hypr/themes/*.conf | xargs -n 1 basename | sed 's/\.conf//' | tofi --prompt-text " Tema: ")
fi

[ -z "$THEME_NAME" ] && exit 0
THEME_FILE="$HOME/.config/hypr/themes/$THEME_NAME.conf"

# --- 2. APPLICAZIONE TEMA ---
cp "$THEME_FILE" "$HOME/.config/hypr/theme.conf"

# --- 3. ESTRAZIONE VARIABILI (Versione Ultra-Robusta) ---
# Usiamo awk per essere sicuri di prendere il valore esatto dopo l'uguale
WALLPAPER=$(grep '$wallpaper' "$THEME_FILE" | awk -F'=' '{print $2}' | xargs)
ACCENT=$(grep '$accent_color' "$THEME_FILE" | awk -F'=' '{print $2}' | xargs)
BG=$(grep '$bg_color' "$THEME_FILE" | awk -F'=' '{print $2}' | xargs)
FG=$(grep '$fg_color' "$THEME_FILE" | awk -F'=' '{print $2}' | xargs)
TOFI_SEL=$(grep '$tofi_selection' "$THEME_FILE" | awk -F'=' '{print $2}' | xargs)

# Fallback: se le variabili sono vuote o mancano di #
[[ ! $ACCENT =~ ^# ]] && ACCENT="#ffffff" 
[[ ! $BG =~ ^# ]] && BG="#000000"
[[ ! $FG =~ ^# ]] && FG="#ffffff"

# LOGICA SPECIALE PER IL TEMA NERO/BLACK
# Se il tema si chiama nero o black, forziamo i colori come li volevi tu
if [[ "$THEME_NAME" == "nero" || "$THEME_NAME" == "black" ]]; then
    ACCENT="#ffffff"  # Waybar bianca
    BG="#000000"      # Sfondo nero
    FG="#ffffff"      # Testo bianco
    TOFI_SEL="#ff0000" # Selezione Tofi ROSSA
fi

[ -z "$TOFI_SEL" ] && TOFI_SEL=$ACCENT

# --- 4. SINCRONIZZAZIONE TOFI ---
for CONFIG in "config" "configpowermenu"; do
cat > ~/.config/tofi/$CONFIG <<EOF
anchor = top
width = 100%
height = $( [ "$CONFIG" == "config" ] && echo 25 || echo 30 )
horizontal = true
font-size = 10
prompt-text = " $( [ "$CONFIG" == "config" ] && echo "run:" || echo "Action:" ) "
font = JetBrainsMono Nerd Font
outline-width = 0
border-width = 0
min-input-width = 120
result-spacing = 25
padding-top = 5
padding-bottom = 5
padding-left = 10
padding-right = 10
background-color = $BG
text-color = $FG
selection-color = $TOFI_SEL
selection-background = #00000000
EOF
done

# --- 5. KITTY & WAYBAR ---
# Qui scriviamo il CSS. Se i valori sono corretti, Waybar non darà più errore.
printf "@define-color accent %s;\n@define-color bg %s;\n@define-color fg %s;\n" "$ACCENT" "$BG" "$FG" > ~/.config/waybar/theme.css

cat > ~/.config/kitty/theme.conf <<EOF
foreground $FG
background $BG
cursor $ACCENT
EOF

# --- 6. HYPRPAPER ---
if [ "$WALLPAPER" != "black" ] && [ -f "$WALLPAPER" ]; then
    printf "preload = %s\nwallpaper = ,%s\nsplash = false\nipc = on\n" "$WALLPAPER" "$WALLPAPER" > ~/.config/hypr/hyprpaper.conf
    pgrep -x "hyprpaper" > /dev/null || hyprpaper &
    sleep 1
    hyprctl hyprpaper preload "$WALLPAPER" > /dev/null 2>&1
    hyprctl hyprpaper wallpaper ",$WALLPAPER" > /dev/null 2>&1
else
    pkill hyprpaper
fi

# --- 7. REFRESH ---
killall -SIGUSR2 waybar > /dev/null 2>&1
killall -USR1 kitty > /dev/null 2>&1