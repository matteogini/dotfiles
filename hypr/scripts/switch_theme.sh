#!/bin/bash

# --- 1. GESTIONE ARGOMENTI ---
if [ -n "$1" ]; then
    THEME_NAME="$1"
else
    THEME_NAME=$(ls ~/.config/hypr/themes/*.conf | xargs -n 1 basename | sed 's/\.conf//' | tofi --prompt-text " Tema: ")
fi

[ -z "$THEME_NAME" ] && exit 0
THEME_FILE="$HOME/.config/hypr/themes/$THEME_NAME.conf"

# --- 2. APPLICAZIONE TEMA HYPRLAND ---
cp "$THEME_FILE" "$HOME/.config/hypr/theme.conf"

# --- 3. ESTRAZIONE VARIABILI ---
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
if [[ "$THEME_NAME" == "nero" || "$THEME_NAME" == "black" ]]; then
    ACCENT="#ffffff"  
    BG="#000000"      
    FG="#ffffff"      
    TOFI_SEL="#ff0000" 
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
printf "@define-color accent %s;\n@define-color bg %s;\n@define-color fg %s;\n" "$ACCENT" "$BG" "$FG" > ~/.config/waybar/theme.css

cat > ~/.config/kitty/theme.conf <<EOF
foreground $FG
background $BG
cursor $ACCENT
EOF

# --- 6. OBSIDIAN (Sincronizzazione Colori) ---
OBSIDIAN_SNIPPET="/home/matteo/obsidian_vault/.obsidian/snippets/system-theme.css"

if [ -d "/home/matteo/obsidian_vault/.obsidian" ]; then
cat > "$OBSIDIAN_SNIPPET" <<EOF
/* Generato automaticamente da switch_theme.sh */
:root {
    --system-accent: $ACCENT;
    --system-bg: $BG;
    --system-fg: $FG;
}

.theme-dark, .theme-light {
    --accent-component: var(--system-accent) !important;
    --interactive-accent: var(--system-accent) !important;
    --text-accent: var(--system-accent) !important;
    --background-primary: var(--system-bg) !important;
    --background-secondary: var(--system-bg) !important;
    --background-primary-alt: var(--system-bg) !important;
    --text-normal: var(--system-fg) !important;
    --titlebar-background: var(--system-bg) !important;
}
EOF
fi

# --- 7. HYPRPAPER ---
if [ "$WALLPAPER" != "black" ] && [ -f "$WALLPAPER" ]; then
    printf "preload = %s\nwallpaper = ,%s\nsplash = false\nipc = on\n" "$WALLPAPER" "$WALLPAPER" > ~/.config/hypr/hyprpaper.conf
    pgrep -x "hyprpaper" > /dev/null || hyprpaper &
    sleep 0.8
    hyprctl hyprpaper preload "$WALLPAPER" > /dev/null 2>&1
    hyprctl hyprpaper wallpaper ",$WALLPAPER" > /dev/null 2>&1
else
    pkill hyprpaper
fi

# --- 8. REFRESH ---
killall -SIGUSR2 waybar > /dev/null 2>&1
killall -USR1 kitty > /dev/null 2>&1

echo "Tema $THEME_NAME applicato con successo!"