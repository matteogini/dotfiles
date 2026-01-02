#!/bin/bash

if pgrep -x spotify > /dev/null; then
    pkill -x spotify
    sleep 0.5
fi

spotify-launcher &

# aspetta che Spotify parta
sleep 3

# riproduce musica
playerctl -p spotify play
