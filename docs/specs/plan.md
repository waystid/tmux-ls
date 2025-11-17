# Implementation Plan: tmux-ls - Mission Control for tmux

**Branch**: `001-tmux-ls-cli` | **Date**: 2025-11-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-tmux-ls-cli/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Transform an ad-hoc tmux session picker into a production-grade CLI tool (tmux-ls) that provides mission control for tmux sessions. The tool will enable engineers to discover, create, and combine tmux sessions through an interactive TUI with features including: session listing/attachment, quick switcher for in-tmux usage, multi-session workspace creation with layout templates, configuration management, session lifecycle actions, stale session cleanup, and optional local telemetry. Primary approach: bash-based CLI using gum for rich interactive UI components, YAML for configuration, and BATS for automated testing.

## Technical Context

**Language/Version**: Bash 4.0+ (targeting macOS 11+ and modern Linux distributions)
**Primary Dependencies**: gum (charm.sh/gum) for interactive UI components (with graceful degradation to bash `select`), yq for YAML parsing, tmux 2.6+ (required but not bundled), sqlite3 CLI (pre-installed on macOS 11+/modern Linux, used only if telemetry enabled)
**Storage**: Filesystem-based - YAML config at `~/.config/tmux-ls/config.yml`, workspace templates in `~/.config/tmux-ls/workspaces/`, optional telemetry SQLite DB at `~/.local/share/tmux-ls/telemetry.db` (requires sqlite3 CLI, gracefully disabled if unavailable)
**Testing**: BATS (Bash Automated Testing System) for unit and integration tests, CI validation on macOS and Linux
**Target Platform**: macOS 11+ and Linux (x86_64/arm64) with bash 4.0+, distributed via Homebrew tap + manual installation option
**Project Type**: Single CLI application
**Performance Goals**: Session list display <500ms for 50 sessions, fuzzy search <100ms per keystroke, workspace creation <3s for 4 sessions
**Constraints**: No external network calls, terminal minimum 80x24 characters, graceful degradation without gum, zero nested tmux sessions
**Scale/Scope**: Single-user local tool, up to 50 concurrent tmux sessions, 5-10 workspace templates, <5MB installed size
**Development Context**: This feature is being developed within the infrastructure-as-code repository using git worktrees for isolation (per Constitution Principle VIII). The worktree at `../infrastructure-as-code-001-tmux-ls-cli/` provides an isolated workspace where this CLI tool implementation proceeds independently from other infrastructure work. While tmux-ls itself is NOT an infrastructure project, the worktree workflow ensures parallel development capability and prevents context switching interference with infrastructure operations happening in other branches.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Infrastructure Project Detection
**Status**: ❌ NOT an infrastructure project

This is a standalone CLI tool for tmux session management. No infrastructure keywords detected (Terraform, Proxmox, Docker orchestration, Kubernetes, cloud-init, VMs, containers). The constitution's infrastructure-specific requirements do NOT apply to this feature.

### Applicable Constitution Principles

**Specification-Driven Development** ✅ PASS
- Specification created at `specs/001-tmux-ls-cli/spec.md`
- Following SpecKit workflow: specify → plan → implement
- Clear success criteria defined (SC-001 through SC-012)

**Test-First Development** ✅ PASS
- Testing framework identified: BATS (Bash Automated Testing System)
- Test structure planned in project layout
- Success criteria include "100% CI test pass rate" (SC-009)
- Edge cases documented in specification

**Documentation Standards** ✅ PASS
- Specification includes comprehensive user stories, requirements, assumptions
- Plan will generate quickstart.md for user onboarding
- README and documentation mentioned in assumptions (A-014)

**Version Control & Git Workflow** ✅ PASS
- Feature branch: `001-tmux-ls-cli`
- Semantic versioning planned (FR-027)
- Git commit workflow follows constitution standards

### Gates Summary

| Gate | Status | Notes |
|------|--------|-------|
| Specification exists | ✅ PASS | Complete spec.md with user stories, requirements, success criteria |
| Test strategy defined | ✅ PASS | BATS framework, CI validation on macOS/Linux |
| Documentation planned | ✅ PASS | Quickstart, README, inline help (--help flag) |
| Version control proper | ✅ PASS | Feature branch naming convention followed |
| No infrastructure violations | ✅ N/A | Not an infrastructure project |

**Overall**: ✅ ALL GATES PASSED - Proceeding to Phase 0 research

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
tmux-ls/
├── bin/
│   └── tmux-ls              # Main executable entry point
├── lib/
│   ├── core/
│   │   ├── session.sh       # Session listing, parsing, metadata
│   │   ├── workspace.sh     # Workspace creation, layout management
│   │   └── config.sh        # Configuration loading, validation
│   ├── ui/
│   │   ├── menu.sh          # Main menu, session selector
│   │   ├── switcher.sh      # Quick switcher (in-tmux mode)
│   │   ├── prompts.sh       # Interactive prompts (gum wrappers with bash fallback)
│   │   └── theme.sh         # Color schemes, UI styling
│   ├── actions/
│   │   ├── create.sh        # New session creation
│   │   ├── attach.sh        # Session attachment logic
│   │   ├── kill.sh          # Session termination
│   │   ├── rename.sh        # Session renaming
│   │   └── cleanup.sh       # Stale session detection/cleanup
│   ├── telemetry/
│   │   ├── logger.sh        # Event logging to SQLite
│   │   └── stats.sh         # Usage statistics reporting
│   └── utils/
│       ├── validation.sh    # Input validation, error handling
│       ├── tmux-check.sh    # Tmux availability, version checks
│       └── platform.sh      # OS detection, compatibility helpers
├── tests/
│   ├── unit/
│   │   ├── test_session.bats
│   │   ├── test_workspace.bats
│   │   ├── test_config.bats
│   │   └── test_validation.bats
│   ├── integration/
│   │   ├── test_workflows.bats
│   │   ├── test_switcher.bats
│   │   └── test_workspace_creation.bats
│   └── fixtures/
│       ├── sample_sessions.txt
│       └── test_config.yml
├── homebrew/
│   └── tmux-ls.rb           # Homebrew formula
├── docs/
│   ├── README.md            # Main documentation
│   ├── INSTALLATION.md      # Installation instructions
│   └── CONTRIBUTING.md      # Development setup
├── .github/
│   └── workflows/
│       └── ci.yml           # GitHub Actions CI
└── VERSION                  # Semantic version file
```

**Structure Decision**: Single project structure (Option 1) selected as this is a standalone CLI tool. Bash scripts are organized by functional domain: `core/` for data operations, `ui/` for interactive components, `actions/` for user operations, `telemetry/` for optional tracking, and `utils/` for common helpers. The `bin/` directory contains the main entry point that sources required libraries. BATS tests mirror the source structure for clarity.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**Status**: No violations detected. All constitution gates passed.

---

## Re-evaluation Post-Design (Phase 1 Complete)

**Date**: 2025-11-17
**Artifacts Generated**: research.md, data-model.md, contracts/cli-interface.md, quickstart.md

### Constitution Compliance Re-Check

**Specification-Driven Development** ✅ PASS
- Complete specification with 8 user stories, 30 functional requirements
- Design artifacts generated: research, data model, CLI contracts, quickstart
- Clear implementation path established

**Test-First Development** ✅ PASS
- BATS framework selected with justification in research.md
- Test structure defined in project layout
- CLI contracts include BATS test examples for each command
- Data model includes validation functions and error handling patterns

**Documentation Standards** ✅ PASS
- Quickstart.md provides 5-minute onboarding path
- CLI contracts document all commands, exit codes, output formats
- Data model explains entities, relationships, validation rules
- Research decisions documented with rationale and alternatives

**Version Control & Git Workflow** ✅ PASS
- Feature branch: 001-tmux-ls-cli (active)
- Semantic versioning strategy defined in research.md
- Git commit format in constitution followed

**No Infrastructure Violations** ✅ N/A
- Confirmed NOT an infrastructure project (no Terraform, Proxmox, VMs, containers)
- Constitution's infrastructure-specific requirements do not apply

### Design Quality Assessment

| Aspect | Status | Evidence |
|--------|--------|----------|
| Clear boundaries | ✅ | Single CLI tool, no web/mobile/API components |
| Testable requirements | ✅ | All 30 FRs map to BATS test cases in contracts |
| Validated tech choices | ✅ | Research.md evaluates 15+ technology decisions with rationale |
| Data integrity | ✅ | Validation rules defined for all entities in data-model.md |
| User experience | ✅ | Quickstart guides users from install to advanced features in 5 min |
| Error handling | ✅ | Exit codes, error messages, graceful degradation documented |
| Accessibility | ✅ | CLI contracts include non-TTY mode, --no-color flag, screen reader notes |
| Performance | ✅ | Specific targets: <500ms list, <100ms search, <3s workspace creation |
| Security | ✅ | No network calls, config validation, input sanitization patterns defined |

### Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| gum unavailable on user system | Medium | Medium | Graceful degradation to bash `select` (documented in research.md) |
| tmux version incompatibility | Low | High | Minimum version 2.6 (2017, widely available), version check on startup |
| Config file corruption | Medium | Low | Validation on load, fallback to defaults, clear error messages |
| Workspace layout on small terminals | Medium | Low | Minimum 80x24 check, auto-adjust layout, warning if too small |
| Performance degradation with 50+ sessions | Low | Medium | Session list caching (500ms TTL), optimized parsing |

### Readiness for Phase 2 (Task Generation)

**Overall**: ✅ READY

All design artifacts complete and validated:
1. ✅ Technical context filled (languages, dependencies, constraints)
2. ✅ Research complete (15 technology decisions documented)
3. ✅ Data model defined (5 entities with attributes, relationships, validation)
4. ✅ CLI contracts specified (13 commands with options, exit codes, examples)
5. ✅ Quickstart written (installation through advanced workflows)
6. ✅ Agent context updated (CLAUDE.md includes new technologies)

**Next Step**: Run `/speckit.tasks` to generate dependency-ordered tasks.md from these artifacts.
