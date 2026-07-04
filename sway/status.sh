#!/bin/bash
while true; do
  cap=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)
  status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null)
  power=$(awk '{line[NR]=$1} END {if(NR>0) printf "%.1fW", (line[1] * line[2]) / 1000000000000}' /sys/class/power_supply/BAT1/current_now /sys/class/power_supply/BAT1/voltage_now 2>/dev/null)

  raw_temp=$(cat $(grep -l "k10temp" /sys/class/hwmon/hwmon*/name | head -n 1 | sed 's/name/temp1_input/') 2>/dev/null)
  if [ -n "$raw_temp" ]; then
    temp="$(($raw_temp / 1000))° "
  else
    temp=""
  fi

  gpu_mode=$(supergfxctl -g 2>/dev/null)
  if [ -n "$gpu_mode" ]; then
    gpu_char=${gpu_mode:0:1}
    gpu="[${gpu_char,,}] "
  else
    gpu=""
  fi

  current_time=$(date +%H:%M)

  if [ "$status" = "Charging" ]; then
    echo "$current_time $gpu$temp$power +$cap"
  else
    echo "$current_time $gpu$temp$power $cap"
  fi
  sleep 10
done
