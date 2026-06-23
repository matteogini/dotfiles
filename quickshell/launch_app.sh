#!/usr/bin/env bash
echo "Launching: $1" >> /tmp/quickshell_launch.log
# some apps might be passed with arguments, so we should eval or just run it with bash -c
bash -c "$1" >/dev/null 2>&1 &
disown
