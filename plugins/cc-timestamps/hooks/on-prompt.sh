#!/bin/bash
# on-prompt.sh - UserPromptSubmit hook for cc-timestamps
# Injects a timestamp banner when the user sends a message.

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

  local time_fmt date_fmt show_date theme
  time_fmt="$(cfg_get time_format "$config")"
  date_fmt="$(cfg_get date_format "$config")"
  show_date="$(cfg_get show_date "$config")"
  theme="$(cfg_get theme "$config")"

  # Format current time
  local time_str date_str
  time_str="$(format_time "$time_fmt")"
  date_str="$(format_date "$date_fmt")"

  # Record prompt timestamp in state
  local epoch
  epoch="$(now_epoch)"
  local state
  state="$(read_state "$session_id")"

  local msg_count session_start total_duration
  msg_count="$(echo "$state" | jq -r '.msg_count // 0')"
  session_start="$(echo "$state" | jq -r '.session_start // 0')"
  total_duration="$(echo "$state" | jq -r '.total_duration // 0')"

  # Initialize session start on first message
  if (( session_start == 0 )); then
    session_start="$epoch"
  fi

  local new_state
  new_state="$(jq -n \
    --argjson msg_count "$msg_count" \
    --argjson total_duration "$total_duration" \
    --argjson session_start "$session_start" \
    --argjson last_prompt_epoch "$epoch" \
    '{msg_count: $msg_count, total_duration: $total_duration, session_start: $session_start, last_prompt_epoch: $last_prompt_epoch}'
  )"
  write_state "$session_id" "$new_state"

  # Build banner
  local banner
  banner="$(format_banner "$theme" "$time_str" "$date_str" "$show_date" "you")"

  # Output systemMessage
  jq -n --arg msg "$banner" '{"systemMessage": $msg}'
}

main
exit 0
