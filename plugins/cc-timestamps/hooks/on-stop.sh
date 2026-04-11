#!/bin/bash
# on-stop.sh - Stop hook for cc-timestamps
# Injects a timestamp banner when Claude finishes responding, with optional
# duration and running session statistics.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

main() {
  # Read hook input from stdin
  local input
  input="$(cat)"

  local session_id
  session_id="$(echo "$input" | jq -r '.session_id // "default"')"

  # Load config
  local config
  config="$(load_config)"

  local time_fmt date_fmt show_date show_duration show_stats theme
  time_fmt="$(cfg_get time_format "$config")"
  date_fmt="$(cfg_get date_format "$config")"
  show_date="$(cfg_get show_date "$config")"
  show_duration="$(cfg_get show_duration "$config")"
  show_stats="$(cfg_get show_stats "$config")"
  theme="$(cfg_get theme "$config")"

  # Format current time
  local time_str date_str
  time_str="$(format_time "$time_fmt")"
  date_str="$(format_date "$date_fmt")"

  local epoch
  epoch="$(now_epoch)"

  # Read state
  local state
  state="$(read_state "$session_id")"

  local last_prompt_epoch msg_count total_duration session_start
  last_prompt_epoch="$(echo "$state" | jq -r '.last_prompt_epoch // 0')"
  msg_count="$(echo "$state" | jq -r '.msg_count // 0')"
  total_duration="$(echo "$state" | jq -r '.total_duration // 0')"
  session_start="$(echo "$state" | jq -r '.session_start // 0')"

  # Calculate duration since user's prompt
  local duration_str=""
  if [[ "$show_duration" == "true" ]] && (( last_prompt_epoch > 0 )); then
    duration_str="$(calc_duration "$last_prompt_epoch" "$epoch")"
  fi

  # Update stats
  local response_duration=0
  if (( last_prompt_epoch > 0 )); then
    response_duration=$(( epoch - last_prompt_epoch ))
  fi
  msg_count=$(( msg_count + 1 ))
  total_duration=$(( total_duration + response_duration ))

  # Build stats string if enabled
  local stats_str=""
  if [[ "$show_stats" == "true" ]] && (( msg_count > 0 )); then
    local avg_duration=$(( total_duration / msg_count ))
    local avg_str
    avg_str="$(calc_duration 0 "$avg_duration")"
    local session_dur=""
    if (( session_start > 0 )); then
      session_dur="$(calc_duration "$session_start" "$epoch")"
      stats_str="[#${msg_count} | avg: ${avg_str} | session: ${session_dur}]"
    else
      stats_str="[#${msg_count} | avg: ${avg_str}]"
    fi
  fi

  # Save updated state
  local new_state
  new_state="$(jq -n \
    --argjson msg_count "$msg_count" \
    --argjson total_duration "$total_duration" \
    --argjson session_start "$session_start" \
    --argjson last_prompt_epoch "$last_prompt_epoch" \
    '{msg_count: $msg_count, total_duration: $total_duration, session_start: $session_start, last_prompt_epoch: $last_prompt_epoch}'
  )"
  write_state "$session_id" "$new_state"

  # Build the "claude:" banner for the response that just finished.
  local claude_banner
  claude_banner="$(format_banner "$theme" "$time_str" "$date_str" "$show_date" "claude" "$duration_str" "$stats_str")"

  # Build the "you:" banner that will visually sit above the user's next
  # message. Uses the current time (Stop time) -- close enough to when the
  # user will type next, and ensures the label appears *before* the message.
  local you_banner
  you_banner="$(format_banner "$theme" "$time_str" "$date_str" "$show_date" "you")"

  # Combine into a single systemMessage line.
  local banner="${claude_banner} ${you_banner}"

  # Output systemMessage
  jq -n --arg msg "$banner" '{"systemMessage": $msg}'
}

main
exit 0
