# cc-timestamps

A Claude Code plugin that displays timestamps on every message, with retro IM styling, duration tracking, and session statistics.

## Installation

```bash
claude install-plugin /path/to/cc-timestamps
```

Or during development:

```bash
claude --plugin-dir /path/to/cc-timestamps
```

## What It Does

Every time you send a message, a timestamp banner appears:

```
........................................
[2:30 PM Apr 10] you:
```

When Claude finishes responding, another banner shows with the response duration:

```
........................................
[2:31 PM Apr 10] claude: (took 45s)
```

## Themes

Four visual themes are available:

### retro-im (default)
```
........................................
[2:30 PM Apr 10] you:
```

### minimal
```
-- 2:30 PM Apr 10 | you --
```

### boxed
```
+----------------------------+
|  2:30 PM Apr 10 | you  |
+----------------------------+
```

### plain
```
2:30 PM Apr 10 you
```

## Configuration

Create `.claude/cc-timestamps.json` in your project directory to override defaults:

```json
{
  "theme": "retro-im",
  "time_format": "%-I:%M %p",
  "date_format": "%b %d",
  "show_date": true,
  "show_duration": true,
  "show_stats": false
}
```

Or use the `/cc-timestamps:config` skill to configure interactively.

### Options

| Option          | Default      | Description                                      |
|-----------------|--------------|--------------------------------------------------|
| `theme`         | `retro-im`   | Visual style: `retro-im`, `minimal`, `boxed`, `plain` |
| `time_format`   | `%-I:%M %p`  | `strftime` format string for time                |
| `date_format`   | `%b %d`      | `strftime` format string for date                |
| `show_date`     | `true`       | Show date alongside time in banners              |
| `show_duration` | `true`       | Show how long Claude took to respond             |
| `show_stats`    | `false`      | Show running stats (message count, avg time)     |

### Time Format Examples

| Format       | Output        |
|--------------|---------------|
| `%-I:%M %p`  | 2:30 PM       |
| `%H:%M`      | 14:30         |
| `%H:%M:%S`   | 14:30:05      |
| `%-I:%M:%S %p` | 2:30:05 PM |

## Skills

### /cc-timestamps:config
Interactively configure plugin settings. Shows current values, theme previews, and writes changes to `.claude/cc-timestamps.json`.

### /cc-timestamps:stats
Display session statistics: message count, average response time, session duration, and time since last activity.

## Session Statistics

When `show_stats` is enabled, each response banner includes running stats:

```
........................................
[2:31 PM Apr 10] claude: (took 45s)
[#12 | avg: 22s | session: 1h 23m]
```

## Dependencies

- `bash` (4.0+)
- `jq`
- `date` (GNU or BSD)

No Python, Node, or other runtime required.

## License

MIT
