#!/bin/bash
ACTION=$1

case $ACTION in
    up)
        brightnessctl s 5%+
        ;;
    down)
        brightnessctl s 5%-
        ;;
esac

PCT=$(brightnessctl i | grep -oP '\(\K[^%]+')

if pgrep -x "quickshell" > /dev/null; then
    quickshell ipc call qsIpc showOsd B "$PCT"
else
    # In battery mode, wob is running
    echo "$PCT" > $XDG_RUNTIME_DIR/wob.fifo
fi
