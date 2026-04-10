# Feature: cc-timestamps - Message Timestamp Plugin for Claude Code

## Feature Description
A Claude Code plugin that displays timestamps for every message exchanged between the user and Claude. The plugin hooks into `UserPromptSubmit` and `Stop` events to inject formatted timestamp lines into the conversation. It supports configurable time/date formats, retro IM-style visual themes, duration tracking between messages, and session statistics (average response time, message count, session duration). Configuration is managed via a simple JSON file in the project's `.claude/` directory.

## User Story
As a Claude Code user
I want to see timestamps on every message in my conversation
So that I can track when messages were sent, how long responses take, and get a sense of pacing during long coding sessions

## Problem Statement
Claude Code conversations have no visible timestamps. During long sessions, users lose track of when exchanges happened, how long Claude took to respond, and overall session duration. This makes it hard to gauge productivity, identify slow responses, or simply know what time it is without switching context.

## Solution Statement
Build a lightweight Claude Code plugin that uses `UserPromptSubmit` and `Stop` hooks to inject timestamp banners into the conversation via `systemMessage`. The plugin reads a config file (`cc-timestamps.json`) from `.claude/` to let users customize time format, date format, visual style (retro IM theme by default), and toggle optional stats like duration since last message and running session statistics. A `/cc-timestamps:config` skill lets users interactively configure settings, and a `/cc-timestamps:stats` skill displays a full session summary.

## Relevant Files
This is a greenfield plugin. All files are new.

### New Files
- `.claude-plugin/plugin.json` - Plugin manifest (name, version, description, author)
- `hooks/hooks.json` - Hook definitions for UserPromptSubmit and Stop events
- `hooks/on-prompt.sh` - Shell script that fires on UserPromptSubmit, injects timestamp for user message
- `hooks/on-stop.sh` - Shell script that fires on Stop, injects timestamp for assistant response completion
- `hooks/lib.sh` - Shared functions for formatting, config loading, stats tracking
- `skills/config/SKILL.md` - Skill definition for `/cc-timestamps:config` to configure settings
- `skills/stats/SKILL.md` - Skill definition for `/cc-timestamps:stats` to show session statistics
- `defaults.json` - Default configuration shipped with the plugin
- `README.md` - Documentation for the plugin

## Implementation Plan
### Phase 1: Foundation
Set up the plugin skeleton with `.claude-plugin/plugin.json`, `hooks/hooks.json`, and the default configuration. Establish the shared library (`hooks/lib.sh`) that handles:
- Loading config from `${CLAUDE_PROJECT_DIR}/.claude/cc-timestamps.json` with fallback to `${CLAUDE_PLUGIN_ROOT}/defaults.json`
- Time/date formatting with configurable format strings
- State file management for tracking message timestamps in `${CLAUDE_PLUGIN_DATA}/session-state.json`
- Visual formatting functions for the retro IM theme and other styles

### Phase 2: Core Implementation
Implement the two main hooks:
- `on-prompt.sh`: Reads stdin JSON, records timestamp, formats a user message timestamp banner, writes state, outputs `systemMessage` JSON
- `on-stop.sh`: Reads stdin JSON, calculates duration since last user prompt, formats an assistant completion timestamp banner with optional duration, updates stats, outputs `systemMessage` JSON
- Both hooks read configuration and apply the selected visual theme and format options

### Phase 3: Integration
Add the two skills:
- `/cc-timestamps:config` - A skill that instructs Claude to read the current config, present options, and write updates to `.claude/cc-timestamps.json`
- `/cc-timestamps:stats` - A skill that instructs Claude to read session state and display message counts, average response times, session duration, and a timeline

## Step by Step Tasks

### Step 1: Create plugin manifest
- Create `.claude-plugin/plugin.json` with name `cc-timestamps`, version `1.0.0`, description, and author fields
- Follow the exact format used by official Claude Code plugins

### Step 2: Create default configuration
- Create `defaults.json` with all configurable options and sensible defaults:
  - `time_format`: `"%-I:%M %p"` (e.g., "2:30 PM")
  - `date_format`: `"%b %d"` (e.g., "Apr 10")
  - `show_date`: `true` (show date alongside time)
  - `show_duration`: `true` (show time elapsed since last message)
  - `show_stats`: `false` (show running stats like msg count, avg response time)
  - `theme`: `"retro-im"` (visual style for timestamp banners)
  - Available themes: `"retro-im"`, `"minimal"`, `"boxed"`, `"plain"`

### Step 3: Create shared library (hooks/lib.sh)
- Implement `load_config()` - loads from project `.claude/cc-timestamps.json`, falls back to `defaults.json`
- Implement `format_time()` - formats current time using configured format
- Implement `format_date()` - formats current date using configured format
- Implement `read_state()` - reads session state from `${CLAUDE_PLUGIN_DATA}/session-state.json`
- Implement `write_state()` - writes/updates session state (last timestamp, message count, cumulative duration)
- Implement `calc_duration()` - calculates human-readable duration between two epoch timestamps
- Implement `format_banner()` - applies the selected theme to produce the final timestamp string
  - `retro-im` theme: `[2:30 PM] user:` or `[2:30 PM] claude:` with dotted separators
  - `minimal` theme: `-- 2:30 PM --`
  - `boxed` theme: `+-- 2:30 PM Apr 10 --+`
  - `plain` theme: `2:30 PM`

### Step 4: Create UserPromptSubmit hook (hooks/on-prompt.sh)
- Read hook input JSON from stdin
- Source `lib.sh` for shared functions
- Load config, record current epoch timestamp in state
- Format the timestamp banner for the user's message
- Output JSON with `systemMessage` containing the formatted timestamp
- Exit 0

### Step 5: Create Stop hook (hooks/on-stop.sh)
- Read hook input JSON from stdin
- Source `lib.sh` for shared functions
- Load config and read state (last user prompt timestamp)
- Calculate duration since user's prompt if `show_duration` is enabled
- Update running stats (increment message pair count, accumulate total duration)
- Format the timestamp banner for Claude's response completion
- Include duration (e.g., "(took 45s)") and optional stats if configured
- Output JSON with `systemMessage` containing the formatted timestamp
- Exit 0

### Step 6: Create hooks.json
- Define `UserPromptSubmit` hook pointing to `on-prompt.sh`
- Define `Stop` hook pointing to `on-stop.sh`
- Use `${CLAUDE_PLUGIN_ROOT}` for paths
- Set reasonable timeouts (5s)

### Step 7: Create /cc-timestamps:config skill
- Create `skills/config/SKILL.md` with instructions for Claude to:
  - Read current config from `.claude/cc-timestamps.json` (or show defaults)
  - Present available options with current values
  - Accept user changes and write updated config
  - Show available themes with visual previews

### Step 8: Create /cc-timestamps:stats skill
- Create `skills/stats/SKILL.md` with instructions for Claude to:
  - Read `${CLAUDE_PLUGIN_DATA}/session-state.json`
  - Display session start time, message count, total duration, average response time
  - Show a simple text-based timeline of message exchanges

### Step 9: Create README.md
- Document installation, configuration options, available themes, skills, and examples
- Include visual examples of each theme

### Step 10: Validate the plugin
- Run `cat .claude-plugin/plugin.json | jq .` to validate JSON
- Run `cat hooks/hooks.json | jq .` to validate JSON
- Run `cat defaults.json | jq .` to validate JSON
- Run `bash -n hooks/on-prompt.sh` to syntax-check the hook script
- Run `bash -n hooks/on-stop.sh` to syntax-check the hook script
- Run `bash -n hooks/lib.sh` to syntax-check the shared library
- Test `on-prompt.sh` with mock stdin: `echo '{"session_id":"test","transcript_path":"/tmp/test.jsonl"}' | bash hooks/on-prompt.sh`
- Test `on-stop.sh` with mock stdin: `echo '{"session_id":"test","transcript_path":"/tmp/test.jsonl"}' | bash hooks/on-stop.sh`
- Verify both produce valid JSON output via `| jq .`

## Testing Strategy
### Unit Tests
- Test `lib.sh` functions in isolation: `format_time`, `format_date`, `calc_duration`, `format_banner` for each theme
- Test config loading with and without a project-level config file
- Test state file read/write with missing, empty, and populated state files

### Integration Tests
- Pipe mock hook input JSON through `on-prompt.sh` and verify valid JSON output with `systemMessage`
- Pipe mock hook input JSON through `on-stop.sh` and verify valid JSON output with `systemMessage` and duration
- Test with different config overrides (each theme, toggling show_date/show_duration/show_stats)
- Test state accumulation across multiple simulated prompt/stop cycles

### Edge Cases
- First message in session (no prior state, no duration to calculate)
- Missing or malformed config file (should fall back to defaults gracefully)
- Missing `CLAUDE_PLUGIN_DATA` directory (should create it)
- Very long durations (hours) formatted correctly
- Sub-second durations displayed as "<1s"
- Concurrent sessions (state keyed by session_id)

## Acceptance Criteria
- Plugin installs and activates without errors when loaded via `claude --plugin-dir`
- Every user prompt shows a formatted timestamp banner as a system message
- Every Claude response completion shows a timestamp banner with optional duration
- The retro-im theme displays `[2:30 PM] user:` and `[2:30 PM] claude:` style banners
- All four themes (retro-im, minimal, boxed, plain) render correctly
- Configuration file in `.claude/cc-timestamps.json` overrides defaults
- `/cc-timestamps:config` skill allows interactive configuration
- `/cc-timestamps:stats` skill displays session statistics
- Duration calculations are accurate (within 1s)
- Hook scripts exit 0 on success and handle errors gracefully (no blocking)
- All JSON output is valid and parseable by `jq`
- No external dependencies beyond bash, jq, and date (standard macOS/Linux tools)

## Validation Commands
Execute every command to validate the feature works correctly with zero regressions.

- `cd /Users/seannam/Developer/cc-timestamps && cat .claude-plugin/plugin.json | jq .` - Validate plugin manifest JSON
- `cd /Users/seannam/Developer/cc-timestamps && cat hooks/hooks.json | jq .` - Validate hooks definition JSON
- `cd /Users/seannam/Developer/cc-timestamps && cat defaults.json | jq .` - Validate defaults JSON
- `cd /Users/seannam/Developer/cc-timestamps && bash -n hooks/lib.sh` - Syntax-check shared library
- `cd /Users/seannam/Developer/cc-timestamps && bash -n hooks/on-prompt.sh` - Syntax-check prompt hook
- `cd /Users/seannam/Developer/cc-timestamps && bash -n hooks/on-stop.sh` - Syntax-check stop hook
- `cd /Users/seannam/Developer/cc-timestamps && mkdir -p /tmp/cc-timestamps-test && echo '{"session_id":"test123","transcript_path":"/tmp/test.jsonl","cwd":"/tmp"}' | CLAUDE_PLUGIN_ROOT="$(pwd)" CLAUDE_PLUGIN_DATA="/tmp/cc-timestamps-test" bash hooks/on-prompt.sh | jq .` - Test prompt hook produces valid JSON
- `cd /Users/seannam/Developer/cc-timestamps && echo '{"session_id":"test123","transcript_path":"/tmp/test.jsonl","cwd":"/tmp"}' | CLAUDE_PLUGIN_ROOT="$(pwd)" CLAUDE_PLUGIN_DATA="/tmp/cc-timestamps-test" bash hooks/on-stop.sh | jq .` - Test stop hook produces valid JSON with duration
- `cd /Users/seannam/Developer/cc-timestamps && rm -rf /tmp/cc-timestamps-test` - Clean up test artifacts

## Notes
- The plugin uses only bash, jq, and date -- no Python, Node, or other runtime dependencies. This keeps it maximally portable across macOS and Linux.
- `jq` is required but is pre-installed on most developer machines and available via Homebrew/apt.
- State files are stored in `${CLAUDE_PLUGIN_DATA}` (managed by Claude Code) to avoid polluting the user's project directory.
- Configuration lives in `.claude/cc-timestamps.json` in the project directory, following the convention used by other plugins (e.g., hookify uses `.claude/hookify.*.local.md`).
- The retro-im theme is inspired by classic AIM/ICQ/IRC timestamp formatting for a nostalgic developer experience.
- Future enhancements could include: color support (ANSI escape codes in systemMessage), per-tool-use timestamps, and a web dashboard via an MCP server.
