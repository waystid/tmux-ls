#!/usr/bin/env bash
#
# error.sh - Error handling framework
#
# Provides consistent error handling, exit codes, and error messaging

# Exit codes (guard against re-sourcing)
if [[ -z "${TMUX_LS_ERROR_LOADED:-}" ]]; then
    readonly EXIT_SUCCESS=0
    readonly EXIT_GENERAL_ERROR=1
    readonly EXIT_INVALID_USAGE=2
    readonly EXIT_TMUX_NOT_FOUND=3
    readonly EXIT_TMUX_SERVER_NOT_RUNNING=4
    readonly EXIT_SESSION_NOT_FOUND=5
    readonly EXIT_SESSION_ALREADY_EXISTS=6
    readonly EXIT_CONFIG_ERROR=7
    readonly EXIT_DEPENDENCY_MISSING=8
    readonly EXIT_PERMISSION_DENIED=9
    readonly EXIT_TIMEOUT=10
    readonly TMUX_LS_ERROR_LOADED=1
fi

# Error message formatting
format_error() {
    local message="$1"
    echo -e "\033[31mERROR:\033[0m $message" >&2
}

format_warning() {
    local message="$1"
    echo -e "\033[33mWARNING:\033[0m $message" >&2
}

format_info() {
    local message="$1"
    echo -e "\033[34mINFO:\033[0m $message" >&2
}

format_success() {
    local message="$1"
    echo -e "\033[32mSUCCESS:\033[0m $message" >&2
}

# Error handler trap function
error_handler() {
    local line_number="$1"
    local command="$2"
    local exit_code="$3"

    if [[ -n "${DEBUG:-}" ]]; then
        format_error "Command failed at line $line_number: $command"
        format_error "Exit code: $exit_code"
    fi
}

# Set up error trap
enable_error_trap() {
    set -eE  # Exit on error, inherit ERR trap
    trap 'error_handler ${LINENO} "$BASH_COMMAND" $?' ERR
}

# Disable error trap
disable_error_trap() {
    set +eE
    trap - ERR
}

# Fatal error (exits immediately)
fatal() {
    local message="$1"
    local exit_code="${2:-$EXIT_GENERAL_ERROR}"

    format_error "$message"
    exit "$exit_code"
}

# Non-fatal error (returns error code)
error() {
    local message="$1"
    format_error "$message"
    return 1
}

# Warning message
warn() {
    local message="$1"
    format_warning "$message"
}

# Info message
info() {
    local message="$1"
    format_info "$message"
}

# Success message
success() {
    local message="$1"
    format_success "$message"
}

# Debug message (only if DEBUG is set)
debug() {
    local message="$1"

    if [[ -n "${DEBUG:-}" ]]; then
        echo -e "\033[90m[DEBUG]\033[0m $message" >&2
    fi
}

# Require root/sudo
require_root() {
    if [[ $EUID -ne 0 ]]; then
        fatal "This operation requires root privileges" "$EXIT_PERMISSION_DENIED"
    fi
}

# Check command exists
require_command() {
    local command="$1"
    local package="${2:-$command}"

    if ! command -v "$command" &>/dev/null; then
        fatal "$command not found. Install it with: $package" "$EXIT_DEPENDENCY_MISSING"
    fi
}

# Assert condition is true
assert() {
    local condition="$1"
    local message="$2"

    if ! eval "$condition"; then
        fatal "Assertion failed: $message" "$EXIT_GENERAL_ERROR"
    fi
}

# Timeout wrapper for commands
with_timeout() {
    local timeout_seconds="$1"
    shift
    local command=("$@")

    if command -v timeout &>/dev/null; then
        timeout "$timeout_seconds" "${command[@]}" || {
            local exit_code=$?
            if [[ $exit_code -eq 124 ]]; then
                error "Command timed out after ${timeout_seconds}s: ${command[*]}"
                return "$EXIT_TIMEOUT"
            fi
            return "$exit_code"
        }
    else
        # Fallback: no timeout support
        "${command[@]}"
    fi
}

# Export functions and constants
export -f format_error
export -f format_warning
export -f format_info
export -f format_success
export -f error_handler
export -f enable_error_trap
export -f disable_error_trap
export -f fatal
export -f error
export -f warn
export -f info
export -f success
export -f debug
export -f require_root
export -f require_command
export -f assert
export -f with_timeout

# Export exit codes
export EXIT_SUCCESS
export EXIT_GENERAL_ERROR
export EXIT_INVALID_USAGE
export EXIT_TMUX_NOT_FOUND
export EXIT_TMUX_SERVER_NOT_RUNNING
export EXIT_SESSION_NOT_FOUND
export EXIT_SESSION_ALREADY_EXISTS
export EXIT_CONFIG_ERROR
export EXIT_DEPENDENCY_MISSING
export EXIT_PERMISSION_DENIED
export EXIT_TIMEOUT
