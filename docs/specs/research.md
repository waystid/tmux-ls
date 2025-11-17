# Research: tmux-ls Technology Decisions

**Feature**: 001-tmux-ls-cli
**Date**: 2025-11-17
**Phase**: 0 - Outline & Research

## Purpose

This document consolidates research findings and technology decisions for implementing tmux-ls, a production-grade CLI tool for tmux session management. All "NEEDS CLARIFICATION" items from the Technical Context have been resolved through this research.

## Core Technology Stack

### Decision: Bash 4.0+ as Primary Language

**Rationale**:
- Native to macOS and Linux environments (target platforms)
- Direct tmux integration without subprocess overhead
- Minimal dependencies reduce installation friction
- Excellent portability across Unix-like systems
- Strong community support for CLI tooling patterns

**Alternatives Considered**:
- **Python**: Would require Python runtime installation, adds ~50MB dependency overhead, slower startup time (~100-200ms vs <50ms for bash)
- **Go**: Requires compilation for multiple architectures, increases binary size (~5-10MB vs <100KB for bash), harder to iterate/debug for script-like workflows
- **Node.js**: Heavy runtime dependency (~50MB), inappropriate for system utility
- **Rust**: Best performance but overkill for IO-bound tmux operations, steeper learning curve, longer compile times

**Trade-offs**:
- Bash has weaker type safety → Mitigated with strict error handling (`set -euo pipefail`), comprehensive BATS tests
- String manipulation can be verbose → Acceptable for this scope, modern bash (4.0+) has adequate features
- Harder to manage complex data structures → YAML parsing via `yq`, simple data models avoid complexity

---

### Decision: gum (charm.sh/gum) for Interactive UI

**Rationale**:
- Production-quality TUI components (select, filter, input, confirm)
- Minimal overhead (~5MB binary, single dependency)
- Rich feature set: fuzzy search, multi-select, styling, spinners
- Active maintenance by Charm team (creators of successful CLI tools)
- Graceful degradation path available (fallback to bash `select`)

**Alternatives Considered**:
- **dialog/whiptail**: Older technology, less intuitive UX, limited styling options
- **Pure bash (select)**: Acceptable fallback but missing fuzzy search, limited interactivity
- **fzf**: Excellent for filtering but lacks form inputs, confirmation prompts (would need multiple tools)
- **Custom ncurses**: Massive complexity increase, not justified for this scope

**Integration Strategy**:
```bash
# Wrapper pattern for graceful degradation
if command -v gum >/dev/null 2>&1; then
    selection=$(gum choose "${options[@]}")
else
    # Fallback to bash select
    PS3="Select: "
    select selection in "${options[@]}"; do
        break
    done
fi
```

**Trade-offs**:
- Adds external dependency → Mitigated by graceful degradation, clear installation instructions
- Requires installation step → Acceptable since gum is available via Homebrew/package managers
- Potential version compatibility → Will pin to gum 0.11+ API, document in dependencies

---

### Decision: YAML for Configuration (via yq)

**Rationale**:
- Human-readable format familiar to developers
- Supports hierarchical configuration (colors.primary, workspace.default_layout)
- `yq` is lightweight (~5MB), actively maintained, available via Homebrew
- Better than JSON for human editing (comments, multiline strings)
- Industry standard for CLI tool configuration (kubectl, helm, docker-compose)

**Alternatives Considered**:
- **TOML**: Less common, would require `toml` parser dependency
- **INI format**: Limited nesting support, no array handling
- **JSON**: Harder for humans to edit (no comments, strict syntax), worse UX
- **Pure bash sourcing**: Security risk (code execution), no validation

**Example Configuration Structure**:
```yaml
# ~/.config/tmux-ls/config.yml
version: "1.0"

ui:
  theme: "charm"
  colors:
    primary: "#00D9FF"
    success: "#00FF00"
    warning: "#FFA500"

workspace:
  default_layout: "grid"
  min_sessions: 2
  max_sessions: 4

cleanup:
  stale_threshold_minutes: 30
  require_confirmation: true

telemetry:
  enabled: false
  database: "~/.local/share/tmux-ls/telemetry.db"
```

**Validation Strategy**:
- Schema validation using yq on startup
- Fallback to sensible defaults on parse errors
- Clear error messages with line numbers

---

### Decision: BATS for Testing Framework

**Rationale**:
- De-facto standard for bash testing (used by Homebrew, many CLI tools)
- Native bash syntax, no foreign test DSL to learn
- Supports unit tests (function-level) and integration tests (full workflows)
- Good CI integration (TAP output format, exit codes)
- Mocking capabilities for tmux commands in isolated tests

**Alternatives Considered**:
- **shunit2**: Older, less active development, weaker assertion library
- **Manual bash scripts**: No standardized reporting, harder to maintain
- **Shellspec**: Newer but smaller community, less ecosystem support

**Test Structure Example**:
```bash
# tests/unit/test_session.bats
@test "parse_session_list correctly extracts session names" {
    # Arrange
    mock_output="session1: 3 windows
session2: 1 windows"

    # Act
    result=$(parse_session_list "$mock_output")

    # Assert
    [[ "$result" == *"session1"* ]]
    [[ "$result" == *"session2"* ]]
}

@test "detect_tmux_context returns true inside tmux" {
    export TMUX="test-session"
    run detect_tmux_context
    [ "$status" -eq 0 ]
}
```

**CI Integration**:
- GitHub Actions workflow with matrix testing (macOS, Ubuntu)
- Parallel test execution for speed
- Test coverage reporting (via kcov or similar)

---

## Dependency Management

### Decision: Homebrew Tap for macOS Distribution

**Rationale**:
- Standard package manager for macOS developers
- Automatic dependency resolution (will install gum, yq if needed)
- Version management and updates via `brew upgrade`
- Simple installation: `brew install waystid/tap/tmux-ls`

**Formula Structure**:
```ruby
class TmuxLs < Formula
  desc "Mission control for tmux sessions"
  homepage "https://github.com/waystid/tmux-ls"
  url "https://github.com/waystid/tmux-ls/archive/v1.0.0.tar.gz"
  sha256 "..."

  depends_on "gum"
  depends_on "yq"
  depends_on "tmux" => :recommended

  def install
    bin.install "bin/tmux-ls"
    prefix.install "lib"
  end

  test do
    system "#{bin}/tmux-ls", "--version"
  end
end
```

---

### Decision: Manual Installation as Fallback

**Rationale**:
- Supports Linux distributions without Homebrew
- Enables quick testing/development without package manager
- Simple process: clone repo, run install.sh

**Installation Script**:
```bash
#!/usr/bin/env bash
# install.sh - Manual installation for Linux

PREFIX="${PREFIX:-$HOME/.local}"

# Check dependencies
for cmd in tmux gum yq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Warning: $cmd not found. Install via package manager."
    fi
done

# Install tmux-ls
mkdir -p "$PREFIX/bin" "$PREFIX/lib/tmux-ls"
cp bin/tmux-ls "$PREFIX/bin/"
cp -r lib/* "$PREFIX/lib/tmux-ls/"
chmod +x "$PREFIX/bin/tmux-ls"

echo "Installed to $PREFIX/bin/tmux-ls"
echo "Add $PREFIX/bin to PATH if needed"
```

---

## Storage & Configuration

### Decision: XDG Base Directory Specification

**Rationale**:
- Industry standard for Unix configuration files
- Clean user home directories
- Predictable locations for debugging

**Paths**:
- **Config**: `~/.config/tmux-ls/config.yml`
- **Workspaces**: `~/.config/tmux-ls/workspaces/*.yml`
- **Telemetry DB**: `~/.local/share/tmux-ls/telemetry.db`
- **Cache** (if needed): `~/.cache/tmux-ls/`

**macOS Compatibility**:
- Same paths work on macOS (already XDG-compliant for most dev tools)
- Fallback to `~/Library/Application Support/tmux-ls` if needed (avoided for simplicity)

---

### Decision: SQLite for Optional Telemetry

**Rationale**:
- Self-contained (no server process)
- Built into macOS and most Linux distributions
- Excellent for time-series event data
- Trivial to delete/reset (`rm` the file)

**Schema** (simplified):
```sql
CREATE TABLE events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp INTEGER NOT NULL,
    action TEXT NOT NULL,  -- 'attach', 'create', 'workspace', etc.
    session_name TEXT,
    duration_ms INTEGER,
    metadata TEXT  -- JSON for extensibility
);

CREATE INDEX idx_timestamp ON events(timestamp);
CREATE INDEX idx_action ON events(action);
```

**Privacy**:
- Purely local storage (no network transmission)
- User-controlled via config flag
- Easy export to JSON for user analysis
- Clear deletion command (`tmux-ls stats --clear`)

---

## Performance Optimizations

### Decision: Lazy Loading of UI Components

**Rationale**:
- Faster startup time (<50ms cold start target)
- Only load gum when interactive mode needed
- Configuration parsing only when accessed

**Implementation**:
```bash
# Only source heavy modules when needed
load_ui_components() {
    [[ -n "${UI_LOADED:-}" ]] && return
    source "${LIB_DIR}/ui/menu.sh"
    source "${LIB_DIR}/ui/switcher.sh"
    UI_LOADED=1
}

# Main entry point
case "$1" in
    --version) echo "$VERSION"; exit 0 ;;
    stats) load_telemetry; show_stats; exit 0 ;;
    *) load_ui_components; run_interactive_mode ;;
esac
```

---

### Decision: Caching tmux Session List

**Rationale**:
- `tmux list-sessions` can be slow (~50-100ms on some systems)
- Fuzzy search requires rapid re-filtering
- Short-lived cache (500ms TTL) balances freshness vs performance

**Implementation**:
```bash
SESSION_CACHE=""
SESSION_CACHE_TIME=0

get_sessions() {
    local now
    now=$(date +%s%3N)  # milliseconds

    # Cache hit: return cached data
    if [[ -n "$SESSION_CACHE" ]] && (( now - SESSION_CACHE_TIME < 500 )); then
        echo "$SESSION_CACHE"
        return
    fi

    # Cache miss: fetch fresh data
    SESSION_CACHE=$(tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_created}")
    SESSION_CACHE_TIME=$now
    echo "$SESSION_CACHE"
}
```

---

## Error Handling & Edge Cases

### Decision: Defensive Bash Scripting Practices

**Rationale**:
- Prevent cascading failures
- Clear error messages for users
- Graceful degradation where possible

**Practices**:
```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'         # Safer word splitting

# Error handler
trap 'error_handler $? $LINENO' ERR

error_handler() {
    local exit_code=$1
    local line_number=$2
    echo "Error on line $line_number (exit code $exit_code)" >&2
    # Cleanup if needed
    exit "$exit_code"
}

# Input validation
validate_session_name() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo "Session name cannot be empty" >&2
        return 1
    fi
    if [[ "$name" =~ [[:space:]] ]]; then
        echo "Session name cannot contain spaces" >&2
        return 1
    fi
    return 0
}
```

---

### Decision: Tmux Recursion Guard

**Rationale**:
- Prevent nested tmux sessions (confusing, often unintentional)
- Critical for user trust (explicit requirement in spec)

**Implementation**:
```bash
prevent_nesting() {
    if [[ -n "${TMUX:-}" ]] && [[ "$MODE" != "switcher" ]]; then
        echo "❌ Already inside tmux. Use quick switcher or detach first." >&2
        echo "   Hint: Run 'tmux detach' to exit current session." >&2
        exit 1
    fi
}
```

---

## Workspace Layout Engine

### Decision: Tmux Native Layout Commands

**Rationale**:
- No need to calculate pixel/character dimensions
- Tmux handles terminal size automatically
- Reliable across terminal emulators

**Supported Layouts**:
1. **Horizontal Split**: `tmux split-window -h -t <target>`
2. **Vertical Split**: `tmux split-window -v -t <target>`
3. **Grid**: `tmux select-layout -t <target> tiled`
4. **Custom**: User-provided tmux layout strings

**Example Workspace Creation**:
```bash
create_workspace() {
    local sessions=("$@")
    local layout="grid"

    # Create new session with first pane
    tmux new-session -d -s "workspace-$(date +%s)" -n main

    # Attach remaining sessions as panes
    for session in "${sessions[@]:1}"; do
        tmux split-window -t "workspace-*" "tmux attach -t '$session'"
    done

    # Apply layout
    tmux select-layout -t "workspace-*" tiled

    # Attach user to workspace
    tmux attach -t "workspace-*"
}
```

---

## Versioning & Release Strategy

### Decision: Semantic Versioning with Git Tags

**Rationale**:
- Industry standard (semver.org)
- Clear communication of breaking changes
- GitHub release automation via tags

**Versioning Scheme**:
- **Major**: Breaking changes to CLI interface or config format
- **Minor**: New features (backward compatible)
- **Patch**: Bug fixes, performance improvements

**Automation**:
```bash
# VERSION file in repo root
echo "1.0.0" > VERSION

# --version flag implementation
tmux-ls --version
# Output: tmux-ls v1.0.0 (commit abc1234, built 2025-11-17)
```

**Release Process**:
1. Update VERSION file
2. Tag commit: `git tag v1.0.0`
3. GitHub Actions builds and creates release
4. Homebrew formula auto-updates via URL + SHA256

---

## Security Considerations

### Decision: No Network Communication

**Rationale**:
- Eliminates entire class of security risks
- No telemetry upload (user privacy)
- Offline-capable by design

**Implications**:
- Version checking requires manual `brew upgrade` (acceptable)
- Telemetry stays local (explicit design goal)
- No analytics/crash reporting (trade-off for privacy)

---

### Decision: Configuration Validation & Sanitization

**Rationale**:
- YAML parsing can execute code in some implementations
- User-provided config could break tool

**Safeguards**:
```bash
validate_config() {
    local config_file=$1

    # Check file permissions (should be user-writable only)
    if [[ $(stat -c '%a' "$config_file") -gt 644 ]]; then
        echo "Warning: Config file has unsafe permissions" >&2
    fi

    # Validate YAML structure (yq will error on malformed YAML)
    if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
        echo "Invalid YAML in config file" >&2
        return 1
    fi

    # Validate expected keys exist
    required_keys=("ui" "workspace" "cleanup")
    for key in "${required_keys[@]}"; do
        if ! yq eval ".${key}" "$config_file" >/dev/null 2>&1; then
            echo "Missing required config key: $key" >&2
            return 1
        fi
    done
}
```

---

## Platform Compatibility

### Decision: Support macOS 11+ and Linux with Bash 4.0+

**Rationale**:
- Covers 95%+ of target users (engineers with modern systems)
- Bash 4.0 released in 2009 (safe baseline)
- macOS 11 (Big Sur) released 2020 (reasonable support window)

**Platform-Specific Handling**:
```bash
detect_platform() {
    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            echo "linux"
            ;;
        *)
            echo "unsupported"
            return 1
            ;;
    esac
}

# Example: Date command differs between macOS/Linux
get_timestamp_ms() {
    if [[ $(detect_platform) == "macos" ]]; then
        # macOS uses BSD date
        date +%s000
    else
        # Linux uses GNU date
        date +%s%3N
    fi
}
```

**Testing Matrix** (CI):
- macOS 12 (Monterey) - oldest supported
- macOS 14 (Sonoma) - current
- Ubuntu 20.04 LTS - bash 5.0
- Ubuntu 22.04 LTS - bash 5.1

---

## Documentation Strategy

### Decision: README-Driven Development

**Rationale**:
- Documentation written alongside code (stays in sync)
- Examples serve as acceptance tests
- Easier onboarding for contributors

**Documentation Structure**:
- **README.md**: Quick start, installation, basic usage
- **INSTALLATION.md**: Detailed install instructions (Homebrew, manual, troubleshooting)
- **CONTRIBUTING.md**: Development setup, testing, PR guidelines
- **Inline `--help`**: Comprehensive CLI reference

**Help Output Example**:
```
tmux-ls - Mission Control for tmux

USAGE:
    tmux-ls [OPTIONS] [COMMAND]

OPTIONS:
    --version       Show version information
    --help          Show this help message

COMMANDS:
    (none)          Launch interactive session manager (default)
    config init     Create default configuration file
    stats           Show usage statistics
    stats --clear   Clear all telemetry data

EXAMPLES:
    tmux-ls                    # Interactive session picker
    tmux-ls stats              # View usage metrics
    tmux-ls config init        # Generate config file

See https://github.com/waystid/tmux-ls for full documentation.
```

---

## Summary of Key Decisions

| Decision Area | Choice | Primary Rationale |
|--------------|--------|-------------------|
| **Language** | Bash 4.0+ | Native to target platforms, minimal overhead, direct tmux integration |
| **UI Framework** | gum with bash fallback | Rich TUI features, graceful degradation |
| **Configuration** | YAML via yq | Human-readable, hierarchical, standard format |
| **Testing** | BATS | De-facto bash testing standard, good CI support |
| **Distribution** | Homebrew tap + manual | Standard for macOS, fallback for Linux |
| **Storage** | XDG directories | Standard paths, clean home directory |
| **Telemetry** | SQLite (optional) | Local-only, self-contained, easy to delete |
| **Versioning** | Semantic versioning | Industry standard, clear communication |
| **Security** | No network, config validation | Privacy-first, minimize attack surface |
| **Platforms** | macOS 11+, Linux (bash 4+) | Covers 95%+ of target users |

---

## Remaining Uncertainties (Deferred to Implementation)

These items are not blockers for planning but will be refined during development:

1. **Exact gum theme customization API**: Will explore during UI implementation
2. **Optimal session cache TTL**: 500ms is initial estimate, may tune based on testing
3. **Telemetry schema extensibility**: JSON metadata field allows future expansion
4. **Workspace template versioning**: v1 will use simple YAML format, can evolve

---

## Next Steps

With research complete, proceed to:
1. **Phase 1**: Generate `data-model.md` based on Key Entities from spec
2. **Phase 1**: Generate API contracts (CLI command structure)
3. **Phase 1**: Generate `quickstart.md` for user onboarding
4. **Phase 1**: Update agent context with new technologies
5. **Phase 2**: Generate `tasks.md` (via `/speckit.tasks` command)

All technology choices are now resolved and ready for implementation planning.
