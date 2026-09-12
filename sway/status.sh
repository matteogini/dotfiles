#!/bin/bash
# swaybar status line, JSON protocol -- see swaybar-protocol(7).
#
# Right side: the same clock / gpu / temp / power / battery text as before.
# Left of it: one block per live Claude Code session, fed by the state files
# that ~/.claude/hooks/agent-state.sh writes. Those hooks send SIGUSR1 here,
# so agent state redraws instantly while the battery is still only sampled
# once a minute.
#
#   left click  -- focus that session's terminal
#   middle click -- dismiss that session's block
#   right click  -- dismiss every finished session

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/claude-agents"
INDICATOR_OFF="${XDG_CONFIG_HOME:-$HOME/.config}/agent-indicator.off"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/swaystatus.pid"
SAMPLE=60      # seconds between battery samples
MAX_AGENTS=6   # agent blocks before the rest collapse into "+N"

C_BUSY="#d8a657"   # working
C_WAIT="#ea6962"   # wants your input
C_DONE="#a9b665"   # finished
C_IDLE="#7c6f64"   # open but idle

main_pid=$$
echo "$main_pid" > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

nudged=0
trap 'nudged=1' USR1   # interrupts the sleep below -> instant redraw

# Consume click events on stdin. Never writes to stdout; asks the main loop
# for a redraw by signalling it.
read_clicks() {
  local line name inst btn con f st
  while IFS= read -r line; do
    line=${line#"["}
    line=${line#","}
    [ -n "$line" ] || continue
    IFS=$'\t' read -r name inst btn < <(
      jq -r '[.name // "", .instance // "", (.button // 0)] | @tsv' <<<"$line" 2>/dev/null)
    [ "$name" = claude ] || continue
    case $btn in
      1)
        con=""
        [ -f "$STATE_DIR/$inst" ] && IFS=$'\t' read -r st con < <(
          cut -f1,3 "$STATE_DIR/$inst" 2>/dev/null)
        [ "$con" = - ] && con=
        [ -n "$con" ] && swaymsg "[con_id=$con] focus" >/dev/null 2>&1
        ;;
      2)
        rm -f "$STATE_DIR/$inst"
        ;;
      3)
        for f in "$STATE_DIR"/*; do
          [ -f "$f" ] || continue
          IFS=$'\t' read -r st _ < "$f" || continue
          [ "$st" = done ] && rm -f "$f"
        done
        ;;
    esac
    kill -USR1 "$main_pid" 2>/dev/null
  done
}

# Process state letter from /proc: R running, S sleeping, T stopped.
proc_state() {
  sed 's/.*) //' "/proc/$1/stat" 2>/dev/null | cut -d' ' -f1
}

# A bar block stands for an interactive session you could switch to. Everything
# else sharing the binary name is infrastructure or a viewer: `claude daemon
# run` (where a --bg job lives, reparented to init and outliving every session),
# `claude agents`, mcp, plugin, update. Only `attach` opens a real session.
# NOTE: this predicate is duplicated in ~/.local/bin/agent-state -- keep both
# copies in step.
NOT_SESSION_claude='agents|attach|auth|auto-mode|daemon|doctor|gateway|import|install|kill|logs|mcp|plugin|plugins|project|respawn|rm|setup-token|stop|ultrareview|update|upgrade'
NOT_SESSION_agy='agent|agents|changelog|help|install|mcp|mic-serve|models|plugin|plugins|update'

is_session() {
  local pid=$1 comm bad arg1 a
  local -a args=()
  # an interactive session's stdin is its terminal
  case $(readlink "/proc/$pid/fd/0" 2>/dev/null) in /dev/pts/*) ;; *) return 1 ;; esac
  comm=$(cat "/proc/$pid/comm" 2>/dev/null) || return 1
  case $comm in
    claude) bad=$NOT_SESSION_claude ;;
    agy)    bad=$NOT_SESSION_agy ;;
    *)      return 1 ;;
  esac
  mapfile -d '' -t args < "/proc/$pid/cmdline" 2>/dev/null || return 1
  arg1=${args[1]:-}
  case $arg1 in
    ''|-*) ;;                                        # bare or flags: a session
    *) [[ $arg1 =~ ^($bad)$ ]] && return 1 ;;        # a management subcommand
  esac
  for a in "${args[@]}"; do                          # print mode is a one-shot
    case $a in -p|--print) return 1 ;; esac
  done
  return 0
}

# True when this process runs inside another agent -- a daemon or nested
# `claude -p` is that session's helper, not a session of its own.
has_agent_ancestor() {
  local q i c
  q=$(awk '/^PPid:/{print $2; exit}' "/proc/$1/status" 2>/dev/null)
  for i in $(seq 1 8); do
    [ -n "$q" ] && [ "$q" != 0 ] && [ -r "/proc/$q/comm" ] || return 1
    c=$(cat "/proc/$q/comm" 2>/dev/null)
    case $c in claude|agy) return 0 ;; esac
    q=$(awk '/^PPid:/{print $2; exit}' "/proc/$q/status" 2>/dev/null)
  done
  return 1
}

# Sessions that predate the hooks -- or a cleared state dir -- never fire an
# event, so the bar would never learn they exist. Read them off the process
# table instead: /proc gives the cwd for the label, and a session owns a
# terminal while helper processes do not. Slow path only; a normally started
# session registers itself via its SessionStart hook.
discover_agents() {
  local d pid comm tty cwd label
  [ -d "$STATE_DIR" ] || return
  for d in /proc/[0-9]*; do
    comm=$(cat "$d/comm" 2>/dev/null) || continue
    case $comm in claude|agy) ;; *) continue ;; esac
    pid=${d##*/}
    [ -e "$STATE_DIR/$comm:$pid" ] && continue
    is_session "$pid" || continue
    [ "$(proc_state "$pid")" = T ] && continue
    has_agent_ancestor "$pid" && continue
    cwd=$(readlink "$d/cwd" 2>/dev/null)
    label=${cwd##*/}
    label=${label//[^A-Za-z0-9._-]/_}
    [ -n "$label" ] || label=$pid
    printf 'ready\t%s\t-\t%s\t0\n' "$pid" "$label" > "$STATE_DIR/$comm:$pid" 2>/dev/null
  done
}

# Background jobs (claude --bg) run under the daemon with no terminal, so the
# /proc sweep above cannot see them. The daemon's roster maps each job to its
# repl pid, and the job's own state.json carries live state. A pre-warmed spare
# worker has no state.json -- that is what keeps it off the bar.
discover_bg_jobs() {
  local roster="$HOME/.claude/daemon/roster.json" short pid cwd st label
  [ -r "$roster" ] || return
  [ -d "$STATE_DIR" ] || return
  while IFS=$'\t' read -r short pid cwd; do
    [ -n "$short" ] && [ -n "$pid" ] || continue
    [ -f "$HOME/.claude/jobs/$short/state.json" ] || continue
    [ -d "/proc/$pid" ] || continue
    [ -e "$STATE_DIR/bg:$short" ] && continue
    st=$(jq -r '.state // ""' "$HOME/.claude/jobs/$short/state.json" 2>/dev/null)
    case $st in
      working) st=busy ;;
      blocked) st=wait ;;
      *)       st=ready ;;
    esac
    label=${cwd%/}
    label=${label##*/}
    label=${label//[^A-Za-z0-9._-]/_}
    [ -n "$label" ] || label=$short
    printf '%s\t%s\t-\t%s\t0\n' "$st" "$pid" "$label" > "$STATE_DIR/bg:$short"
  done < <(jq -r '.workers | to_entries[] |
    [.key, (.value.replPid // .value.pid // empty), (.value.cwd // "")] | @tsv' "$roster" 2>/dev/null)
}

# pts number of a session, used to tell same-directory sessions apart.
tty_of() {
  local t
  t=$(readlink "/proc/$1/fd/0" 2>/dev/null)
  t=${t##*/}
  case $t in [0-9]*) printf '%s' "$t" ;; esac
}

# One JSON block per session, most urgent first, capped at MAX_AGENTS.
agent_blocks() {
  [ -e "$INDICATOR_OFF" ] && return   # hidden from the ags control center
  local f sid st pid con label n txt e col icon tag t
  local -a rows=() want=() busy=() fini=() idle=() ordered=()
  local -A dupe=()

  [ -d "$STATE_DIR" ] || return
  for f in "$STATE_DIR"/*; do
    [ -f "$f" ] || continue
    IFS=$'\t' read -r st pid con label n < "$f" || continue
    [ "$pid" = - ] && pid=
    [ "$con" = - ] && con=
    [ "$label" = - ] && label=
    if [ -n "$pid" ] && [ ! -d "/proc/$pid" ]; then
      rm -f "$f" "$STATE_DIR/.locks/${f##*/}"   # gone, end event or not
      continue
    fi
    # suspended with Ctrl+Z: parked, not pending. Keep the file so resuming
    # brings the block back with its window id still attached.
    [ -n "$pid" ] && [ "$(proc_state "$pid")" = T ] && continue
    sid=${f##*/}
    [ -n "$label" ] || label=${sid#*:}
    [ -n "$n" ] || n=0
    rows+=("$sid|$st|$pid|$label|$n")
    dupe["${sid%%:*}/$label"]=$(( ${dupe["${sid%%:*}/$label"]:-0} + 1 ))
  done

  for e in "${rows[@]}"; do
    IFS='|' read -r sid st pid label n <<<"$e"
    # file name is "<source>:<pid>" -- c = claude code, a = antigravity
    case ${sid%%:*} in
      claude) tag=c ;;
      agy)    tag=a ;;
      bg)     tag=bg ;;
      *)      tag=${sid:0:1} ;;
    esac
    t=""
    [ "${dupe["${sid%%:*}/$label"]:-1}" -gt 1 ] && [ -n "$pid" ] && t=$(tty_of "$pid")
    if [ -n "$t" ]; then
      # several sessions in one directory render identically: name the tty too
      [ ${#label} -gt 7 ] && label="${label:0:6}…"
      label="$label#$t"
    else
      [ ${#label} -gt 10 ] && label="${label:0:9}…"
    fi
    label="$tag:$label"
    case $st in
      wait) want+=("$sid|$C_WAIT|?|$label|$n") ;;
      busy) busy+=("$sid|$C_BUSY|▶|$label|$n") ;;
      done) fini+=("$sid|$C_DONE|✓|$label|$n") ;;
      *)    idle+=("$sid|$C_IDLE|·|$label|$n") ;;
    esac
  done

  ordered=("${want[@]}" "${busy[@]}" "${fini[@]}" "${idle[@]}")
  local total=${#ordered[@]} shown=0
  for e in "${ordered[@]}"; do
    [ "$shown" -ge "$MAX_AGENTS" ] && break
    IFS='|' read -r sid col icon label n <<<"$e"
    txt="$icon$label"
    [ "$n" -gt 0 ] && txt="$txt·$n"
    printf '{"name":"claude","instance":"%s","full_text":"%s","short_text":"%s","color":"%s","separator":false,"separator_block_width":10},' \
      "$sid" "$txt" "$icon" "$col"
    shown=$((shown + 1))
  done
  if [ "$total" -gt "$shown" ]; then
    printf '{"name":"claude","instance":"more","full_text":"+%s","color":"%s","separator":false,"separator_block_width":10},' \
      "$((total - shown))" "$C_IDLE"
  fi
}

# Resolve static paths and values once at startup
TEMP_FILE=$(grep -l "k10temp" /sys/class/hwmon/hwmon*/name 2>/dev/null | head -n 1 | sed 's/name/temp1_input/')
gpu_mode=$(supergfxctl -g 2>/dev/null)
if [ -n "$gpu_mode" ]; then
  gpu_char=${gpu_mode:0:1}
  gpu="[${gpu_char,,}] "
else
  gpu=""
fi

printf '{"version":1,"click_events":true}\n[\n'

# Bash points a background job's stdin at /dev/null in a non-interactive
# shell, so hand the reader an explicit duplicate of the bar's event stream.
exec 3<&0
read_clicks <&3 &

prev_charge=""
last_sample=0
right=""
sep=""

while true; do
  nudged=0
  printf -v now '%(%s)T' -1

  if [ $((now - last_sample)) -ge "$SAMPLE" ]; then
    cap=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)
    status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null)

    # Average power since the previous sample. The gap is measured rather than
    # assumed, so a SIGUSR1 redraw in between cannot skew the reading.
    curr_charge=$(cat /sys/class/power_supply/BAT1/charge_now 2>/dev/null)
    voltage=$(cat /sys/class/power_supply/BAT1/voltage_now 2>/dev/null)
    elapsed=$((now - last_sample))

    if [ -n "$prev_charge" ] && [ -n "$curr_charge" ] && [ "$status" = "Discharging" ] &&
       [ "$last_sample" -gt 0 ] && [ "$elapsed" -gt 0 ]; then
      diff=$((prev_charge - curr_charge))
      power=$(awk -v diff="$diff" -v vol="$voltage" -v el="$elapsed" \
        'BEGIN { printf "%.1fW", (diff * (3600 / el) * vol) / 1000000000000 }')
    else
      current=$(cat /sys/class/power_supply/BAT1/current_now 2>/dev/null)
      power=$(awk -v cur="$current" -v vol="$voltage" \
        'BEGIN { if(cur>0) printf "%.1fW", (cur * vol) / 1000000000000 }')
    fi
    prev_charge="$curr_charge"

    if [ -n "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
      raw_temp=$(cat "$TEMP_FILE" 2>/dev/null)
      temp="$((raw_temp / 1000))° "
    else
      temp=""
    fi

    if [ "$status" = "Charging" ]; then
      right="$gpu$temp$power +$cap"
    else
      right="$gpu$temp$power $cap"
    fi
    last_sample=$now
    discover_agents
    discover_bg_jobs
  fi

  printf -v clock '%(%H:%M)T' -1

  if [ -f /etc/systemd/logind.conf.d/ignore-lid-switch.conf ]; then
    lid='{"full_text":"[ lid disabled ]","color":"'"$C_WAIT"'","separator":false,"separator_block_width":14},'
  else
    lid=""
  fi

  printf '%s[%s%s{"full_text":"%s %s","separator":false,"separator_block_width":12}]\n' \
    "$sep" "$(agent_blocks)" "$lid" "$clock" "$right"
  sep=","

  # A nudge that landed while rendering would otherwise wait out the sleep.
  [ "$nudged" = 1 ] && continue

  printf -v t '%(%s)T' -1
  remain=$((last_sample + SAMPLE - t))
  [ "$remain" -lt 1 ] && remain=1
  [ "$remain" -gt "$SAMPLE" ] && remain=$SAMPLE

  sleep "$remain" &
  sp=$!
  wait "$sp" 2>/dev/null
  kill "$sp" 2>/dev/null
done
