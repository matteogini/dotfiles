#!/bin/bash
update() {
    active_ws=$(hyprctl activeworkspace -j | jq -r .id)
    if [ -z "$active_ws" ]; then echo 0; return; fi
    hyprctl clients -j | jq -c '[.[] | select(.workspace.id == '"$active_ws"' and .floating == false)] | length'
}

update

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    case "$line" in
        workspace*|openwindow*|closewindow*|changefloatingmode*|movewindow*)
            update
            ;;
    esac
done
