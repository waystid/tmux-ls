#!/usr/bin/env bash
#
# platform.sh - Platform detection and compatibility checks
#
# Detects operating system, bash version, and platform-specific behaviors
# Required by all other modules for cross-platform compatibility

# Minimum required bash version (4.0+)
REQUIRED_BASH_MAJOR=4
REQUIRED_BASH_MINOR=0

# Platform detection
detect_platform() {
    local os_type
    os_type=$(uname -s)

    case "$os_type" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check bash version meets minimum requirements
check_bash_version() {
    local major="${BASH_VERSINFO[0]}"
    local minor="${BASH_VERSINFO[1]}"

    if [[ "$major" -lt "$REQUIRED_BASH_MAJOR" ]]; then
        return 1
    fi

    if [[ "$major" -eq "$REQUIRED_BASH_MAJOR" && "$minor" -lt "$REQUIRED_BASH_MINOR" ]]; then
        return 1
    fi

    return 0
}

# Get bash version as string
get_bash_version() {
    echo "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]}"
}

# Get platform architecture
get_architecture() {
    uname -m
}

# Check if running on macOS
is_macos() {
    [[ "$(detect_platform)" == "macos" ]]
}

# Check if running on Linux
is_linux() {
    [[ "$(detect_platform)" == "linux" ]]
}

# Platform-specific date command (for timestamps)
get_timestamp() {
    if is_macos; then
        date +%s
    else
        date +%s
    fi
}

# Validate platform compatibility
validate_platform() {
    local platform
    platform=$(detect_platform)

    if [[ "$platform" == "unknown" ]]; then
        echo "ERROR: Unsupported platform ($(uname -s))" >&2
        echo "tmux-ls requires macOS 11+ or modern Linux" >&2
        return 1
    fi

    if ! check_bash_version; then
        echo "ERROR: Bash version too old ($(get_bash_version))" >&2
        echo "tmux-ls requires Bash ${REQUIRED_BASH_MAJOR}.${REQUIRED_BASH_MINOR}+" >&2
        return 1
    fi

    return 0
}

# Export functions for use in other modules
export -f detect_platform
export -f check_bash_version
export -f get_bash_version
export -f get_architecture
export -f is_macos
export -f is_linux
export -f get_timestamp
export -f validate_platform
