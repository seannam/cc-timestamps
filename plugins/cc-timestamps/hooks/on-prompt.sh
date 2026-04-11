#!/bin/bash
# on-prompt.sh - UserPromptSubmit hook for cc-timestamps
# State-only: records the prompt epoch for duration tracking in the Stop hook.
# No visible banner is emitted here -- the Stop hook renders both the "claude:"
# and "you:" timestamps so the "you:" label visually sits above the next
# user message instead of below the current one.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

main() {
  # Read hook input from stdin
  local input
  input="$(cat)"

  local session_id
  session_id="$(echo "$input" | jq -r '.session_id // "default"')"

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

  # No visible output -- emit empty JSON so Claude Code shows nothing.
  echo '{}'
}

main
exit 0
