#!/usr/bin/env bats
#
# Unit tests for lib/utils/validation.sh
# Tests input validation functions for session names, colors, integers, etc.

# Setup test environment
setup() {
    load '../test_helper/bats-support/load'
    load '../test_helper/bats-assert/load'

    # Source dependencies
    source "${BATS_TEST_DIRNAME}/../../lib/utils/error.sh"
    source "${BATS_TEST_DIRNAME}/../../lib/utils/validation.sh"
}

# Test: validate_session_name - valid names
@test "validate_session_name accepts valid session names" {
    run validate_session_name "dev-api"
    assert_success

    run validate_session_name "project_frontend"
    assert_success

    run validate_session_name "staging.v2"
    assert_success

    run validate_session_name "123-test"
    assert_success
}

# Test: validate_session_name - reject empty
@test "validate_session_name rejects empty name" {
    run validate_session_name ""
    assert_failure
    assert_output --partial "cannot be empty"
}

# Test: validate_session_name - reject spaces
@test "validate_session_name rejects names with spaces" {
    run validate_session_name "dev api"
    assert_failure
    assert_output --partial "cannot contain spaces"
}

# Test: validate_session_name - reject special characters
@test "validate_session_name rejects shell-unsafe characters" {
    run validate_session_name "dev\$api"
    assert_failure
    assert_output --partial "invalid characters"

    run validate_session_name "api;ls"
    assert_failure

    run validate_session_name "test|grep"
    assert_failure
}

# Test: validate_session_name - reject too long
@test "validate_session_name rejects names > 64 chars" {
    local long_name
    long_name=$(printf 'a%.0s' {1..65})

    run validate_session_name "$long_name"
    assert_failure
    assert_output --partial "too long"
}

# Test: validate_session_name - reject reserved names
@test "validate_session_name rejects reserved names" {
    run validate_session_name "."
    assert_failure
    assert_output --partial "Reserved"

    run validate_session_name ".."
    assert_failure

    run validate_session_name "--"
    assert_failure
}

# Test: validate_hex_color - valid colors
@test "validate_hex_color accepts valid hex colors" {
    run validate_hex_color "#FF0000"
    assert_success

    run validate_hex_color "#00ff00"
    assert_success

    run validate_hex_color "#ABC"
    assert_success

    run validate_hex_color "#123"
    assert_success
}

# Test: validate_hex_color - allow empty (defaults)
@test "validate_hex_color allows empty string" {
    run validate_hex_color ""
    assert_success
}

# Test: validate_hex_color - reject invalid format
@test "validate_hex_color rejects invalid formats" {
    run validate_hex_color "FF0000"
    assert_failure
    assert_output --partial "Invalid hex color"

    run validate_hex_color "#GG0000"
    assert_failure

    run validate_hex_color "#12"
    assert_failure

    run validate_hex_color "#12345"
    assert_failure
}

# Test: validate_positive_integer - valid integers
@test "validate_positive_integer accepts positive integers" {
    run validate_positive_integer "1"
    assert_success

    run validate_positive_integer "42"
    assert_success

    run validate_positive_integer "1000"
    assert_success
}

# Test: validate_positive_integer - reject non-integers
@test "validate_positive_integer rejects non-integers" {
    run validate_positive_integer "abc"
    assert_failure
    assert_output --partial "must be a positive integer"

    run validate_positive_integer "1.5"
    assert_failure

    run validate_positive_integer "-10"
    assert_failure
}

# Test: validate_positive_integer - reject zero
@test "validate_positive_integer rejects zero" {
    run validate_positive_integer "0"
    assert_failure
    assert_output --partial "must be greater than 0"
}

# Test: validate_range - valid ranges
@test "validate_range accepts values in range" {
    run validate_range "5" "1" "10"
    assert_success

    run validate_range "1" "1" "10"
    assert_success

    run validate_range "10" "1" "10"
    assert_success
}

# Test: validate_range - reject out of range
@test "validate_range rejects values outside range" {
    run validate_range "0" "1" "10"
    assert_failure
    assert_output --partial "must be between"

    run validate_range "11" "1" "10"
    assert_failure
}

# Test: validate_boolean - valid booleans
@test "validate_boolean accepts valid boolean values" {
    run validate_boolean "true"
    assert_success

    run validate_boolean "false"
    assert_success

    run validate_boolean "yes"
    assert_success

    run validate_boolean "no"
    assert_success

    run validate_boolean "1"
    assert_success

    run validate_boolean "0"
    assert_success

    run validate_boolean "on"
    assert_success

    run validate_boolean "off"
    assert_success

    # Case insensitive
    run validate_boolean "TRUE"
    assert_success

    run validate_boolean "No"
    assert_success
}

# Test: validate_boolean - reject invalid
@test "validate_boolean rejects invalid boolean values" {
    run validate_boolean "maybe"
    assert_failure
    assert_output --partial "Invalid boolean"

    run validate_boolean "2"
    assert_failure

    run validate_boolean ""
    assert_failure
}

# Test: sanitize_input removes special characters
@test "sanitize_input removes shell-unsafe characters" {
    run sanitize_input "test\$value"
    assert_output "testvalue"

    run sanitize_input "api;ls"
    assert_output "apils"

    run sanitize_input "file|grep"
    assert_output "filegrep"
}

# Test: sanitize_input preserves safe characters
@test "sanitize_input preserves alphanumeric, dash, underscore, dot" {
    run sanitize_input "dev-api_v2.1"
    assert_output "dev-api_v2.1"

    run sanitize_input "Project123"
    assert_output "Project123"
}
