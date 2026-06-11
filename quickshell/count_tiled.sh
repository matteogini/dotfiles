#!/bin/bash

update() {
    active_ws=$(hyprctl activeworkspace -j | jq -r .id)
    if [ -z "$active_ws" ] || [ "$active_ws" = "null" ]; then echo 0; return; fi
    hyprctl clients -j | jq -c '[.[] | select(.workspace.id == '"$active_ws"' and .floating == false)] | length'
}

# Initial update
update

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    # Consume any rapid-fire events that arrive within 50ms
    while read -t 0.05 -r junk; do
        true
    done
    # Now that the burst is over, query Hyprland
    sleep 0.1
    update
done
