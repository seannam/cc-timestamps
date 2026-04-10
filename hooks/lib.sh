#!/bin/bash
# lib.sh - Shared functions for cc-timestamps plugin
# Provides config loading, time formatting, state management, and theme rendering.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-/tmp/cc-timestamps}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

load_config() {
  local project_config="${PROJECT_DIR}/.claude/cc-timestamps.json"
  local default_config="${PLUGIN_ROOT}/defaults.json"

  if [[ -f "$project_config" ]]; then
    # Merge: defaults as base, project config overrides
    jq -s '.[0] * .[1]' "$default_config" "$project_config" 2>/dev/null || cat "$default_config"
  elif [[ -f "$default_config" ]]; then
    cat "$default_config"
  else
    # Inline fallback if even defaults.json is missing
    echo '{"time_format":"%-I:%M %p","date_format":"%b %d","show_date":true,"show_duration":true,"show_stats":false,"theme":"retro-im"}'
  fi
}

cfg_get() {
  # Usage: cfg_get <key> <config_json>
  local key="$1" config="$2"
  echo "$config" | jq -r ".$key // empty"
}

# ---------------------------------------------------------------------------
# Time formatting
# ---------------------------------------------------------------------------

format_time() {
  local fmt="$1"
  date +"$fmt" 2>/dev/null || date "+%-I:%M %p"
}

format_date() {
  local fmt="$1"
  date +"$fmt" 2>/dev/null || date "+%b %d"
}

now_epoch() {
  date +%s
}

# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

state_file() {
  local session_id="${1:-default}"
  echo "${PLUGIN_DATA}/state-${session_id}.json"
}

ensure_data_dir() {
  mkdir -p "$PLUGIN_DATA"
}

read_state() {
  local sf
  sf="$(state_file "${1:-default}")"
  if [[ -f "$sf" ]]; then
    cat "$sf"
  else
    echo '{"msg_count":0,"total_duration":0,"session_start":0,"last_prompt_epoch":0}'
  fi
}

write_state() {
  local session_id="${1:-default}" state_json="$2"
  ensure_data_dir
  local sf
  sf="$(state_file "$session_id")"
  echo "$state_json" > "$sf"
}

# ---------------------------------------------------------------------------
# Duration
# ---------------------------------------------------------------------------

calc_duration() {
  # Produces a human-readable duration string from two epoch timestamps.
  local start="$1" end="$2"
  local diff=$(( end - start ))

  if (( diff < 0 )); then
    diff=$(( -diff ))
  fi

  if (( diff == 0 )); then
    echo "<1s"
    return
  fi

  local hours=$(( diff / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))
  local secs=$(( diff % 60 ))

  local parts=()
  if (( hours > 0 )); then
    parts+=("${hours}h")
  fi
  if (( mins > 0 )); then
    parts+=("${mins}m")
  fi
  if (( secs > 0 && hours == 0 )); then
    # Only show seconds if under an hour
    parts+=("${secs}s")
  fi

  local IFS=" "
  echo "${parts[*]}"
}

# ---------------------------------------------------------------------------
# Theme / Banner formatting
# ---------------------------------------------------------------------------

format_banner() {
  # Usage: format_banner <theme> <time_str> <date_str> <show_date> <role> [duration_str] [stats_str]
  local theme="$1" time_str="$2" date_str="$3" show_date="$4" role="$5"
  local duration_str="${6:-}" stats_str="${7:-}"

  local timestamp="$time_str"
  if [[ "$show_date" == "true" ]]; then
    timestamp="${time_str} ${date_str}"
  fi

  local suffix=""
  if [[ -n "$duration_str" ]]; then
    suffix=" (took ${duration_str})"
  fi

  local stats_line=""
  if [[ -n "$stats_str" ]]; then
    stats_line="\n${stats_str}"
  fi

  case "$theme" in
    retro-im)
      echo -e "........................................\n[${timestamp}] ${role}:${suffix}${stats_line}"
      ;;
    minimal)
      echo -e "-- ${timestamp} | ${role}${suffix} --${stats_line}"
      ;;
    boxed)
      local inner="${timestamp} | ${role}${suffix}"
      local border
      border=$(printf '%*s' $(( ${#inner} + 4 )) '' | tr ' ' '-')
      echo -e "+${border}+\n|  ${inner}  |\n+${border}+${stats_line}"
      ;;
    plain)
      echo -e "${timestamp} ${role}${suffix}${stats_line}"
      ;;
    *)
      # Fall back to retro-im
      echo -e "........................................\n[${timestamp}] ${role}:${suffix}${stats_line}"
      ;;
  esac
}
