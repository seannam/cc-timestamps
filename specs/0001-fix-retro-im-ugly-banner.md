# Bug: Timestamps appear after messages instead of before them

## Bug Description
Two issues with the current timestamp rendering:

1. **Ugly output**: The default `retro-im` theme produces a multi-line banner (dots on line 1, timestamp on line 2). When Claude Code renders it, the dots appear inline with `UserPromptSubmit says:`, looking like broken/garbled output.

2. **Wrong position**: The `UserPromptSubmit` hook fires after the user submits, so the "you:" timestamp appears *below* the user's message. The user wants timestamps *before* messages -- like classic IM clients where `[7:50 PM] sean:` labels the message from above.

**Current rendering:**
```
> user's message text
└ UserPromptSubmit says: ........................................
    [7:50 PM Apr 10] you:
... Claude's response ...
└ Stop says: ........................................
    [7:51 PM Apr 10] claude: (took 45s)
```

**Expected rendering:**
```
└ Stop says: [7:50 PM Apr 10] you: ... [7:51 PM Apr 10] claude: (took 45s)
> next user's message text
```

## Problem Statement
There is no "before prompt" hook in Claude Code. `UserPromptSubmit` fires on submission, so its output always renders after the user's text. To get a timestamp that visually appears before the next user message, it must be output by the `Stop` hook at the end of the previous exchange.

Additionally, multi-line theme formats (retro-im dots, boxed borders) look broken when rendered inline with Claude Code's `... says:` prefix.

## Solution Statement
1. **Move the "you:" timestamp into the `Stop` hook.** The Stop hook fires after Claude responds, and its output appears right before the user types their next message. Output both the "claude:" timestamp and a "you:" timestamp from `Stop`, so the visual flow becomes: `claude timestamp` + `you timestamp` then the user's next message appears below it.
2. **Make `UserPromptSubmit` silent (state-only).** It still records the prompt epoch for duration tracking but outputs no visible banner -- or outputs an empty/minimal systemMessage.
3. **Fix multi-line themes.** All themes must produce single-line output so they render cleanly after the `... says:` prefix.

## Steps to Reproduce
1. Install the cc-timestamps plugin with default config (theme: `retro-im`).
2. Start a Claude Code session.
3. Send any message.
4. Observe the `UserPromptSubmit says:` output -- dots on first line, timestamp on second line, positioned *after* the user's message.

Reproduction command:
```bash
mkdir -p /tmp/cc-timestamps-test
echo '{"session_id":"test123","transcript_path":"/tmp/test.jsonl","cwd":"/tmp"}' | \
  CLAUDE_PLUGIN_ROOT=plugins/cc-timestamps CLAUDE_PLUGIN_DATA=/tmp/cc-timestamps-test \
  bash plugins/cc-timestamps/hooks/on-prompt.sh | jq -r .systemMessage
```

Current output:
```
........................................
[7:50 PM Apr 10] you:
```

## Root Cause Analysis
**Position issue:** The architecture outputs the "you:" timestamp from `UserPromptSubmit`, which fires after the user submits their prompt. Claude Code renders this output below the user's message text. There is no hook that fires before the prompt is displayed, so the only way to have a timestamp appear visually above the user's next message is to output it from the `Stop` hook of the previous exchange.

**Ugly output issue:** In `plugins/cc-timestamps/hooks/lib.sh`, the `format_banner` function's `retro-im` case (line 148-150) outputs a two-line string starting with dots. Claude Code prefixes `UserPromptSubmit says:` to the first line, making the dots the most prominent visual element while the timestamp is relegated to an indented second line.

## Relevant Files
Use these files to fix the bug:

- `plugins/cc-timestamps/hooks/on-prompt.sh` -- Currently outputs the "you:" banner. Needs to be changed to state-only (record prompt epoch, no visible banner).
- `plugins/cc-timestamps/hooks/on-stop.sh` -- Currently outputs just the "claude:" banner. Needs to be changed to output both the "claude:" timestamp and the "you:" timestamp so the label appears before the next user message.
- `plugins/cc-timestamps/hooks/lib.sh` -- Contains `format_banner` function. All themes need to produce single-line output. The retro-im dots and boxed multi-line borders must be removed/redesigned.
- `plugins/cc-timestamps/defaults.json` -- Default config reference. No changes needed.

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

### 1. Fix all themes to single-line format in lib.sh
- Edit `format_banner()` in `plugins/cc-timestamps/hooks/lib.sh`.
- **retro-im** (line 148-150): Change from `........\n[timestamp] role:` to `[${timestamp}] ${role}:${suffix}`. Drop the dots. The bracketed timestamp + colon already evokes classic IM/IRC.
- **boxed** (lines 155-158): Change from 3-line box to single-line `[ ${timestamp} | ${role}${suffix} ]`.
- **fallback `*` case** (lines 163-166): Update to match the new retro-im format.
- **minimal** and **plain**: Already single-line, no changes needed.
- Stats line (`stats_line`), if present, can remain appended with a space separator (not a newline) to keep everything single-line.

### 2. Make UserPromptSubmit (on-prompt.sh) state-only
- Edit `plugins/cc-timestamps/hooks/on-prompt.sh`.
- Keep the state recording logic (reading input, saving `last_prompt_epoch` to state file).
- Remove the banner generation and the `jq -n --arg msg "$banner" '{"systemMessage": $msg}'` output.
- Output an empty JSON object `{}` (or omit `systemMessage`) so Claude Code shows nothing for this hook.

### 3. Add "you:" timestamp to Stop hook (on-stop.sh)
- Edit `plugins/cc-timestamps/hooks/on-stop.sh`.
- After building the existing "claude" banner, also build a "you" banner using `format_banner` with role `"you"` and the current time (the time at Stop, which is close enough to when the user will type next).
- Combine both into the systemMessage: `"${claude_banner} ${you_banner}"` -- a single-line output with both timestamps. This way the Stop hook output reads like: `[7:51 PM Apr 10] claude: (took 45s) [7:51 PM Apr 10] you:`
- The "you:" label will visually sit right above where the user types their next message.

### 4. Run validation commands
- Run all validation commands to confirm no syntax errors or regressions.
- Run integration tests to verify the new output format.

## Validation Commands
Execute every command to validate the bug is fixed with zero regressions.

```bash
# Syntax-check all bash scripts
bash -n plugins/cc-timestamps/hooks/lib.sh
bash -n plugins/cc-timestamps/hooks/on-prompt.sh
bash -n plugins/cc-timestamps/hooks/on-stop.sh

# Validate all JSON files
jq . plugins/cc-timestamps/.claude-plugin/plugin.json
jq . plugins/cc-timestamps/hooks/hooks.json
jq . plugins/cc-timestamps/defaults.json

# Integration test: prompt hook -- should output empty/no systemMessage
mkdir -p /tmp/cc-timestamps-test
echo '{"session_id":"test-fix","transcript_path":"/tmp/test.jsonl","cwd":"/tmp"}' | \
  CLAUDE_PLUGIN_ROOT=plugins/cc-timestamps CLAUDE_PLUGIN_DATA=/tmp/cc-timestamps-test \
  bash plugins/cc-timestamps/hooks/on-prompt.sh
# Expected: {} or {"systemMessage": ""} -- no visible banner

# Integration test: stop hook -- should output both claude and you timestamps
echo '{"session_id":"test-fix","transcript_path":"/tmp/test.jsonl","cwd":"/tmp"}' | \
  CLAUDE_PLUGIN_ROOT=plugins/cc-timestamps CLAUDE_PLUGIN_DATA=/tmp/cc-timestamps-test \
  bash plugins/cc-timestamps/hooks/on-stop.sh | jq -r .systemMessage
# Expected: single line with both [timestamp] claude: and [timestamp] you:

# Verify all themes produce single-line output
CLAUDE_PLUGIN_ROOT=plugins/cc-timestamps CLAUDE_PLUGIN_DATA=/tmp/cc-timestamps-test \
  bash -c '
    source plugins/cc-timestamps/hooks/lib.sh
    for theme in retro-im minimal boxed plain; do
      echo "=== $theme ==="
      output=$(format_banner "$theme" "7:50 PM" "Apr 10" "true" "you" "3s" "[#5 | avg: 4s]")
      line_count=$(echo "$output" | wc -l)
      echo "$output"
      echo "(lines: $line_count)"
      echo ""
    done
  '

# Cleanup
rm -rf /tmp/cc-timestamps-test
```

## Notes
- No new libraries or dependencies required.
- The "you:" timestamp from `Stop` will show the time Claude finished responding, not the exact time the user starts typing. This is a small inaccuracy but acceptable since the alternative (showing it after the message) defeats the purpose entirely.
- On the very first message of a session, there is no prior `Stop` hook, so there will be no "you:" label above it. This is fine -- the first message is self-evident.
- The `UserPromptSubmit` hook is still needed for state management (recording `last_prompt_epoch` for duration calculation). It just no longer outputs a visible banner.
