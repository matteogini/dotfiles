#!/bin/bash
if pgrep -x "quickshell" > /dev/null; then
    quickshell ipc call qsIpc toggleThemeSwitcher
else
    /home/matteo/.config/hypr/scripts/switch_theme.sh
fi
