#!/usr/bin/env bash
#
# theme.sh - Color schemes and UI styling
#
# ANSI color codes, configurable colors, and --no-color support

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/utils/error.sh
source "$SCRIPT_DIR/../utils/error.sh"

# ANSI color codes (use regular variables to avoid readonly issues when sourced multiple times)
COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"
COLOR_DIM="\033[2m"
COLOR_ITALIC="\033[3m"
COLOR_UNDERLINE="\033[4m"

# Foreground colors
COLOR_BLACK="\033[30m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_MAGENTA="\033[35m"
COLOR_CYAN="\033[36m"
COLOR_WHITE="\033[37m"
COLOR_GRAY="\033[90m"

# Bright foreground colors
COLOR_BRIGHT_RED="\033[91m"
COLOR_BRIGHT_GREEN="\033[92m"
COLOR_BRIGHT_YELLOW="\033[93m"
COLOR_BRIGHT_BLUE="\033[94m"
COLOR_BRIGHT_MAGENTA="\033[95m"
COLOR_BRIGHT_CYAN="\033[96m"

# Semantic colors (configurable)
COLOR_ACTIVE="${COLOR_BRIGHT_GREEN}"
COLOR_INACTIVE="${COLOR_GRAY}"
COLOR_WARNING="${COLOR_YELLOW}"
COLOR_ERROR="${COLOR_RED}"
COLOR_INFO="${COLOR_BLUE}"
COLOR_SUCCESS="${COLOR_GREEN}"
COLOR_HIGHLIGHT="${COLOR_CYAN}"

# Check if terminal supports colors
supports_color() {
    # Check if stdout is a terminal
    [[ -t 1 ]] && {
        # Check TERM variable
        [[ -n "${TERM:-}" ]] && [[ "$TERM" != "dumb" ]]
    }
}

# Check if --no-color flag is set
is_no_color() {
    [[ -n "${NO_COLOR:-}" ]] || [[ -n "${TMUX_LS_NO_COLOR:-}" ]]
}

# Colorize text
# Usage: colorize "$COLOR_RED" "text"
colorize() {
    local color="$1"
    local text="$2"

    if is_no_color || ! supports_color; then
        echo -n "$text"
    else
        echo -n "${color}${text}${COLOR_RESET}"
    fi
}

# Colorize line (with newline)
colorize_line() {
    local color="$1"
    local text="$2"

    colorize "$color" "$text"
    echo
}

# Strip color codes from text
strip_colors() {
    local text="$1"
    echo "$text" | sed -E 's/\x1b\[[0-9;]*m//g'
}

# Apply theme colors from config
apply_theme() {
    local active="${1:-}"
    local inactive="${2:-}"
    local warning="${3:-}"
    local error="${4:-}"

    [[ -n "$active" ]] && COLOR_ACTIVE="$active"
    [[ -n "$inactive" ]] && COLOR_INACTIVE="$inactive"
    [[ -n "$warning" ]] && COLOR_WARNING="$warning"
    [[ -n "$error" ]] && COLOR_ERROR="$error"
}

# Hex color to ANSI escape code
# Usage: hex_to_ansi "#FF0000"
hex_to_ansi() {
    local hex="$1"

    # Remove # prefix
    hex="${hex#\#}"

    # Convert to RGB
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))

    # Return 24-bit color code
    echo "\033[38;2;${r};${g};${b}m"
}

# Format session status indicator
format_status_indicator() {
    local status="$1"

    if [[ "$status" == "attached" ]]; then
        colorize "$COLOR_ACTIVE" "🟢"
    else
        colorize "$COLOR_INACTIVE" "⚪"
    fi
}

# Format favorite indicator
format_favorite_indicator() {
    colorize "$COLOR_HIGHLIGHT" "⭐"
}

# Format warning indicator
format_warning_indicator() {
    colorize "$COLOR_WARNING" "⚠️ "
}

# Format error indicator
format_error_indicator() {
    colorize "$COLOR_ERROR" "❌"
}

# Format success indicator
format_success_indicator() {
    colorize "$COLOR_SUCCESS" "✅"
}

# Format info indicator
format_info_indicator() {
    colorize "$COLOR_INFO" "ℹ️ "
}

# Box drawing characters for layouts
BOX_H="─"
BOX_V="│"
BOX_TL="┌"
BOX_TR="┐"
BOX_BL="└"
BOX_BR="┘"
BOX_CROSS="┼"
BOX_T="┬"
BOX_B="┴"
BOX_L="├"
BOX_R="┤"

# Draw simple box
draw_box() {
    local width="$1"
    local height="$2"
    local title="${3:-}"

    # Top border
    echo -n "$BOX_TL"
    if [[ -n "$title" ]]; then
        local title_len=${#title}
        local padding=$(( (width - title_len - 2) / 2 ))
        for ((i=0; i<padding; i++)); do echo -n "$BOX_H"; done
        echo -n " $title "
        for ((i=0; i<padding; i++)); do echo -n "$BOX_H"; done
    else
        for ((i=0; i<width; i++)); do echo -n "$BOX_H"; done
    fi
    echo "$BOX_TR"

    # Sides
    for ((i=0; i<height; i++)); do
        echo -n "$BOX_V"
        for ((j=0; j<width; j++)); do echo -n " "; done
        echo "$BOX_V"
    done

    # Bottom border
    echo -n "$BOX_BL"
    for ((i=0; i<width; i++)); do echo -n "$BOX_H"; done
    echo "$BOX_BR"
}

# Export functions and constants
export -f supports_color
export -f is_no_color
export -f colorize
export -f colorize_line
export -f strip_colors
export -f apply_theme
export -f hex_to_ansi
export -f format_status_indicator
export -f format_favorite_indicator
export -f format_warning_indicator
export -f format_error_indicator
export -f format_success_indicator
export -f format_info_indicator
export -f draw_box

# Export color constants
export COLOR_RESET COLOR_BOLD COLOR_DIM COLOR_ITALIC COLOR_UNDERLINE
export COLOR_BLACK COLOR_RED COLOR_GREEN COLOR_YELLOW COLOR_BLUE
export COLOR_MAGENTA COLOR_CYAN COLOR_WHITE COLOR_GRAY
export COLOR_BRIGHT_RED COLOR_BRIGHT_GREEN COLOR_BRIGHT_YELLOW
export COLOR_BRIGHT_BLUE COLOR_BRIGHT_MAGENTA COLOR_BRIGHT_CYAN
export COLOR_ACTIVE COLOR_INACTIVE COLOR_WARNING COLOR_ERROR
export COLOR_INFO COLOR_SUCCESS COLOR_HIGHLIGHT

# Export box drawing characters
export BOX_H BOX_V BOX_TL BOX_TR BOX_BL BOX_BR
export BOX_CROSS BOX_T BOX_B BOX_L BOX_R
