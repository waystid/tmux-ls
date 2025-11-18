#!/usr/bin/env bats
#
# Unit tests for bin/tmux-ls CLI flags
# Tests --version, --help, and flag parsing

# Setup test environment
setup() {
    load '../test_helper/bats-support/load'
    load '../test_helper/bats-assert/load'

    # Path to tmux-ls executable
    TMUX_LS="${BATS_TEST_DIRNAME}/../../bin/tmux-ls"
}

# Test: --version flag displays version
@test "tmux-ls --version displays version information" {
    run "$TMUX_LS" --version
    assert_success
    assert_output --partial "tmux-ls version"
    assert_output --partial "Platform:"
    assert_output --partial "Bash:"
    assert_output --partial "tmux:"
    assert_output --partial "Repository:"
    assert_output --partial "License:"
}

# Test: -v short flag works
@test "tmux-ls -v displays version (short flag)" {
    run "$TMUX_LS" -v
    assert_success
    assert_output --partial "tmux-ls version"
}

# Test: Version format is correct
@test "version string follows semantic versioning format" {
    run "$TMUX_LS" --version
    assert_success
    # Match X.Y.Z or X.Y.Z-suffix (e.g., 0.1.0-dev)
    assert_output --regexp 'tmux-ls version [0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)?'
}

# Test: --help flag displays help
@test "tmux-ls --help displays help information" {
    run "$TMUX_LS" --help
    assert_success
    assert_output --partial "tmux-ls - Mission Control for tmux"
    assert_output --partial "USAGE:"
    assert_output --partial "OPTIONS:"
    assert_output --partial "DESCRIPTION:"
    assert_output --partial "EXAMPLES:"
    assert_output --partial "CONFIGURATION:"
}

# Test: -h short flag works
@test "tmux-ls -h displays help (short flag)" {
    run "$TMUX_LS" -h
    assert_success
    assert_output --partial "USAGE:"
}

# Test: Help includes all documented flags
@test "help message documents all CLI flags" {
    run "$TMUX_LS" --help
    assert_success
    assert_output --partial "--help"
    assert_output --partial "--version"
    assert_output --partial "--config"
    assert_output --partial "--debug"
    assert_output --partial "--no-color"
}

# Test: Invalid flag shows error
@test "invalid flag displays error message" {
    run "$TMUX_LS" --invalid-flag
    assert_failure
    assert_output --partial "Unknown option"
}

# Test: --version exits with code 0
@test "version flag exits with success code" {
    run "$TMUX_LS" --version
    assert_equal "$status" 0
}

# Test: --help exits with code 0
@test "help flag exits with success code" {
    run "$TMUX_LS" --help
    assert_equal "$status" 0
}

# Test: Invalid flag exits with non-zero
@test "invalid flag exits with error code" {
    run "$TMUX_LS" --invalid
    assert_failure
    assert [ "$status" -ne 0 ]
}

# Test: Platform detection in version output
@test "version output shows correct platform" {
    run "$TMUX_LS" --version
    assert_success

    # Should show either macos or linux
    assert_output --regexp 'Platform:\s+(macos|linux)'
}

# Test: Bash version shown in version output
@test "version output shows bash version" {
    run "$TMUX_LS" --version
    assert_success

    # Should show version in X.Y.Z format
    assert_output --regexp 'Bash:\s+[0-9]+\.[0-9]+\.[0-9]+'
}

# Test: Architecture shown in version output
@test "version output shows architecture" {
    run "$TMUX_LS" --version
    assert_success

    # Should show common architectures
    assert_output --regexp '\(x86_64|aarch64|arm64|i386|i686\)'
}

# Test: Repository URL in version output
@test "version output includes repository URL" {
    run "$TMUX_LS" --version
    assert_success
    assert_output --partial "https://github.com/waystid/tmux-ls"
}

# Test: License information in version output
@test "version output includes license" {
    run "$TMUX_LS" --version
    assert_success
    assert_output --partial "MIT"
}

# Test: Help shows configuration location
@test "help message shows config file location" {
    run "$TMUX_LS" --help
    assert_success
    assert_output --partial "~/.config/tmux-ls/config.yml"
}

# Test: Help shows examples
@test "help message includes usage examples" {
    run "$TMUX_LS" --help
    assert_success
    assert_output --partial "EXAMPLES:"
    assert_output --partial "tmux-ls"
}
