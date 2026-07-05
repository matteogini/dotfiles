#!/bin/bash
prev_charge=""

# Resolve static paths and values once at startup
TEMP_FILE=$(grep -l "k10temp" /sys/class/hwmon/hwmon*/name 2>/dev/null | head -n 1 | sed 's/name/temp1_input/')
gpu_mode=$(supergfxctl -g 2>/dev/null)
if [ -n "$gpu_mode" ]; then
  gpu_char=${gpu_mode:0:1}
  gpu="[${gpu_char,,}] "
else
  gpu=""
fi

while true; do
  cap=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)
  status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null)
  
  # Calculate average power over 60 seconds without extra wakeups
  curr_charge=$(cat /sys/class/power_supply/BAT1/charge_now 2>/dev/null)
  voltage=$(cat /sys/class/power_supply/BAT1/voltage_now 2>/dev/null)
  
  if [ -n "$prev_charge" ] && [ -n "$curr_charge" ] && [ "$status" = "Discharging" ]; then
    diff=$((prev_charge - curr_charge))
    power=$(awk -v diff="$diff" -v vol="$voltage" 'BEGIN { printf "%.1fW", (diff * 60 * vol) / 1000000000000 }')
  else
    current=$(cat /sys/class/power_supply/BAT1/current_now 2>/dev/null)
    power=$(awk -v cur="$current" -v vol="$voltage" 'BEGIN { if(cur>0) printf "%.1fW", (cur * vol) / 1000000000000 }')
  fi
  prev_charge="$curr_charge"

  if [ -n "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
    raw_temp=$(cat "$TEMP_FILE" 2>/dev/null)
    temp="$(($raw_temp / 1000))° "
  else
    temp=""
  fi

  current_time=$(date +%H:%M)

  if [ "$status" = "Charging" ]; then
    echo "$current_time $gpu$temp$power +$cap"
  else
    echo "$current_time $gpu$temp$power $cap"
  fi
  sleep 60
done
