# CLI Interface Contract: tmux-ls

**Feature**: 001-tmux-ls-cli
**Date**: 2025-11-17
**Phase**: 1 - Design & Contracts

## Overview

This document defines the command-line interface contract for tmux-ls, including all commands, flags, arguments, exit codes, and output formats. This contract serves as the API specification for the CLI tool.

---

## Command Structure

```
tmux-ls [GLOBAL_OPTIONS] [COMMAND] [COMMAND_OPTIONS] [ARGUMENTS]
```

---

## Global Options

These options apply to all commands and must appear before the command.

| Option | Short | Type | Default | Description |
|--------|-------|------|---------|-------------|
| `--version` | `-v` | Flag | N/A | Display version information and exit |
| `--help` | `-h` | Flag | N/A | Display help message and exit |
| `--config` | `-c` | Path | `~/.config/tmux-ls/config.yml` | Use alternate configuration file |
| `--debug` | `-d` | Flag | false | Enable debug output to stderr |
| `--no-color` | | Flag | false | Disable colored output (for non-TTY or accessibility) |

### Examples

```bash
# Show version
tmux-ls --version
# Output: tmux-ls v1.0.0 (commit abc1234, built 2025-11-17)

# Show help
tmux-ls --help
# Output: [Full help message with all commands]

# Use custom config
tmux-ls --config /tmp/test-config.yml

# Debug mode
tmux-ls --debug
# Output includes: [DEBUG] Loading config from ~/.config/tmux-ls/config.yml
#                  [DEBUG] Found 5 active sessions
```

---

## Commands

### Default Command (Interactive Mode)

**Invocation**: `tmux-ls` (no command specified)

**Description**: Launch interactive session manager with full menu.

**Behavior**:
1. Detect if running inside tmux (`$TMUX` environment variable)
   - If inside tmux → Launch quick switcher mode (see User Story 3)
   - If outside tmux → Launch full menu mode (see User Story 1)
2. Display session list with metadata (name, windows, uptime, status)
3. Allow user to select action: attach, create new, workspace, actions, config

**Exit Codes**:
- `0`: User successfully attached to session or exited normally
- `1`: tmux server not running or other error
- `2`: User cancelled operation (ESC pressed)
- `130`: SIGINT (Ctrl+C)

**Output**:
- Interactive UI via gum (or bash select fallback)
- Minimal stdout (only final action confirmation)
- Errors to stderr

**Example Session**:
```bash
$ tmux-ls

╭─────────────────────────────────────────────╮
│ tmux-ls - Mission Control                  │
│ 5 active sessions                           │
├─────────────────────────────────────────────┤
│ > dev-api          (3 windows, 2h uptime)  │
│   staging          (1 window, 30m uptime)  │
│   test-suite       (2 windows, 5m uptime)  │
│ ─────────────────────────────────────────── │
│   📝 New tmux session                       │
│   🚀 New Workspace                          │
│   ⚙️  Actions                               │
│   🔧 Configuration                          │
╰─────────────────────────────────────────────╯

[User selects "dev-api"]
✓ Attached to session 'dev-api'
```

---

### `config init`

**Invocation**: `tmux-ls config init [OPTIONS]`

**Description**: Generate default configuration file at `~/.config/tmux-ls/config.yml`.

**Options**:
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--force` | Flag | false | Overwrite existing config file |
| `--minimal` | Flag | false | Create minimal config (no comments/defaults) |

**Behavior**:
1. Check if config file exists
   - If exists and no `--force`: Error and exit
   - If exists and `--force`: Backup old config to `.bak` and create new
2. Create `~/.config/tmux-ls/` directory if needed
3. Write default config with inline comments explaining each option

**Exit Codes**:
- `0`: Config created successfully
- `1`: Config already exists (without --force)
- `2`: Permission error (can't write to config directory)

**Output**:
```bash
$ tmux-ls config init
✓ Created default configuration at ~/.config/tmux-ls/config.yml
  Edit this file to customize tmux-ls behavior.

$ tmux-ls config init
✗ Configuration already exists at ~/.config/tmux-ls/config.yml
  Use --force to overwrite.

$ tmux-ls config init --force
⚠  Backed up existing config to ~/.config/tmux-ls/config.yml.bak
✓ Created fresh configuration at ~/.config/tmux-ls/config.yml
```

---

### `config validate`

**Invocation**: `tmux-ls config validate [FILE]`

**Description**: Validate configuration file syntax and values.

**Arguments**:
- `FILE` (optional): Path to config file (default: `~/.config/tmux-ls/config.yml`)

**Behavior**:
1. Parse YAML file
2. Check for required keys
3. Validate value types and ranges
4. Report errors with line numbers

**Exit Codes**:
- `0`: Config is valid
- `1`: Config has errors

**Output**:
```bash
$ tmux-ls config validate
✓ Configuration is valid
  All required fields present and correct.

$ tmux-ls config validate ~/.config/tmux-ls/config.yml
✗ Configuration validation failed:
  - Line 12: Invalid value for 'cleanup.stale_threshold_minutes' (must be > 0)
  - Line 25: Unknown key 'ui.invalid_option'
  2 errors found.
```

---

### `config show`

**Invocation**: `tmux-ls config show [OPTIONS]`

**Description**: Display current effective configuration (merged defaults + user config).

**Options**:
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--format` | String | "yaml" | Output format: yaml, json, table |

**Exit Codes**:
- `0`: Success
- `1`: Config file has errors

**Output**:
```bash
$ tmux-ls config show
version: "1.0"
ui:
  theme: "charm"
  colors:
    primary: "#00D9FF"
    success: "#00FF00"
...

$ tmux-ls config show --format json
{
  "version": "1.0",
  "ui": {
    "theme": "charm",
    ...
  }
}

$ tmux-ls config show --format table
Key                               | Value
----------------------------------|----------
ui.theme                          | charm
ui.colors.primary                 | #00D9FF
workspace.default_layout          | grid
...
```

---

### `stats`

**Invocation**: `tmux-ls stats [OPTIONS]`

**Description**: Display local usage statistics (requires telemetry enabled).

**Options**:
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--export` | Path | - | Export stats to JSON file |
| `--clear` | Flag | false | Delete all telemetry data (prompts confirmation) |
| `--since` | Duration | "7d" | Show stats from last N days/hours (e.g., "24h", "30d") |

**Behavior**:
- Query telemetry SQLite database
- Aggregate events by action type
- Calculate most-used sessions, workspace patterns

**Exit Codes**:
- `0`: Success
- `1`: Telemetry disabled (no data to show)
- `2`: Database file not found or corrupted

**Output**:
```bash
$ tmux-ls stats
tmux-ls Usage Statistics (last 7 days)

📊 Total Actions: 142
  - attach:           65 (45.8%)
  - workspace_create: 23 (16.2%)
  - create:           18 (12.7%)
  - switch:           30 (21.1%)
  - kill:              6 (4.2%)

🔥 Most Used Sessions:
  1. dev-api          (35 attaches)
  2. staging          (18 attaches)
  3. test-suite       (12 attaches)

🚀 Workspaces Created: 23
  - grid layout:      15 (65%)
  - horizontal:        5 (22%)
  - vertical:          3 (13%)

$ tmux-ls stats --export stats.json
✓ Exported statistics to stats.json

$ tmux-ls stats --clear
⚠  This will delete all telemetry data.
   Continue? (y/n) y
✓ Deleted 142 events from local database.

$ tmux-ls stats
⚠  Telemetry is disabled.
   Enable it in ~/.config/tmux-ls/config.yml to track usage.
```

---

### `workspace list`

**Invocation**: `tmux-ls workspace list`

**Description**: List all saved workspace templates.

**Exit Codes**:
- `0`: Success
- `1`: No templates found

**Output**:
```bash
$ tmux-ls workspace list
Saved Workspace Templates:

microservices  (4 sessions, grid layout)
  Created: 2025-11-15 14:30
  Sessions: api-gateway, auth-service, user-service, monitoring

fullstack      (3 sessions, horizontal layout)
  Created: 2025-11-10 09:15
  Sessions: backend, frontend, database

Found 2 templates in ~/.config/tmux-ls/workspaces/

$ tmux-ls workspace list
⚠  No workspace templates found.
   Create one via the interactive menu.
```

---

### `workspace create`

**Invocation**: `tmux-ls workspace create <TEMPLATE_NAME>`

**Description**: Instantiate a saved workspace template.

**Arguments**:
- `TEMPLATE_NAME` (required): Name of template to instantiate

**Behavior**:
1. Load template YAML from `~/.config/tmux-ls/workspaces/<TEMPLATE_NAME>.yml`
2. Check if referenced sessions exist
   - If missing: Prompt to create them or cancel
3. Create workspace with specified layout
4. Attach user to workspace

**Exit Codes**:
- `0`: Workspace created and attached
- `1`: Template not found
- `2`: Session creation failed or user cancelled

**Output**:
```bash
$ tmux-ls workspace create microservices
⚠  Session 'auth-service' does not exist. Create it? (y/n) y
✓ Created session 'auth-service'
✓ Created workspace 'microservices' with 4 sessions
  Layout: grid
✓ Attached to workspace

$ tmux-ls workspace create nonexistent
✗ Template 'nonexistent' not found in ~/.config/tmux-ls/workspaces/
  Available templates: microservices, fullstack
```

---

### `workspace delete`

**Invocation**: `tmux-ls workspace delete <TEMPLATE_NAME>`

**Description**: Delete a saved workspace template (not the sessions themselves).

**Arguments**:
- `TEMPLATE_NAME` (required): Name of template to delete

**Options**:
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--force` | Flag | false | Skip confirmation prompt |

**Exit Codes**:
- `0`: Template deleted
- `1`: Template not found
- `2`: User cancelled deletion

**Output**:
```bash
$ tmux-ls workspace delete microservices
⚠  Delete workspace template 'microservices'? (y/n) y
✓ Deleted template 'microservices'
  (Sessions are still active)

$ tmux-ls workspace delete microservices --force
✓ Deleted template 'microservices'
```

---

### `session kill`

**Invocation**: `tmux-ls session kill <SESSION_NAME> [OPTIONS]`

**Description**: Terminate a tmux session by name.

**Arguments**:
- `SESSION_NAME` (required): Name of session to kill

**Options**:
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--force` | Flag | false | Skip confirmation and process check |

**Behavior**:
1. Check if session exists
2. List running processes in session (unless `--force`)
3. Prompt for confirmation (unless `--force`)
4. Kill session via `tmux kill-session`

**Exit Codes**:
- `0`: Session killed successfully
- `1`: Session not found
- `2`: User cancelled

**Output**:
```bash
$ tmux-ls session kill dev-api
Session 'dev-api' has running processes:
  - npm run dev (PID 12345)
  - tail -f logs/app.log (PID 12346)

⚠  Kill session 'dev-api'? (y/n) y
✓ Killed session 'dev-api'

$ tmux-ls session kill dev-api --force
✓ Killed session 'dev-api'

$ tmux-ls session kill nonexistent
✗ Session 'nonexistent' not found.
```

---

### `session rename`

**Invocation**: `tmux-ls session rename <OLD_NAME> <NEW_NAME>`

**Description**: Rename an existing tmux session.

**Arguments**:
- `OLD_NAME` (required): Current session name
- `NEW_NAME` (required): New session name

**Behavior**:
1. Validate old session exists
2. Validate new name format (no spaces, unique)
3. Rename via `tmux rename-session`

**Exit Codes**:
- `0`: Session renamed
- `1`: Old session not found or new name invalid
- `2`: New name already exists

**Output**:
```bash
$ tmux-ls session rename dev-api production-api
✓ Renamed session 'dev-api' → 'production-api'

$ tmux-ls session rename dev-api "invalid name"
✗ Invalid session name: 'invalid name'
  Session names cannot contain spaces.

$ tmux-ls session rename dev-api staging
✗ Session 'staging' already exists.
  Choose a different name.
```

---

### `cleanup`

**Invocation**: `tmux-ls cleanup [OPTIONS]`

**Description**: Find and optionally kill stale sessions (idle with no attached clients).

**Options**:
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--threshold` | Duration | "30m" | Idle time threshold (e.g., "30m", "2h") |
| `--dry-run` | Flag | false | Show stale sessions without killing |
| `--force` | Flag | false | Kill without confirmation |

**Behavior**:
1. Query all sessions via `tmux list-sessions`
2. Filter for sessions with:
   - No attached clients (`#{session_attached}` = 0)
   - Idle time > threshold
3. Display list with metadata
4. Prompt for multi-select kill (unless `--force`)

**Exit Codes**:
- `0`: Cleanup completed (or dry run successful)
- `1`: No stale sessions found
- `2`: User cancelled

**Output**:
```bash
$ tmux-ls cleanup
Found 3 stale sessions (idle > 30m, no clients):

[x] old-test      (idle 2h 15m, 1 window)
[x] temp-session  (idle 45m, 2 windows)
[ ] dev-backup    (idle 35m, 3 windows)

Select sessions to kill (Space to toggle, Enter to confirm):
✓ Killed 2 sessions (freed 3 windows)

$ tmux-ls cleanup --dry-run
Found 3 stale sessions (idle > 30m, no clients):
  - old-test      (idle 2h 15m)
  - temp-session  (idle 45m)
  - dev-backup    (idle 35m)

Run without --dry-run to kill these sessions.

$ tmux-ls cleanup --force
✓ Killed 3 stale sessions (freed 6 windows)

$ tmux-ls cleanup
✓ No stale sessions found.
  All sessions are active or have attached clients.
```

---

## Environment Variables

These variables affect tmux-ls behavior:

| Variable | Description | Default |
|----------|-------------|---------|
| `TMUX` | Set by tmux when running inside a session (used to detect context) | Unset |
| `TMUX_LS_CONFIG` | Override config file location | `~/.config/tmux-ls/config.yml` |
| `TMUX_LS_DEBUG` | Enable debug mode (same as `--debug`) | Unset |
| `NO_COLOR` | Disable colored output (standard env var) | Unset |
| `TERM` | Terminal type (affects gum availability check) | `xterm-256color` |

---

## Exit Codes Reference

| Code | Meaning | When |
|------|---------|------|
| `0` | Success | Operation completed successfully |
| `1` | General error | tmux not running, session not found, config invalid |
| `2` | User cancelled | User pressed ESC or chose not to proceed |
| `3` | Dependency missing | gum not installed (and no fallback possible) |
| `130` | SIGINT | User pressed Ctrl+C |

---

## Output Formats

### Standard Output (stdout)

- **Interactive mode**: Minimal output, only final confirmation messages
- **Non-interactive commands**: Structured output (list, stats, config show)
- **Machine-readable**: JSON format available via `--format json` where applicable

### Error Output (stderr)

- Prefixed with `✗` for errors
- Prefixed with `⚠` for warnings
- Debug messages prefixed with `[DEBUG]` (only with `--debug`)

### Color Scheme (with ANSI codes)

| Element | Color | Code |
|---------|-------|------|
| Success (`✓`) | Green | `\e[32m` |
| Error (`✗`) | Red | `\e[31m` |
| Warning (`⚠`) | Yellow | `\e[33m` |
| Info | Cyan | `\e[36m` |
| Accent | Primary (configurable) | From `ui.colors.primary` |

---

## Accessibility

### Non-TTY Mode

When stdout is not a TTY (e.g., piped to another command):
- Disable gum interactive components
- Fall back to plain text output
- No ANSI color codes (unless forced)

```bash
$ tmux-ls | tee log.txt
# Output will be plain text, no colors

$ tmux-ls --color | tee log.txt
# Force colors even when piped
```

### Screen Reader Compatibility

- Use `--no-color` to disable visual formatting
- Provide plain text alternatives for icons
- All interactive prompts have keyboard-only navigation

---

## Version Negotiation

The `--version` output includes machine-readable format for scripting:

```bash
$ tmux-ls --version
tmux-ls v1.0.0 (commit abc1234, built 2025-11-17)

$ tmux-ls --version --format json
{
  "version": "1.0.0",
  "commit": "abc1234",
  "build_date": "2025-11-17",
  "tmux_min_version": "2.6"
}
```

---

## Backwards Compatibility

### Semantic Versioning Guarantees

- **Major version** (1.x.x → 2.x.x): CLI interface may break, config format may change
- **Minor version** (1.0.x → 1.1.x): New commands/options added, backward compatible
- **Patch version** (1.0.0 → 1.0.1): Bug fixes only, no interface changes

### Deprecation Policy

When removing a command or option:
1. Mark as deprecated in next minor release (warning message)
2. Remove in next major release (error message with migration guide)

Example:
```bash
# v1.1.0
$ tmux-ls old-command
⚠  Warning: 'old-command' is deprecated and will be removed in v2.0.0
   Use 'new-command' instead.

# v2.0.0
$ tmux-ls old-command
✗ Error: 'old-command' was removed in v2.0.0
   See migration guide: https://github.com/waystid/tmux-ls/blob/main/MIGRATION.md
```

---

## Testing Contract Compliance

### BATS Test Examples

```bash
# Test: --version flag works
@test "tmux-ls --version shows version info" {
    run tmux-ls --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^tmux-ls\ v[0-9]+\.[0-9]+\.[0-9]+ ]]
}

# Test: Exit code for non-existent session
@test "session kill returns exit code 1 for missing session" {
    run tmux-ls session kill nonexistent-session-name
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

# Test: Config validation detects errors
@test "config validate reports invalid threshold" {
    echo "cleanup:\n  stale_threshold_minutes: -5" > /tmp/bad-config.yml
    run tmux-ls config validate /tmp/bad-config.yml
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be > 0" ]]
}
```

---

## tmux API Integration

This section documents the specific tmux commands used to gather session metrics and state information.

### Session Listing

**Command**: `tmux list-sessions -F <format>`

**Format String**:
```bash
"#{session_name}|#{session_windows}|#{session_created}|#{session_attached}|#{session_activity}"
```

**Example Output**:
```
dev-api|3|1700000000|1|1700001234
staging|1|1699999999|0|1700000500
```

**Parsed Fields**:
- `session_name`: Session identifier (string)
- `session_windows`: Number of windows (integer)
- `session_created`: Unix timestamp of creation (integer)
- `session_attached`: Number of attached clients (integer)
- `session_activity`: Unix timestamp of last activity (integer)

### Derived Metrics

These metrics are calculated from tmux output:

| Metric | Calculation | Example |
|--------|-------------|---------|
| **Uptime** | `current_time - session_created` | `7200` (2 hours) |
| **Idle Duration** | `current_time - session_activity` | `300` (5 minutes) |
| **Status** | `session_attached > 0 ? "attached" : "detached"` | `"attached"` |

### Session Details (for individual inspection)

**Command**: `tmux list-windows -t <session_name> -F <format>`

**Format String**:
```bash
"#{window_index}|#{window_name}|#{window_active}|#{pane_current_command}"
```

### Server Status Check

**Command**: `tmux list-sessions 2>/dev/null`

**Exit Code**: `0` if server running, `1` if no server

---

## Summary

This CLI interface contract defines:

1. **Command structure**: Clear hierarchy of commands and subcommands
2. **Options**: Global and command-specific flags with defaults
3. **Exit codes**: Consistent meanings for scripting/automation
4. **Output formats**: Human-readable and machine-readable options
5. **Error handling**: Clear messages with actionable guidance
6. **Accessibility**: Support for non-TTY, color-disabled, and screen reader usage
7. **Versioning**: Semantic versioning with deprecation policy

All commands map directly to functional requirements and user stories in the specification.
