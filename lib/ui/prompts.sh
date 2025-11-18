#!/usr/bin/env bash
#
# prompts.sh - Interactive prompts (gum wrappers with bash fallback)
#
# Provides rich interactive UI using gum when available, falls back to bash built-ins

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/utils/error.sh
source "$SCRIPT_DIR/../utils/error.sh"

# Check if gum is available
check_gum_available() {
    command -v gum &>/dev/null
}

# One-time warning about gum unavailability
warn_gum_missing() {
    if [[ -z "${GUM_WARNING_SHOWN:-}" ]]; then
        warn "gum not found - using basic prompts"
        info "For better UX, install gum: https://github.com/charmbracelet/gum"
        echo "  macOS: brew install gum"
        echo "  Linux: See https://github.com/charmbracelet/gum#installation"
        export GUM_WARNING_SHOWN=1
    fi
}

# Interactive selection from list
# Usage: prompt_choose "prompt" "option1" "option2" ...
prompt_choose() {
    local prompt="$1"
    shift
    local options=("$@")

    if check_gum_available; then
        gum choose --header "$prompt" "${options[@]}"
    else
        warn_gum_missing
        echo "$prompt" >&2
        PS3="Select (number): "
        select opt in "${options[@]}"; do
            if [[ -n "$opt" ]]; then
                echo "$opt"
                break
            fi
        done
    fi
}

# Multi-select from list
# Usage: prompt_multiselect "prompt" "option1" "option2" ...
prompt_multiselect() {
    local prompt="$1"
    shift
    local options=("$@")

    if check_gum_available; then
        gum choose --no-limit --header "$prompt" "${options[@]}"
    else
        warn_gum_missing
        echo "$prompt" >&2
        echo "Enter selections one at a time (empty line to finish):" >&2

        local selections=()
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt" >&2
            ((i++))
        done

        while true; do
            read -r -p "Select (number, or empty to finish): " selection
            if [[ -z "$selection" ]]; then
                break
            fi

            if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 && "$selection" -le "${#options[@]}" ]]; then
                local idx=$((selection - 1))
                selections+=("${options[$idx]}")
                echo "  Added: ${options[$idx]}" >&2
            else
                echo "  Invalid selection" >&2
            fi
        done

        printf "%s\n" "${selections[@]}"
    fi
}

# Fuzzy filter/search
# Usage: echo "option1\noption2" | prompt_filter "prompt"
prompt_filter() {
    local prompt="$1"

    if check_gum_available; then
        gum filter --placeholder "$prompt"
    else
        warn_gum_missing
        echo "$prompt" >&2
        echo "Enter search term (basic filtering):" >&2

        local search
        read -r search

        if [[ -n "$search" ]]; then
            grep -i "$search"
        else
            cat
        fi
    fi
}

# Text input
# Usage: prompt_input "prompt" "default"
prompt_input() {
    local prompt="$1"
    local default="${2:-}"

    if check_gum_available; then
        if [[ -n "$default" ]]; then
            gum input --placeholder "$prompt" --value "$default"
        else
            gum input --placeholder "$prompt"
        fi
    else
        warn_gum_missing
        if [[ -n "$default" ]]; then
            read -r -p "$prompt [$default]: " input
            echo "${input:-$default}"
        else
            read -r -p "$prompt: " input
            echo "$input"
        fi
    fi
}

# Confirmation prompt
# Usage: prompt_confirm "Are you sure?" && do_something
prompt_confirm() {
    local prompt="$1"

    if check_gum_available; then
        gum confirm "$prompt"
    else
        warn_gum_missing
        while true; do
            read -r -p "$prompt (y/n): " response
            case "${response,,}" in
                y|yes)
                    return 0
                    ;;
                n|no)
                    return 1
                    ;;
                *)
                    echo "Please answer y or n" >&2
                    ;;
            esac
        done
    fi
}

# Password input (hidden)
# Usage: password=$(prompt_password "Enter password")
prompt_password() {
    local prompt="$1"

    if check_gum_available; then
        gum input --password --placeholder "$prompt"
    else
        warn_gum_missing
        read -r -s -p "$prompt: " password
        echo "$password"
    fi
}

# Spinner for long operations
# Usage: prompt_spinner "Loading..." command_to_run args
prompt_spinner() {
    local message="$1"
    shift
    local command=("$@")

    if check_gum_available; then
        gum spin --title "$message" -- "${command[@]}"
    else
        # Fallback: just run command with message
        echo "$message..." >&2
        "${command[@]}"
    fi
}

# Write multiline text
# Usage: text=$(prompt_write "Enter description")
prompt_write() {
    local prompt="$1"

    if check_gum_available; then
        gum write --placeholder "$prompt"
    else
        warn_gum_missing
        echo "$prompt (Ctrl+D to finish):" >&2
        cat
    fi
}

# Export functions
export -f check_gum_available
export -f warn_gum_missing
export -f prompt_choose
export -f prompt_multiselect
export -f prompt_filter
export -f prompt_input
export -f prompt_confirm
export -f prompt_password
export -f prompt_spinner
export -f prompt_write
