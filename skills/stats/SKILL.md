---
description: Show session timestamp statistics and message timeline
---

# Session Statistics

Display statistics about the current Claude Code session's message timing.

## Steps

1. Read the session state file from `${CLAUDE_PLUGIN_DATA}/`. List files matching `state-*.json` to find active sessions.
2. For each session state file found, read the JSON and extract:
   - `session_start` - epoch when the session began
   - `msg_count` - number of completed message exchanges
   - `total_duration` - cumulative response time in seconds
   - `last_prompt_epoch` - when the last user prompt was sent
3. Calculate and display:
   - **Session start**: formatted timestamp
   - **Session duration**: time from start to now
   - **Messages exchanged**: count of prompt/response pairs
   - **Total response time**: cumulative time Claude spent responding
   - **Average response time**: total_duration / msg_count
   - **Time since last message**: now - last_prompt_epoch
4. Present the stats in a clean format:

```
Session Statistics
==================
Started:          2:15 PM Apr 10
Duration:         1h 23m
Messages:         12 exchanges
Total think time: 4m 32s
Avg response:     22s
Last activity:    3m ago
```

5. If no state files are found, inform the user that no session data is available yet (timestamps begin tracking when the plugin is active).
