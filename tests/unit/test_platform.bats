#!/usr/bin/env bats
#
# Unit tests for lib/utils/platform.sh
# Tests platform detection, bash version checking, and compatibility validation

# Load the platform module
setup() {
    load '../test_helper/bats-support/load'
    load '../test_helper/bats-assert/load'

    # Source the platform module
    source "${BATS_TEST_DIRNAME}/../../lib/utils/platform.sh"
}

# Test: detect_platform returns valid platform
@test "detect_platform returns 'macos' or 'linux'" {
    run detect_platform
    assert_success
    assert_output --regexp '^(macos|linux|unknown)$'
}

# Test: Platform detection matches uname
@test "detect_platform matches uname output" {
    local platform
    platform=$(detect_platform)

    case "$(uname -s)" in
        Darwin*)
            assert_equal "$platform" "macos"
            ;;
        Linux*)
            assert_equal "$platform" "linux"
            ;;
    esac
}

# Test: Bash version check passes (we're running bash 4.0+)
@test "check_bash_version passes for current bash" {
    run check_bash_version
    assert_success
}

# Test: get_bash_version returns valid version string
@test "get_bash_version returns version in X.Y.Z format" {
    run get_bash_version
    assert_success
    assert_output --regexp '^[0-9]+\.[0-9]+\.[0-9]+$'
}

# Test: get_architecture returns valid architecture
@test "get_architecture returns valid arch string" {
    run get_architecture
    assert_success
    assert_output --regexp '^(x86_64|aarch64|arm64|i386|i686)$'
}

# Test: is_macos returns correct value
@test "is_macos returns true on macOS, false on Linux" {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        run is_macos
        assert_success
    else
        run is_macos
        assert_failure
    fi
}

# Test: is_linux returns correct value
@test "is_linux returns true on Linux, false on macOS" {
    if [[ "$(uname -s)" == "Linux" ]]; then
        run is_linux
        assert_success
    else
        run is_linux
        assert_failure
    fi
}

# Test: get_timestamp returns unix timestamp
@test "get_timestamp returns valid unix timestamp" {
    run get_timestamp
    assert_success
    assert_output --regexp '^[0-9]{10}$'
}

# Test: validate_platform succeeds on supported platforms
@test "validate_platform succeeds on current platform" {
    run validate_platform
    assert_success
    refute_output --partial "ERROR"
}

# Test: Platform functions are exported
@test "platform functions are exported" {
    run bash -c "source lib/utils/platform.sh; type -t detect_platform"
    assert_output "function"
}
