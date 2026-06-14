#!/bin/bash
if pgrep -x "quickshell" > /dev/null; then
    # Performance Mode: Use Quickshell IPC
    quickshell ipc call qsIpc togglePowerMenu
else
    # Battery Mode: Fallback to Tofi/Legacy
    /home/matteo/.config/tofi/powermenu.sh
fi
