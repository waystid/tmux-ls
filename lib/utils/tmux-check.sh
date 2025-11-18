#!/usr/bin/env bash
#
# tmux-check.sh - tmux availability and version checks
#
# Verifies tmux is installed, meets minimum version, and server is running

# Minimum required tmux version (2.6+)
REQUIRED_TMUX_MAJOR=2
REQUIRED_TMUX_MINOR=6

# Check if tmux is installed
is_tmux_installed() {
    command -v tmux &>/dev/null
}

# Get tmux version as string
get_tmux_version() {
    if ! is_tmux_installed; then
        echo "not_installed"
        return 1
    fi

    tmux -V | sed 's/tmux //g'
}

# Parse tmux version into major.minor components
parse_tmux_version() {
    local version
    version=$(get_tmux_version)

    if [[ "$version" == "not_installed" ]]; then
        echo "0.0"
        return 1
    fi

    # Handle versions like "2.6", "3.2a", "next-3.4"
    echo "$version" | grep -oE '[0-9]+\.[0-9]+' | head -n1
}

# Check if tmux version meets minimum requirements
check_tmux_version() {
    local version_str major minor
    version_str=$(parse_tmux_version)

    if [[ -z "$version_str" ]]; then
        return 1
    fi

    major=$(echo "$version_str" | cut -d. -f1)
    minor=$(echo "$version_str" | cut -d. -f2)

    if [[ "$major" -lt "$REQUIRED_TMUX_MAJOR" ]]; then
        return 1
    fi

    if [[ "$major" -eq "$REQUIRED_TMUX_MAJOR" && "$minor" -lt "$REQUIRED_TMUX_MINOR" ]]; then
        return 1
    fi

    return 0
}

# Check if tmux server is running
is_tmux_server_running() {
    tmux list-sessions &>/dev/null
    local exit_code=$?

    # Exit code 0: server running with sessions
    # Exit code 1: server running but no sessions (still valid)
    # Other codes: server not running
    [[ $exit_code -eq 0 || $exit_code -eq 1 ]]
}

# Check if currently inside a tmux session
is_inside_tmux() {
    [[ -n "$TMUX" ]]
}

# Get current tmux session name (if inside tmux)
get_current_session() {
    if ! is_inside_tmux; then
        echo ""
        return 1
    fi

    tmux display-message -p '#S'
}

# Prevent nested tmux sessions
prevent_nesting() {
    if is_inside_tmux; then
        echo "ERROR: Already inside tmux session '$(get_current_session)'" >&2
        echo "Nested tmux sessions are not supported." >&2
        echo "Use 'tmux switch-client' to switch sessions." >&2
        return 1
    fi
    return 0
}

# Validate tmux environment
validate_tmux() {
    if ! is_tmux_installed; then
        echo "ERROR: tmux is not installed" >&2
        echo "Install tmux first:" >&2
        echo "  macOS: brew install tmux" >&2
        echo "  Linux: sudo apt-get install tmux" >&2
        return 1
    fi

    if ! check_tmux_version; then
        echo "ERROR: tmux version too old ($(get_tmux_version))" >&2
        echo "tmux-ls requires tmux ${REQUIRED_TMUX_MAJOR}.${REQUIRED_TMUX_MINOR}+" >&2
        return 1
    fi

    if ! is_tmux_server_running; then
        echo "WARNING: tmux server not running" >&2
        echo "Start tmux with: tmux new-session -s <name>" >&2
        return 2  # Non-fatal warning
    fi

    return 0
}

# Export functions
export -f is_tmux_installed
export -f get_tmux_version
export -f parse_tmux_version
export -f check_tmux_version
export -f is_tmux_server_running
export -f is_inside_tmux
export -f get_current_session
export -f prevent_nesting
export -f validate_tmux
