# Data Model: tmux-ls

**Feature**: 001-tmux-ls-cli
**Date**: 2025-11-17
**Phase**: 1 - Design & Contracts

## Overview

This document defines the core data entities, their attributes, relationships, and validation rules for tmux-ls. Since this is a bash-based CLI tool, the "data model" is implemented through structured parsing, validation functions, and file formats rather than database schemas.

---

## Entity: Session

Represents a tmux session discovered from `tmux list-sessions` or created by the user.

### Attributes

| Attribute | Type | Source | Validation | Description |
|-----------|------|--------|------------|-------------|
| `name` | String | tmux API | Unique, non-empty, no spaces | Session identifier (e.g., "dev-api", "project-frontend") |
| `creation_timestamp` | Unix timestamp | tmux API | Positive integer | When session was created (seconds since epoch) |
| `window_count` | Integer | tmux API | >= 1 | Number of windows in session |
| `attached_client_count` | Integer | tmux API | >= 0 | Number of clients currently attached |
| `uptime` | Duration (seconds) | Calculated | >= 0 | Time elapsed since creation (now - creation_timestamp) |
| `idle_duration` | Duration (seconds) | tmux API | >= 0 | Time since last activity in session |
| `is_favorite` | Boolean | Config file | true/false | User-marked as favorite (pinned to top of list) |
| `last_accessed` | Unix timestamp | Telemetry DB | Optional | Last time user attached to this session |
| `status` | Enum | Derived | "attached" \| "detached" | Whether session has attached clients |

### Parsing from tmux

```bash
# tmux list-sessions -F format string
FORMAT="#{session_name}|#{session_windows}|#{session_created}|#{session_attached}|#{session_activity}"

# Example output:
# dev-api|3|1700000000|1|1700001234
# staging|1|1699999999|0|1700000500

parse_session() {
    local line=$1
    IFS='|' read -r name windows created attached activity <<< "$line"

    # Validation
    [[ -z "$name" ]] && return 1
    [[ ! "$windows" =~ ^[0-9]+$ ]] && return 1

    # Derived fields
    local now
    now=$(date +%s)
    local uptime=$((now - created))
    local idle=$((now - activity))
    local status="detached"
    [[ "$attached" -gt 0 ]] && status="attached"

    # Output structured data (bash associative array or delimited format)
    echo "name=$name"
    echo "windows=$windows"
    echo "created=$created"
    echo "attached=$attached"
    echo "uptime=$uptime"
    echo "idle=$idle"
    echo "status=$status"
}
```

### State Transitions

```
[Non-existent] --create--> [Detached]
[Detached] --attach--> [Attached]
[Attached] --detach--> [Detached]
[Attached/Detached] --kill--> [Non-existent]
```

### Relationships

- **One-to-Many** with Workspace: A session can be referenced by multiple workspace templates
- **One-to-Many** with TelemetryEvent: Each session can have multiple logged events

---

## Entity: Workspace

Represents a multi-session layout combining 2-4 tmux sessions into a unified view with split panes.

### Attributes

| Attribute | Type | Source | Validation | Description |
|-----------|------|--------|------------|-------------|
| `name` | String | User input | Unique, non-empty, no spaces | Workspace identifier (e.g., "microservices", "fullstack-dev") |
| `layout_type` | Enum | User selection | "horizontal" \| "vertical" \| "grid" \| "custom" | Pane arrangement strategy |
| `session_refs` | Array[String] | User selection | 2-4 session names | Sessions to include in workspace |
| `pane_commands` | Map[String, String] | Optional | Valid bash commands | Optional commands to run in each pane (session_name -> command) |
| `is_template` | Boolean | Derived | true/false | Whether this workspace is saved as reusable template |
| `created_at` | Unix timestamp | File metadata | Positive integer | When template was saved |

### Persistence Format (YAML)

```yaml
# ~/.config/tmux-ls/workspaces/microservices.yml
version: "1.0"
name: "microservices"
layout_type: "grid"
sessions:
  - name: "api-gateway"
    command: "npm run dev"
  - name: "auth-service"
    command: "cargo run"
  - name: "user-service"
    command: "python manage.py runserver"
  - name: "monitoring"
    command: "docker-compose logs -f"
metadata:
  created_at: 1700000000
  description: "Full microservices stack for development"
```

### Validation Rules

```bash
validate_workspace() {
    local workspace_file=$1

    # Check session count
    local session_count
    session_count=$(yq eval '.sessions | length' "$workspace_file")
    if [[ "$session_count" -lt 2 ]] || [[ "$session_count" -gt 4 ]]; then
        echo "Workspace must have 2-4 sessions (found $session_count)" >&2
        return 1
    fi

    # Validate layout type
    local layout
    layout=$(yq eval '.layout_type' "$workspace_file")
    case "$layout" in
        horizontal|vertical|grid|custom) ;;
        *)
            echo "Invalid layout type: $layout" >&2
            return 1
            ;;
    esac

    # Check all referenced sessions exist (or can be created)
    local sessions
    sessions=$(yq eval '.sessions[].name' "$workspace_file")
    while IFS= read -r session_name; do
        if ! tmux has-session -t "$session_name" 2>/dev/null; then
            echo "Warning: Session '$session_name' does not exist (will be created)" >&2
        fi
    done <<< "$sessions"
}
```

### Layout Implementation Mapping

| Layout Type | tmux Command | Description |
|-------------|--------------|-------------|
| `horizontal` | `split-window -h` | Side-by-side panes (left-right) |
| `vertical` | `split-window -v` | Stacked panes (top-bottom) |
| `grid` | `select-layout tiled` | Equal-sized grid (automatic arrangement) |
| `custom` | User-provided layout string | Advanced: `tmux select-layout <string>` |

---

## Entity: Configuration

Represents user preferences for tmux-ls behavior, UI appearance, and feature toggles.

### Attributes

| Attribute | Type | Default | Validation | Description |
|-----------|------|---------|------------|-------------|
| `ui.theme` | String | "charm" | Non-empty | Gum theme name (charm, dracula, catppuccin) |
| `ui.colors.primary` | HexColor | "#00D9FF" | Valid hex (#RRGGBB) | Primary accent color |
| `ui.colors.success` | HexColor | "#00FF00" | Valid hex | Success state color |
| `ui.colors.warning` | HexColor | "#FFA500" | Valid hex | Warning state color |
| `workspace.default_layout` | Enum | "grid" | See Workspace.layout_type | Layout used when not explicitly chosen |
| `workspace.min_sessions` | Integer | 2 | 2-4 | Minimum sessions for workspace |
| `workspace.max_sessions` | Integer | 4 | 2-4 | Maximum sessions for workspace |
| `cleanup.stale_threshold_minutes` | Integer | 30 | > 0 | Minutes of idle time before session marked stale |
| `cleanup.require_confirmation` | Boolean | true | true/false | Prompt before killing sessions |
| `telemetry.enabled` | Boolean | false | true/false | Collect local usage metrics |
| `telemetry.database` | Path | "~/.local/share/tmux-ls/telemetry.db" | Valid path | SQLite database location |

### File Format (YAML)

```yaml
# ~/.config/tmux-ls/config.yml
version: "1.0"

ui:
  theme: "charm"
  colors:
    primary: "#00D9FF"
    success: "#00FF00"
    warning: "#FFA500"
    error: "#FF0000"

workspace:
  default_layout: "grid"
  min_sessions: 2
  max_sessions: 4
  auto_create_missing: true  # Create sessions if they don't exist

cleanup:
  stale_threshold_minutes: 30
  require_confirmation: true
  never_stale_patterns:
    - "tmux-ls-*"  # Don't mark our own sessions as stale

telemetry:
  enabled: false
  database: "~/.local/share/tmux-ls/telemetry.db"
  retention_days: 90  # Auto-delete events older than this

keybindings:
  quit: "q"
  select: "enter"
  cancel: "esc"
```

### Loading & Merging Strategy

```bash
# Default config (embedded in code)
declare -A DEFAULT_CONFIG=(
    [ui.theme]="charm"
    [ui.colors.primary]="#00D9FF"
    [workspace.default_layout]="grid"
    [cleanup.stale_threshold_minutes]=30
    [telemetry.enabled]=false
)

load_config() {
    local config_file="$HOME/.config/tmux-ls/config.yml"

    # Start with defaults
    declare -gA CONFIG
    for key in "${!DEFAULT_CONFIG[@]}"; do
        CONFIG[$key]="${DEFAULT_CONFIG[$key]}"
    done

    # Overlay user config if exists
    if [[ -f "$config_file" ]]; then
        validate_config "$config_file" || {
            echo "Config validation failed, using defaults" >&2
            return 1
        }

        # Merge user values (yq reads each key)
        CONFIG[ui.theme]=$(yq eval '.ui.theme' "$config_file" 2>/dev/null || echo "${DEFAULT_CONFIG[ui.theme]}")
        CONFIG[workspace.default_layout]=$(yq eval '.workspace.default_layout' "$config_file" 2>/dev/null || echo "${DEFAULT_CONFIG[workspace.default_layout]}")
        # ... (repeat for each config key)
    fi
}
```

---

## Entity: TelemetryEvent

Represents a single user action logged for local analytics (opt-in only).

### Attributes

| Attribute | Type | Validation | Description |
|-----------|------|------------|-------------|
| `id` | Integer (auto-increment) | Primary key | Unique event identifier |
| `timestamp` | Unix timestamp (milliseconds) | Positive integer | When event occurred |
| `action` | Enum | See Action Types | What the user did |
| `session_name` | String | Optional | Related session (if applicable) |
| `duration_ms` | Integer | >= 0 | How long operation took (if measurable) |
| `metadata` | JSON String | Valid JSON | Additional context (workspace name, layout type, error messages) |

### Action Types

| Action | When Triggered | Example Metadata |
|--------|---------------|------------------|
| `attach` | User attaches to existing session | `{"session_name": "dev-api"}` |
| `create` | User creates new session | `{"session_name": "new-project"}` |
| `kill` | User terminates session | `{"session_name": "old-session", "confirmed": true}` |
| `workspace_create` | User builds workspace | `{"workspace_name": "fullstack", "session_count": 3, "layout": "grid"}` |
| `switch` | User switches via quick switcher | `{"from_session": "dev", "to_session": "staging"}` |
| `cleanup` | User runs stale session cleanup | `{"sessions_killed": 5}` |
| `config_init` | User initializes config | `{}` |
| `stats_view` | User views statistics | `{}` |

### SQLite Schema

```sql
CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp INTEGER NOT NULL,  -- Unix timestamp in milliseconds
    action TEXT NOT NULL,
    session_name TEXT,
    duration_ms INTEGER,
    metadata TEXT,  -- JSON
    CHECK(action IN ('attach', 'create', 'kill', 'workspace_create', 'switch', 'cleanup', 'config_init', 'stats_view'))
);

CREATE INDEX IF NOT EXISTS idx_timestamp ON events(timestamp);
CREATE INDEX IF NOT EXISTS idx_action ON events(action);
CREATE INDEX IF NOT EXISTS idx_session_name ON events(session_name);
```

### Logging Function

```bash
log_event() {
    local action=$1
    local session_name=${2:-}
    local duration_ms=${3:-0}
    local metadata=${4:-'{}'}

    # Only log if telemetry enabled
    [[ "${CONFIG[telemetry.enabled]}" != "true" ]] && return 0

    local db="${CONFIG[telemetry.database]}"
    local timestamp
    timestamp=$(date +%s%3N)  # milliseconds

    # Insert event into SQLite
    sqlite3 "$db" <<EOF
INSERT INTO events (timestamp, action, session_name, duration_ms, metadata)
VALUES ($timestamp, '$action', '$session_name', $duration_ms, '$metadata');
EOF
}

# Usage example
log_event "attach" "dev-api" 150 '{"from_menu": true}'
log_event "workspace_create" "" 2340 '{"layout": "grid", "sessions": ["api", "frontend", "db"]}'
```

### Privacy & Data Lifecycle

- **No network transmission**: Database stays on local filesystem
- **User control**: Disabled by default, clear opt-in required
- **Easy deletion**: Single command (`tmux-ls stats --clear`) or delete DB file
- **Retention policy**: Auto-delete events older than `telemetry.retention_days` (default 90)
- **Export capability**: `tmux-ls stats --export` outputs JSON for user analysis

---

## Entity: LayoutTemplate

Represents a reusable workspace configuration saved by the user. This is a specialized view of Workspace entity with `is_template=true`.

### Attributes

(Same as Workspace entity, with additional constraints)

| Attribute | Additional Constraint |
|-----------|-----------------------|
| `name` | Must be filesystem-safe (used as filename) |
| `is_template` | Always `true` |
| `created_at` | Immutable (set once on save) |

### Template Lifecycle

```
[Workspace instance] --save_as_template--> [LayoutTemplate]
[LayoutTemplate] --instantiate--> [New Workspace instance]
[LayoutTemplate] --delete--> [Non-existent]
```

### Storage

- **Location**: `~/.config/tmux-ls/workspaces/`
- **Naming**: `<template-name>.yml` (e.g., `microservices.yml`)
- **Format**: Same YAML structure as Workspace

### Template Operations

```bash
# List all templates
list_templates() {
    local template_dir="$HOME/.config/tmux-ls/workspaces"
    [[ -d "$template_dir" ]] || return 0

    find "$template_dir" -name '*.yml' -exec basename {} .yml \;
}

# Instantiate template (create workspace from template)
instantiate_template() {
    local template_name=$1
    local template_file="$HOME/.config/tmux-ls/workspaces/${template_name}.yml"

    [[ ! -f "$template_file" ]] && {
        echo "Template '$template_name' not found" >&2
        return 1
    }

    # Read sessions from template
    local sessions
    sessions=$(yq eval '.sessions[].name' "$template_file")

    # Create missing sessions
    while IFS= read -r session_name; do
        if ! tmux has-session -t "$session_name" 2>/dev/null; then
            echo "Creating missing session: $session_name"
            tmux new-session -d -s "$session_name"

            # Run optional command
            local cmd
            cmd=$(yq eval ".sessions[] | select(.name == \"$session_name\") | .command" "$template_file")
            [[ -n "$cmd" ]] && tmux send-keys -t "$session_name" "$cmd" C-m
        fi
    done <<< "$sessions"

    # Build workspace using template layout
    local layout
    layout=$(yq eval '.layout_type' "$template_file")
    create_workspace "$layout" $sessions  # Call workspace creation function
}
```

---

## Validation Rules Summary

### Cross-Entity Validation

1. **Workspace → Session**: All `session_refs` must either exist or be createable
2. **TelemetryEvent → Session**: `session_name` should match an existing session (soft constraint, historical data allowed)
3. **Configuration**: Must be valid YAML and pass schema validation
4. **LayoutTemplate → Workspace**: Template instantiation must satisfy workspace constraints (2-4 sessions)

### Input Sanitization

```bash
# Session name validation
validate_session_name() {
    local name=$1

    # Empty check
    [[ -z "$name" ]] && {
        echo "Session name cannot be empty" >&2
        return 1
    }

    # Character whitelist (alphanumeric, dash, underscore)
    [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]] && {
        echo "Session name can only contain letters, numbers, dash, underscore" >&2
        return 1
    }

    # Length constraint
    [[ ${#name} -gt 50 ]] && {
        echo "Session name too long (max 50 chars)" >&2
        return 1
    }

    return 0
}

# Hex color validation
validate_hex_color() {
    local color=$1
    [[ "$color" =~ ^#[0-9A-Fa-f]{6}$ ]] || {
        echo "Invalid hex color: $color (expected #RRGGBB)" >&2
        return 1
    }
}
```

---

## Data Flow Diagrams

### Session Lifecycle Flow

```
User runs tmux-ls
    ↓
Parse tmux list-sessions → Session[]
    ↓
Enrich with metadata (uptime, favorites)
    ↓
Display in UI (gum choose)
    ↓
User selects session
    ↓
Attach to session (tmux attach)
    ↓
Log TelemetryEvent (action=attach)
```

### Workspace Creation Flow

```
User selects "New Workspace"
    ↓
Multi-select sessions (Session[])
    ↓
Validate 2-4 sessions selected
    ↓
Select layout (horizontal/vertical/grid)
    ↓
Create tmux session with splits
    ↓
Attach each selected session to pane
    ↓
Apply layout (tmux select-layout)
    ↓
Optional: Save as template (LayoutTemplate)
    ↓
Log TelemetryEvent (action=workspace_create)
```

### Configuration Loading Flow

```
tmux-ls starts
    ↓
Load default config (hardcoded)
    ↓
Check for ~/.config/tmux-ls/config.yml
    ↓ [exists]
Validate YAML structure
    ↓ [valid]
Merge user config over defaults
    ↓
Apply to CONFIG global
    ↓
UI components read CONFIG values
```

---

## Performance Considerations

### Caching Strategy

- **Session list**: Cache for 500ms (balance freshness vs performance)
- **Configuration**: Load once at startup, no hot-reload (user restarts for changes)
- **Workspace templates**: Lazy load on-demand (only when template menu accessed)
- **Telemetry**: Async writes (don't block UI for DB inserts)

### Memory Footprint

- **Session**: ~200 bytes per session (50 sessions = 10KB)
- **Configuration**: ~2KB total
- **Telemetry DB**: ~1KB per 10 events (10,000 events = 1MB)
- **Total runtime**: <5MB for typical usage

---

## Error Handling

### Invalid Data Recovery

```bash
# Example: Handle corrupted config
load_config_safe() {
    if ! load_config; then
        echo "⚠️  Config validation failed, using defaults" >&2
        echo "   Location: ~/.config/tmux-ls/config.yml" >&2
        echo "   Run 'tmux-ls config init' to reset" >&2
        # Continue with defaults (CONFIG already populated)
    fi
}

# Example: Handle missing sessions in workspace
create_workspace_safe() {
    local sessions=("$@")

    for session in "${sessions[@]}"; do
        if ! tmux has-session -t "$session" 2>/dev/null; then
            read -rp "Session '$session' not found. Create it? (y/n) " response
            if [[ "$response" == "y" ]]; then
                tmux new-session -d -s "$session" || {
                    echo "Failed to create session '$session'" >&2
                    return 1
                }
            else
                echo "Workspace creation cancelled" >&2
                return 1
            fi
        fi
    done

    # Proceed with workspace creation
    # ...
}
```

---

## Future Extensibility

### Planned Enhancements (Post-MVP)

1. **Session Groups**: Logical grouping of sessions (e.g., "project-X" group)
2. **Session Metadata**: Custom key-value pairs (project path, tech stack)
3. **Workspace Versioning**: Track template changes over time
4. **Migration Support**: Schema versioning for config/template upgrades

### Reserved Fields

These fields are reserved in YAML/DB schemas for future use:

- `version`: All entities have version field for schema migration
- `metadata`: JSON field in telemetry for extensibility
- `custom_*`: Any field starting with `custom_` is user-defined

---

## Gum Dependency & Feature Degradation Matrix

tmux-ls uses gum (charm.sh/gum) for rich interactive UI but gracefully degrades when unavailable.

### Installation Check

On first run, tmux-ls checks for gum availability:
- **If found**: Uses gum for all interactive prompts
- **If missing**: Displays one-time warning with installation instructions, then falls back to bash built-ins

### Feature Compatibility Matrix

| Feature | With Gum | Without Gum (Fallback) | Degradation Impact |
|---------|----------|------------------------|-------------------|
| Session list selection | `gum choose` with colors, icons | `bash select` menu (numbered list) | **Low** - Functionality identical, aesthetics reduced |
| Multi-select (workspace sessions) | `gum choose --multiselect` | `bash select` loop (pick one at a time) | **Medium** - Requires multiple selections instead of single multi-select |
| Fuzzy search (quick switcher) | `gum filter` with real-time filtering | `bash select` with static list | **High** - No fuzzy matching, must scroll through full list |
| Text input (session name) | `gum input` with validation prompts | `read -p` with manual validation | **Low** - Functionality identical, prompts less styled |
| Confirmation prompts | `gum confirm` with styled buttons | `read -p "Confirm? (y/n)"` | **Low** - Functionality identical |
| Layout preview (workspace) | ASCII art boxes with gum styling | Plain text layout descriptions | **Medium** - Visual preview becomes text description |
| Color themes | gum theme support | ANSI color codes only | **Low** - Colors still work, just not themed |
| Progress indicators | `gum spin` for long operations | Simple "..." text or none | **Low** - Operations still complete, just no spinner |

### Gum-Required Operations (None)

**All features work without gum** - degradation affects UX quality, not functionality.

### Recommendation

- Install gum for optimal experience: `brew install gum` (macOS) or follow https://github.com/charmbracelet/gum
- tmux-ls will function fully without it, but fuzzy search and multi-select are significantly better with gum

---

## Terminal UI Terminology & Visual Elements

This section clarifies what "visual preview", "visual indicator", and other UI terms mean in the context of a terminal application.

### Visual Indicators

| Term in Spec | Terminal Implementation | Example |
|--------------|------------------------|---------|
| **Visual indicator** (favorited sessions) | Emoji prefix + color | `⭐ dev-api (3 windows, 2h uptime)` |
| **Visual indicator** (stale sessions) | Warning emoji + italic text | `⚠️  old-session (idle 45m, no clients)` |
| **Visual indicator** (attached status) | Dot prefix with color | `🟢 active-session` (attached) vs `⚪ idle-session` (detached) |

### Layout Previews

**With gum**: ASCII box diagrams using box-drawing characters:
```
┌─────────────┬─────────────┐
│   Session1  │   Session2  │
├─────────────┼─────────────┤
│   Session3  │   Session4  │
└─────────────┴─────────────┘
```

**Without gum**: Plain text descriptions:
```
Grid Layout (2x2):
  Top-left: Session1    Top-right: Session2
  Bottom-left: Session3 Bottom-right: Session4
```

### Color Usage

- **ANSI color codes**: `\033[32m` for green, `\033[31m` for red, etc.
- **Semantic colors**: Green = active/healthy, Yellow = warning/stale, Red = error/stopped
- **Respect --no-color flag**: All color codes stripped when flag is present or TTY not detected

### Icons & Emojis

| Purpose | Icon | Fallback (no emoji support) |
|---------|------|----------------------------|
| Favorite | ⭐ | `[*]` |
| Warning | ⚠️  | `[!]` |
| Active | 🟢 | `[+]` |
| Inactive | ⚪ | `[ ]` |
| Workspace | 🏗️  | `[W]` |

---

## Configuration Path Conventions

tmux-ls follows platform-specific conventions for configuration storage:

### Linux (XDG Base Directory Specification)

- **Config**: `~/.config/tmux-ls/config.yml`
- **Data**: `~/.local/share/tmux-ls/telemetry.db`
- **Workspace Templates**: `~/.config/tmux-ls/workspaces/*.yml`

Respects `$XDG_CONFIG_HOME` and `$XDG_DATA_HOME` environment variables if set.

### macOS (Apple Human Interface Guidelines)

tmux-ls **follows XDG conventions even on macOS** for consistency with other CLI tools:

- **Config**: `~/.config/tmux-ls/config.yml` (NOT `~/Library/Application Support/`)
- **Data**: `~/.local/share/tmux-ls/telemetry.db` (NOT `~/Library/Application Support/`)

**Rationale**: Most CLI tools on macOS use XDG paths for better compatibility with dotfiles management and cross-platform workflows. Native macOS app directories (`~/Library/`) are reserved for GUI applications.

### Path Resolution Order

1. Check `$XDG_CONFIG_HOME/tmux-ls/config.yml`
2. Fallback to `~/.config/tmux-ls/config.yml`
3. If neither exists and `tmux-ls config init` not run, use embedded defaults

---

## Summary

This data model provides:

1. **Clear entity definitions** with attributes, types, and validation
2. **Practical bash implementations** showing how to parse/validate data
3. **Relationships** between entities (workspace → sessions, events → sessions)
4. **Persistence formats** (YAML for config/templates, SQLite for telemetry)
5. **Validation rules** ensuring data integrity
6. **Error handling** strategies for invalid or missing data
7. **Gum dependency degradation matrix** showing fallback behavior for all features

All entities align with the functional requirements and success criteria defined in the feature specification.
