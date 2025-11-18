#!/usr/bin/env bash
#
# validation.sh - Input validation functions
#
# Validates user input for session names, colors, numbers, etc.

# Validate session name
# Rules: non-empty, no spaces, no special shell characters, max 64 chars
validate_session_name() {
    local name="$1"

    # Check if empty
    if [[ -z "$name" ]]; then
        echo "ERROR: Session name cannot be empty" >&2
        return 1
    fi

    # Check length
    if [[ ${#name} -gt 64 ]]; then
        echo "ERROR: Session name too long (max 64 characters)" >&2
        return 1
    fi

    # Check for spaces
    if [[ "$name" =~ [[:space:]] ]]; then
        echo "ERROR: Session name cannot contain spaces" >&2
        return 1
    fi

    # Check for special characters (shell-unsafe)
    if [[ "$name" =~ [\$\`\!\;\|\&\<\>\(\)\{\}\[\]\\] ]]; then
        echo "ERROR: Session name contains invalid characters" >&2
        echo "Allowed: alphanumeric, dash, underscore, dot" >&2
        return 1
    fi

    # Check for reserved names
    case "$name" in
        "." | ".." | "-" | "--")
            echo "ERROR: Reserved session name: $name" >&2
            return 1
            ;;
    esac

    return 0
}

# Validate hex color code
validate_hex_color() {
    local color="$1"

    # Allow empty (will use default)
    if [[ -z "$color" ]]; then
        return 0
    fi

    # Check format: #RRGGBB or #RGB
    if [[ "$color" =~ ^#[0-9A-Fa-f]{6}$ || "$color" =~ ^#[0-9A-Fa-f]{3}$ ]]; then
        return 0
    fi

    echo "ERROR: Invalid hex color: $color" >&2
    echo "Expected format: #RRGGBB or #RGB" >&2
    return 1
}

# Validate positive integer
validate_positive_integer() {
    local value="$1"
    local name="${2:-value}"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "ERROR: $name must be a positive integer" >&2
        return 1
    fi

    if [[ "$value" -le 0 ]]; then
        echo "ERROR: $name must be greater than 0" >&2
        return 1
    fi

    return 0
}

# Validate integer range
validate_range() {
    local value="$1"
    local min="$2"
    local max="$3"
    local name="${4:-value}"

    if ! validate_positive_integer "$value" "$name"; then
        return 1
    fi

    if [[ "$value" -lt "$min" || "$value" -gt "$max" ]]; then
        echo "ERROR: $name must be between $min and $max" >&2
        return 1
    fi

    return 0
}

# Validate boolean value
validate_boolean() {
    local value="$1"

    case "${value,,}" in  # Convert to lowercase
        true|yes|1|on)
            return 0
            ;;
        false|no|0|off)
            return 0
            ;;
        *)
            echo "ERROR: Invalid boolean value: $value" >&2
            echo "Expected: true/false, yes/no, 1/0, on/off" >&2
            return 1
            ;;
    esac
}

# Validate file path exists
validate_file_exists() {
    local path="$1"
    local name="${2:-file}"

    if [[ ! -f "$path" ]]; then
        echo "ERROR: $name not found: $path" >&2
        return 1
    fi

    return 0
}

# Validate directory exists
validate_directory_exists() {
    local path="$1"
    local name="${2:-directory}"

    if [[ ! -d "$path" ]]; then
        echo "ERROR: $name not found: $path" >&2
        return 1
    fi

    return 0
}

# Sanitize input for shell safety
sanitize_input() {
    local input="$1"

    # Remove all special shell characters
    echo "$input" | tr -cd '[:alnum:]._-'
}

# Export functions
export -f validate_session_name
export -f validate_hex_color
export -f validate_positive_integer
export -f validate_range
export -f validate_boolean
export -f validate_file_exists
export -f validate_directory_exists
export -f sanitize_input
