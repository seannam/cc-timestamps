---
description: Configure cc-timestamps settings (theme, time format, toggles)
---

# Configure cc-timestamps

Read the current cc-timestamps configuration and help the user update it.

## Steps

1. Read the defaults from `${CLAUDE_PLUGIN_ROOT}/defaults.json`.
2. Check if a project override exists at `.claude/cc-timestamps.json` in the current project directory. If it does, read it.
3. Present the current effective settings in a table:

| Setting        | Value           | Description                              |
|----------------|-----------------|------------------------------------------|
| `theme`        | retro-im        | Visual style (retro-im, minimal, boxed, plain) |
| `time_format`  | %-I:%M %p       | strftime format for time                 |
| `date_format`  | %b %d           | strftime format for date                 |
| `show_date`    | true            | Show date alongside time                 |
| `show_duration`| true            | Show response duration                   |
| `show_stats`   | false           | Show running session statistics          |

4. Show a preview of each theme:

```
retro-im:   ........................................
            [2:30 PM Apr 10] you:

minimal:    -- 2:30 PM Apr 10 | you --

boxed:      +----------------------------+
            |  2:30 PM Apr 10 | you  |
            +----------------------------+

plain:      2:30 PM Apr 10 you
```

5. Ask the user what they'd like to change.
6. Write the updated config to `.claude/cc-timestamps.json` (create `.claude/` directory if needed).
7. Confirm the changes were saved.
