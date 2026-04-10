# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code plugin marketplace containing the **cc-timestamps** plugin, which injects timestamp banners into every message exchange via `UserPromptSubmit` and `Stop` hooks. It supports four visual themes (retro-im, minimal, boxed, plain), configurable time/date formats, duration tracking, and session statistics.

## Repository Structure

This repo uses the Claude Code plugin marketplace layout:

- `.claude-plugin/marketplace.json` -- marketplace manifest listing available plugins
- `plugins/cc-timestamps/` -- the actual plugin directory
  - `.claude-plugin/plugin.json` -- plugin manifest
  - `hooks/hooks.json` -- hook definitions (UserPromptSubmit, Stop)
  - `hooks/lib.sh` -- shared library (config, formatting, state, themes)
  - `hooks/on-prompt.sh` -- fires on user prompt, injects timestamp banner
  - `hooks/on-stop.sh` -- fires on Claude response, injects timestamp + duration
  - `defaults.json` -- default configuration
  - `skills/config/SKILL.md` -- `/cc-timestamps:config` skill definition
  - `skills/stats/SKILL.md` -- `/cc-timestamps:stats` skill definition
- `specs/` -- feature specifications

## Key Architecture Details

- All logic is in bash scripts (`hooks/lib.sh`, `on-prompt.sh`, `on-stop.sh`). No Python, Node, or other runtimes -- only `bash`, `jq`, and `date`.
- Config loading merges `defaults.json` with an optional project-level override at `.claude/cc-timestamps.json` using `jq -s '.[0] * .[1]'`.
- Session state (message count, total duration, timestamps) is persisted to `${CLAUDE_PLUGIN_DATA}/state-${session_id}.json`, keyed by session ID to support concurrent sessions.
- Hooks communicate back to Claude Code by outputting JSON with a `systemMessage` key to stdout.
- All scripts use `set -euo pipefail`.

## Validation Commands

```bash
# Validate all JSON files
jq . plugins/cc-timestamps/.claude-plugin/plugin.json
jq . plugins/cc-timestamps/hooks/hooks.json
jq . plugins/cc-timestamps/defaults.json

# Syntax-check all bash scripts
bash -n plugins/cc-timestamps/hooks/lib.sh
bash -n plugins/cc-timestamps/hooks/on-prompt.sh
bash -n plugins/cc-timestamps/hooks/on-stop.sh

# Integration test: prompt hook
mkdir -p /tmp/cc-timestamps-test
echo '{"session_id":"test123","transcript_path":"/tmp/test.jsonl","cwd":"/tmp"}' | \
  CLAUDE_PLUGIN_ROOT=plugins/cc-timestamps CLAUDE_PLUGIN_DATA=/tmp/cc-timestamps-test \
  bash plugins/cc-timestamps/hooks/on-prompt.sh | jq .

# Integration test: stop hook
echo '{"session_id":"test123","transcript_path":"/tmp/test.jsonl","cwd":"/tmp"}' | \
  CLAUDE_PLUGIN_ROOT=plugins/cc-timestamps CLAUDE_PLUGIN_DATA=/tmp/cc-timestamps-test \
  bash plugins/cc-timestamps/hooks/on-stop.sh | jq .

# Cleanup
rm -rf /tmp/cc-timestamps-test
```

## Environment Variables

Hook scripts depend on these Claude Code-provided variables:

- `CLAUDE_PLUGIN_ROOT` -- path to the plugin directory (used to find `defaults.json` and `lib.sh`)
- `CLAUDE_PLUGIN_DATA` -- writable data directory for session state files
- `CLAUDE_PROJECT_DIR` -- user's project directory (used to find `.claude/cc-timestamps.json` config override)
