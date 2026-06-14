#!/bin/bash
ACTION=$1

case $ACTION in
    up)
        wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
esac

VAL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
if echo "$VAL" | grep -q "MUTED"; then
    PCT=0
else
    PCT=$(echo "$VAL" | LC_ALL=C awk '{print int($2 * 100)}')
fi

if pgrep -x "quickshell" > /dev/null; then
    quickshell ipc call qsIpc showOsd V "$PCT"
else
    # In battery mode, wob is running
    echo "$PCT" > $XDG_RUNTIME_DIR/wob.fifo
fi
