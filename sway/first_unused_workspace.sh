#!/bin/bash
# Get the list of currently used workspaces
used_workspaces=$(swaymsg -t get_workspaces | jq '.[] | .num' | sort -n)

# Find the first unused workspace
for i in {1..100}; do
    if ! echo "$used_workspaces" | grep -qw "$i"; then
        swaymsg workspace number "$i"
        break
    fi
done
