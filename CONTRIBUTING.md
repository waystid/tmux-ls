# Contributing to tmux-ls

Thank you for your interest in contributing to tmux-ls! This document provides guidelines for contributing to the project.

## Development Philosophy

tmux-ls follows a **specification-driven development** approach. The complete specification was developed using SpecKit workflow in the [infrastructure-as-code](https://github.com/waystid/infrastructure-as-code) repository and is maintained in `docs/specs/`.

### Design Authority

**Specification Source**: https://github.com/waystid/infrastructure-as-code/tree/main/specs/001-tmux-ls-cli

The specification documents in `docs/specs/` are **reference copies** of the authoritative specification. Major design changes should be proposed and documented in the specification first.

## Getting Started

### Prerequisites

- **tmux**: Version 2.6 or later
- **bash**: Version 4.0 or later
- **gum**: Interactive UI components - [charm.sh/gum](https://github.com/charmbracelet/gum)
- **yq**: YAML parser - [github.com/mikefarah/yq](https://github.com/mikefarah/yq)
- **bats**: Bash testing framework - [github.com/bats-core/bats-core](https://github.com/bats-core/bats-core)

### Clone and Setup

```bash
git clone git@github.com:waystid/tmux-ls.git
cd tmux-ls

# Install dependencies (examples)
# macOS (Homebrew)
brew install gum yq bats-core

# Linux (varies by distribution)
# See installation guides for gum, yq, bats
```

## Development Workflow

### 1. Review the Specification

Before implementing features, review the relevant specification documents:

```bash
# Read the feature specification
cat docs/specs/spec.md

# Review implementation plan
cat docs/specs/plan.md

# Check task breakdown
cat docs/specs/tasks.md
```

### 2. Create a Feature Branch

```bash
# Branch naming: feature/phase-N-description
git checkout -b feature/phase-1-setup

# For bug fixes: bugfix/issue-number-description
git checkout -b bugfix/42-session-name-validation
```

### 3. Implement with Task References

Each commit should reference task IDs from `docs/specs/tasks.md`:

```bash
# Implement tasks T001-T008 (Phase 1)
# ... code implementation ...

# Commit with task references
git commit -m "feat(setup): implement project scaffolding and CI pipeline

Implements tasks T001-T008 from specification Phase 1.

- T001: Create directory structure
- T002: Set up lib/ module organization
- T003: Create bin/tmux-ls entry point
- T004: Configure shell script best practices
- T005-T008: GitHub Actions CI pipeline
"
```

### 4. Write Tests

tmux-ls uses BATS for testing. All new features should include tests:

```bash
# Run unit tests
bats tests/unit/*.bats

# Run integration tests
bats tests/integration/*.bats

# Run all tests
bats tests/**/*.bats
```

### 5. Create Pull Request

```bash
# Push feature branch
git push origin feature/phase-1-setup

# Create PR with specification reference
gh pr create \
  --title "Phase 1: Project Setup & Scaffolding" \
  --body "Implements tasks T001-T020 from specification.

## Tasks Completed
- [x] T001-T008: Directory structure and CI
- [x] T009-T014: Core library modules
- [x] T015-T020: Basic testing infrastructure

## Testing
- All unit tests pass
- Integration tests added for session parsing
- Manual testing on macOS 14 and Ubuntu 22.04

## Documentation
- Inline code comments added
- README updated with installation instructions
"
```

## Code Style

### Bash Style Guide

- **Shebang**: `#!/usr/bin/env bash`
- **Set options**: `set -euo pipefail` at script start
- **Quoting**: Always quote variables: `"${variable}"`
- **Functions**: Use lowercase with underscores: `parse_session_list()`
- **Constants**: Use uppercase: `readonly DEFAULT_CONFIG_PATH`
- **Local variables**: Declare with `local`: `local session_name`

### File Organization

```bash
# lib/core/session.sh - Example module structure

#!/usr/bin/env bash
#
# Session management functions
# Handles tmux session listing, parsing, and metadata extraction

set -euo pipefail

# Constants
readonly TMUX_MIN_VERSION="2.6"

# Parse session list from tmux
# Globals: None
# Arguments: None
# Outputs: Writes session info to stdout (one per line)
# Returns: 0 on success, 1 on error
parse_session_list() {
    local session_format="%s|%w|%t|%a"

    if ! tmux list-sessions -F "${session_format}" 2>/dev/null; then
        log_error "Failed to list tmux sessions"
        return 1
    fi
}
```

### Error Handling

```bash
# Check for tmux availability
check_tmux_available() {
    if ! command -v tmux &>/dev/null; then
        log_error "tmux is not installed or not in PATH"
        echo "Install tmux: https://github.com/tmux/tmux/wiki/Installing"
        return 1
    fi
}

# Graceful degradation for optional dependencies
check_gum_available() {
    if ! command -v gum &>/dev/null; then
        log_warn "gum not found - falling back to bash select prompts"
        export TMUX_LS_USE_GUM=false
    else
        export TMUX_LS_USE_GUM=true
    fi
}
```

## Testing Guidelines

### Unit Tests

Test individual functions in isolation:

```bash
# tests/unit/session_test.bats

@test "parse_session_list returns valid session format" {
    # Mock tmux output
    function tmux() {
        echo "main|3|1699884000|1"
        echo "dev|1|1699887000|0"
    }
    export -f tmux

    run parse_session_list
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "main|3|1699884000|1" ]
}
```

### Integration Tests

Test complete workflows:

```bash
# tests/integration/attach_session_test.bats

@test "can attach to existing session" {
    # Setup: Create test session
    tmux new-session -d -s test-session

    # Execute
    run tmux-ls attach test-session

    # Verify
    [ "$status" -eq 0 ]
    tmux has-session -t test-session

    # Cleanup
    tmux kill-session -t test-session
}
```

## Specification Updates

If you discover issues with the specification during implementation:

1. **Document the issue**: Open an issue in this repository describing the spec problem
2. **Propose a solution**: Include your proposed specification change
3. **Update reference copy**: Update `docs/specs/` with the change
4. **Notify maintainers**: Tag maintainers to update authoritative spec in infrastructure-as-code repo

## Task Tracking

Task completion is tracked in the specification repository. When you complete tasks:

1. Note completed task IDs in your PR description
2. Maintainers will update `specs/001-tmux-ls-cli/tasks.md` in the infrastructure-as-code repo

## Release Process

Releases follow semantic versioning (SemVer):

- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features, backward compatible
- **Patch** (0.1.1): Bug fixes, backward compatible

Version number is stored in `VERSION` file.

## Questions?

- **Implementation questions**: Open an issue in this repository
- **Specification questions**: Reference `docs/specs/` or open a discussion
- **Bug reports**: Use the issue template
- **Feature requests**: Check if it aligns with specification first

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
