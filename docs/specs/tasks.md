# Tasks: tmux-ls - Mission Control for tmux

**Input**: Design documents from `/specs/001-tmux-ls-cli/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cli-interface.md

**Tests**: Included - spec.md Success Criteria SC-009 requires "100% CI test pass rate" with BATS framework

**Organization**: Tasks grouped by user story to enable independent implementation and testing of each story

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US8)
- All file paths are relative to repository root `tmux-ls/`

## Path Conventions

Based on plan.md structure (single CLI application):
- **Source**: `lib/` for bash libraries
- **Entry Point**: `bin/tmux-ls`
- **Tests**: `tests/unit/`, `tests/integration/`, `tests/fixtures/`
- **Docs**: `docs/`
- **Distribution**: `homebrew/`, `install.sh`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic bash script structure

- [ ] T001 Create project directory structure: `tmux-ls/` with subdirectories `bin/`, `lib/`, `tests/`, `docs/`, `homebrew/`
- [ ] T002 Create `lib/` subdirectories: `core/`, `ui/`, `actions/`, `telemetry/`, `utils/`
- [ ] T003 Create `tests/` subdirectories: `unit/`, `integration/`, `fixtures/`
- [ ] T004 [P] Initialize VERSION file with `1.0.0` at repository root
- [ ] T005 [P] Create .gitignore for bash project (ignore `*.swp`, `*.bak`, `.DS_Store`)
- [ ] T006 [P] Create LICENSE file (MIT or preferred license)
- [ ] T007 [P] Setup GitHub Actions CI workflow in `.github/workflows/ci.yml` with BATS on macOS/Ubuntu matrix, shellcheck linting (fail on errors), and parallel job execution
- [ ] T008 [P] Create test fixtures directory `tests/fixtures/` with sample_sessions.txt and test_config.yml

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core utilities and validation that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T009 Implement platform detection in `lib/utils/platform.sh` (macOS vs Linux, bash version check)
- [ ] T010 [P] Implement tmux availability check in `lib/utils/tmux-check.sh` (check tmux installed, version >= 2.6, server running)
- [ ] T011 [P] Implement input validation functions in `lib/utils/validation.sh` (validate_session_name, validate_hex_color)
- [ ] T012 [P] Implement error handling framework in `lib/utils/error.sh` (error_handler trap, exit codes, stderr formatting)
- [ ] T013 [P] Create gum wrapper functions in `lib/ui/prompts.sh` (check_gum_available, fallback to bash select)
- [ ] T014 [P] Implement color/theme system in `lib/ui/theme.sh` (ANSI codes, configurable colors, --no-color support)
- [ ] T015 Create main entry point `bin/tmux-ls` with argument parsing (--version, --help, --config, --debug, --no-color)
- [ ] T016 [P] Write unit test for platform detection in `tests/unit/test_platform.bats`
- [ ] T017 [P] Write unit test for validation functions in `tests/unit/test_validation.bats`
- [ ] T017b [P] Write unit test for --version and --help output format in `tests/unit/test_cli_flags.bats` (validate version string format, help message structure, exit codes)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Install and Run Basic Session Management (Priority: P1) 🎯 MVP

**Goal**: Enable users to install tmux-ls, view active sessions, and attach to one interactively

**Independent Test**: Run `tmux-ls` with existing sessions, verify interactive list displays with metadata, select session and verify attachment

### Tests for User Story 1 (TDD Approach)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T018 [P] [US1] Contract test for default command (interactive mode) in `tests/integration/test_workflows.bats`
- [ ] T019 [P] [US1] Unit test for session parsing in `tests/unit/test_session.bats` (parse_session_list, enrich_metadata)
- [ ] T020 [P] [US1] Integration test for session attachment flow in `tests/integration/test_workflows.bats`

### Implementation for User Story 1

- [ ] T021 [P] [US1] Implement session listing in `lib/core/session.sh` (get_sessions with tmux list-sessions parsing)
- [ ] T022 [P] [US1] Implement session metadata enrichment in `lib/core/session.sh` (calculate uptime, idle time, attached status)
- [ ] T023 [P] [US1] Implement session caching in `lib/core/session.sh` (500ms TTL cache to meet <500ms performance target)
- [ ] T024 [US1] Implement main menu UI in `lib/ui/menu.sh` (display session list with gum choose, handle empty session list)
- [ ] T025 [US1] Implement session attachment in `lib/actions/attach.sh` (tmux attach-session with error handling)
- [ ] T026 [US1] Integrate session listing → menu → attachment in `bin/tmux-ls` for default command
- [ ] T027 [US1] Add --version flag implementation showing version from VERSION file
- [ ] T028 [US1] Add --help flag implementation with usage documentation
- [ ] T029 [P] [US1] Create installation script `install.sh` for manual installation (copy to $PREFIX/bin and lib)
- [ ] T030 [P] [US1] Create Homebrew formula in `homebrew/tmux-ls.rb` with dependencies (gum, yq, tmux)

**Checkpoint**: At this point, User Story 1 is fully functional - users can install, list sessions, and attach

---

## Phase 4: User Story 2 - Create New Sessions with Guided Flow (Priority: P1)

**Goal**: Enable users to create new named sessions through interactive prompts

**Independent Test**: Select "New tmux session", enter session name, verify session created and user attached

### Tests for User Story 2

- [ ] T031 [P] [US2] Unit test for session creation in `tests/unit/test_session.bats` (create_session, duplicate name handling)
- [ ] T032 [P] [US2] Integration test for new session workflow in `tests/integration/test_workflows.bats`

### Implementation for User Story 2

- [ ] T033 [P] [US2] Implement session name prompt in `lib/ui/prompts.sh` (gum input with validation, fallback to read)
- [ ] T034 [P] [US2] Implement duplicate session check in `lib/core/session.sh` (check if session exists before creation)
- [ ] T035 [US2] Implement session creation in `lib/actions/create.sh` (tmux new-session with name validation, error handling)
- [ ] T036 [US2] Add "New tmux session" option to main menu in `lib/ui/menu.sh`
- [ ] T037 [US2] Integrate create flow in `bin/tmux-ls` (menu → prompt → create → attach)
- [ ] T038 [US2] Handle ESC/cancel in create flow (return to main menu without creating)

**Checkpoint**: User Stories 1 AND 2 fully functional - users can list, create, and attach to sessions

---

## Phase 5: User Story 3 - Quick Switcher Inside tmux (Priority: P2)

**Goal**: Enable users inside tmux to quickly switch sessions with fuzzy search, prevent nested tmux

**Independent Test**: Run tmux-ls from inside tmux session, verify quick switcher UI with fuzzy search, switch to different session

### Tests for User Story 3

- [ ] T039 [P] [US3] Unit test for tmux context detection in `tests/unit/test_session.bats` (detect_tmux_context using $TMUX)
- [ ] T040 [P] [US3] Unit test for nested tmux prevention in `tests/unit/test_session.bats` (prevent_nesting guard)
- [ ] T041 [P] [US3] Integration test for quick switcher in `tests/integration/test_switcher.bats`

### Implementation for User Story 3

- [ ] T042 [P] [US3] Implement tmux context detection in `lib/core/session.sh` (check $TMUX environment variable)
- [ ] T043 [P] [US3] Implement nested tmux prevention guard in `lib/utils/tmux-check.sh` (prevent_nesting with clear error message)
- [ ] T044 [US3] Implement quick switcher UI in `lib/ui/switcher.sh` (gum filter for fuzzy search, session metrics display)
- [ ] T045 [US3] Implement session switching in `lib/actions/attach.sh` (tmux switch-client for in-tmux context)
- [ ] T046 [US3] Integrate quick switcher mode in `bin/tmux-ls` (detect context → route to switcher or menu)
- [ ] T047 [US3] Add session uptime/window count/status to switcher display

**Checkpoint**: User Stories 1-3 functional - basic session management + quick switching complete

---

## Phase 6: User Story 4 - Build Multi-Session Workspace (Priority: P2)

**Goal**: Enable users to combine 2-4 sessions in custom layouts (horizontal/vertical/grid)

**Independent Test**: Select "New Workspace", multi-select 2-4 sessions, choose layout, verify workspace displays in split panes

### Tests for User Story 4

- [ ] T048 [P] [US4] Unit test for workspace validation in `tests/unit/test_workspace.bats` (session count 2-4, layout types)
- [ ] T049 [P] [US4] Integration test for workspace creation in `tests/integration/test_workspace_creation.bats`

### Implementation for User Story 4

- [ ] T050 [P] [US4] Implement multi-select session picker in `lib/ui/prompts.sh` (gum choose --multiselect, 2-4 constraint)
- [ ] T051 [P] [US4] Implement layout selection UI in `lib/ui/prompts.sh` (horizontal/vertical/grid options with preview text)
- [ ] T052 [US4] Implement workspace creation logic in `lib/core/workspace.sh` (create_workspace with tmux split-window commands)
- [ ] T053 [US4] Implement horizontal layout in `lib/core/workspace.sh` (tmux split-window -h)
- [ ] T054 [P] [US4] Implement vertical layout in `lib/core/workspace.sh` (tmux split-window -v)
- [ ] T055 [P] [US4] Implement grid layout in `lib/core/workspace.sh` (tmux select-layout tiled)
- [ ] T056 [US4] Add "New Workspace" option to main menu in `lib/ui/menu.sh`
- [ ] T057 [US4] Handle missing sessions during workspace creation (prompt to create or cancel)
- [ ] T058 [P] [US4] Implement per-pane command prompt UI in `lib/ui/prompts.sh` (optional text input for each pane with skip option)
- [ ] T059 [US4] Implement per-pane command execution in `lib/core/workspace.sh` (send-keys to each pane after workspace creation, handle command failures)

**Checkpoint**: User Stories 1-4 functional - session management + workspace creation complete

---

## Phase 7: User Story 5 - Configure tmux-ls Preferences (Priority: P3)

**Goal**: Enable users to customize UI appearance and behavior via YAML config file

**Independent Test**: Run `tmux-ls config init`, edit config file, verify tmux-ls respects custom settings

### Tests for User Story 5

- [ ] T059 [P] [US5] Unit test for config loading in `tests/unit/test_config.bats` (load_config, merge defaults)
- [ ] T060 [P] [US5] Unit test for config validation in `tests/unit/test_config.bats` (validate_config, error reporting)
- [ ] T061 [P] [US5] Integration test for config commands in `tests/integration/test_workflows.bats`

### Implementation for User Story 5

- [ ] T062 [P] [US5] Implement config loading in `lib/core/config.sh` (load from ~/.config/tmux-ls/config.yml, merge defaults)
- [ ] T063 [P] [US5] Implement config validation in `lib/core/config.sh` (YAML parsing with yq, schema validation)
- [ ] T064 [P] [US5] Create default config template in `lib/core/config.sh` (embedded YAML with comments)
- [ ] T065 [US5] Implement `config init` command in `bin/tmux-ls` (create config file, check for --force)
- [ ] T066 [US5] Implement `config validate` command in `bin/tmux-ls` (validate and report errors with line numbers)
- [ ] T067 [US5] Implement `config show` command in `bin/tmux-ls` (display effective config, support --format yaml/json/table)
- [ ] T068 [US5] Apply config colors to UI components in `lib/ui/theme.sh`
- [ ] T069 [US5] Apply config workspace defaults in `lib/core/workspace.sh`
- [ ] T070 [US5] Apply config cleanup thresholds in `lib/actions/cleanup.sh` (stale_threshold_minutes)

**Checkpoint**: User Stories 1-5 functional - full session management + workspace + configuration

---

## Phase 8: User Story 6 - Manage Sessions with Advanced Actions (Priority: P3)

**Goal**: Enable users to kill, rename, duplicate sessions, pin favorites, save workspace templates

**Independent Test**: Access actions menu, perform kill/rename/favorite operations, verify changes persist

### Tests for User Story 6

- [ ] T071 [P] [US6] Unit test for session kill in `tests/unit/test_session.bats` (kill_session, confirmation handling)
- [ ] T072 [P] [US6] Unit test for session rename in `tests/unit/test_session.bats` (rename_session, duplicate name check)
- [ ] T073 [P] [US6] Integration test for actions menu in `tests/integration/test_workflows.bats`

### Implementation for User Story 6

- [ ] T074 [P] [US6] Implement session kill in `lib/actions/kill.sh` (tmux kill-session, process check, confirmation prompt)
- [ ] T075 [P] [US6] Implement session rename in `lib/actions/rename.sh` (tmux rename-session, validation)
- [ ] T076 [P] [US6] Implement session duplicate in `lib/actions/create.sh` (copy window layout, auto-suffix naming)
- [ ] T077 [P] [US6] Implement favorite pinning in `lib/core/session.sh` (store favorites in config, sort to top)
- [ ] T078 [P] [US6] Implement workspace template save in `lib/core/workspace.sh` (save to ~/.config/tmux-ls/workspaces/*.yml)
- [ ] T079 [P] [US6] Implement workspace template load in `lib/core/workspace.sh` (instantiate from YAML, create missing sessions)
- [ ] T080 [US6] Create actions menu UI in `lib/ui/menu.sh` (attach, kill, rename, duplicate, pin favorite options)
- [ ] T081 [US6] Implement `session kill <name>` command in `bin/tmux-ls` with --force flag
- [ ] T082 [US6] Implement `session rename <old> <new>` command in `bin/tmux-ls`
- [ ] T083 [US6] Implement `workspace list` command in `bin/tmux-ls`
- [ ] T084 [US6] Implement `workspace create <template>` command in `bin/tmux-ls`
- [ ] T085 [US6] Implement `workspace delete <template>` command in `bin/tmux-ls` with --force flag

**Checkpoint**: User Stories 1-6 functional - full feature set including advanced session actions

---

## Phase 9: User Story 7 - Clean Up Stale Sessions (Priority: P3)

**Goal**: Enable users to find and delete idle sessions with no attached clients

**Independent Test**: Create idle sessions, run `tmux-ls cleanup`, verify stale detection and multi-select kill

### Tests for User Story 7

- [ ] T086 [P] [US7] Unit test for stale detection in `tests/unit/test_session.bats` (detect_stale_sessions with threshold)
- [ ] T087 [P] [US7] Integration test for cleanup workflow in `tests/integration/test_workflows.bats`

### Implementation for User Story 7

- [ ] T088 [P] [US7] Implement stale session detection in `lib/actions/cleanup.sh` (check attached clients, idle duration vs threshold)
- [ ] T089 [P] [US7] Implement stale session display in `lib/ui/menu.sh` (visual indicator, idle duration in session list)
- [ ] T090 [US7] Implement cleanup multi-select UI in `lib/actions/cleanup.sh` (gum choose --multiselect for stale sessions)
- [ ] T091 [US7] Implement bulk session kill in `lib/actions/cleanup.sh` (kill selected sessions, display freed resources)
- [ ] T092 [US7] Implement `cleanup` command in `bin/tmux-ls` with --threshold, --dry-run, --force flags
- [ ] T093 [US7] Add stale session banner to main menu when detected

**Checkpoint**: User Stories 1-7 functional - full feature set including session cleanup

---

## Phase 10: User Story 8 - Understand Usage Patterns (Priority: P3)

**Goal**: Enable users to view local telemetry stats (opt-in, no network calls)

**Independent Test**: Enable telemetry in config, perform operations, run `tmux-ls stats`, verify metrics display

### Tests for User Story 8

- [ ] T094 [P] [US8] Unit test for telemetry logging in `tests/unit/test_telemetry.bats` (log_event, SQLite insertion)
- [ ] T095 [P] [US8] Unit test for stats aggregation in `tests/unit/test_telemetry.bats` (aggregate events, calculate metrics)

### Implementation for User Story 8

- [ ] T096 [P] [US8] Implement SQLite schema creation in `lib/telemetry/logger.sh` (events table with indexes)
- [ ] T097 [P] [US8] Implement event logging in `lib/telemetry/logger.sh` (log_event function, async writes)
- [ ] T098 [P] [US8] Implement stats aggregation in `lib/telemetry/stats.sh` (query events, calculate action counts, most-used sessions)
- [ ] T099 [P] [US8] Implement stats display in `lib/telemetry/stats.sh` (format output with emojis, percentages)
- [ ] T100 [US8] Integrate telemetry logging into all user actions (attach, create, kill, workspace, switch)
- [ ] T101 [US8] Implement `stats` command in `bin/tmux-ls` with --since, --export, --clear flags
- [ ] T102 [US8] Implement JSON export in `lib/telemetry/stats.sh` (export to file)
- [ ] T103 [US8] Implement data clear in `lib/telemetry/logger.sh` (delete SQLite DB with confirmation)
- [ ] T104 [US8] Add telemetry enabled/disabled check (respect config.telemetry.enabled)

**Checkpoint**: All 8 user stories functional - complete feature implementation

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, CI integration, final testing, and release preparation

- [ ] T105 [P] Create README.md in `docs/` with quickstart, installation, usage examples
- [ ] T106 [P] Create INSTALLATION.md in `docs/` with detailed install instructions (Homebrew, manual, troubleshooting)
- [ ] T107 [P] Create CONTRIBUTING.md in `docs/` with development setup, testing, PR guidelines
- [ ] T108 [P] Write integration test for full user journey in `tests/integration/test_workflows.bats` (install → list → create → workspace)
- [ ] T109 [P] Write unit tests for edge cases in `tests/unit/` (empty session list, corrupted config, missing gum, slow tmux)
- [ ] T110 [P] Implement accessibility features (--no-color flag, non-TTY detection, plain text fallback)
- [ ] T111 [P] Add inline help text for all commands (expand --help output with examples)
- [ ] T112 [P] Create animated demo GIF for README (asciinema recording of tmux-ls usage)
- [ ] T113 Code cleanup and shellcheck validation (ensure all scripts pass shellcheck linting integrated in T007 CI workflow)
- [ ] T114 Performance optimization (verify session list <500ms, fuzzy search <100ms, workspace <3s targets)
- [ ] T115 Security audit (validate input sanitization, check for code injection risks in session names)
- [ ] T116 Run full quickstart.md validation (manual walkthrough of all quickstart scenarios)
- [ ] T116b [P] Conduct UX validation for SC-006 (recruit 5 new users, measure time to complete core tasks: install, list, attach, create session; validate 95% succeed within 5 minutes)
- [ ] T117 Create release checklist (VERSION bump, git tag, Homebrew formula update, GitHub release)
- [ ] T118 Final CI run on macOS and Ubuntu (verify 100% test pass rate per SC-009)
- [ ] T119 [P] Create GitHub Release workflow in `.github/workflows/release.yml` (triggered on version tag push, builds artifacts, generates changelog)
- [ ] T120 [P] Create VERSION bump script `scripts/bump-version.sh` (accepts major/minor/patch, updates VERSION file, creates git tag)
- [ ] T121 [P] Test release workflow end-to-end (bump version locally, push tag, verify GitHub Release creation, validate artifact downloads)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - **BLOCKS all user stories**
- **User Stories (Phases 3-10)**: All depend on Foundational phase completion
  - User stories CAN proceed in parallel after Phase 2 (if team capacity allows)
  - OR sequentially in priority order: P1 (US1, US2) → P2 (US3, US4) → P3 (US5-8)
- **Polish (Phase 11)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (Install/List/Attach - P1)**: Can start after Foundational - No dependencies on other stories
- **US2 (Create Sessions - P1)**: Can start after Foundational - No dependencies on other stories
- **US3 (Quick Switcher - P2)**: Depends on US1 (session listing logic) - Could start in parallel if coordinated
- **US4 (Workspaces - P2)**: Depends on US1 (session listing logic) - Could start in parallel if coordinated
- **US5 (Configuration - P3)**: Depends on US1-4 for config application points - Best after P2 stories complete
- **US6 (Advanced Actions - P3)**: Depends on US1 (session management foundation) - Could start after US1 complete
- **US7 (Cleanup - P3)**: Depends on US1 (session listing) and US6 (kill logic) - Start after US6
- **US8 (Telemetry - P3)**: Independent of other stories - Can start after Foundational

### Within Each User Story

1. Tests (TDD): Write tests FIRST, ensure they FAIL
2. Models/Core Logic: Implement core functionality
3. UI/Commands: Implement user-facing interfaces
4. Integration: Wire together components
5. Verification: Tests now PASS

### Parallel Opportunities

**Phase 1 (Setup)**: T004, T005, T006, T007, T008 can run in parallel

**Phase 2 (Foundational)**: T010, T011, T012, T013, T014, T016, T017 can run in parallel (after T009 platform detection)

**User Stories (after Phase 2 complete)**:
- US1, US2, US8 are fully independent - can start in parallel
- US3, US4 can start in parallel (after US1 T021-T023 session core is done)
- US6 can start after US1 core complete
- US5 and US7 have cross-dependencies - best sequential

**Within Each Story**: All tasks marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Run these tests in parallel (all [P] tasks):
T018: Contract test for interactive mode
T019: Unit test for session parsing
T020: Integration test for attachment

# Then run these implementations in parallel:
T021: Session listing
T022: Metadata enrichment
T023: Session caching
T029: Installation script
T030: Homebrew formula

# Then sequential integration:
T024 → T025 → T026 → T027 → T028 (UI → attach → integration → flags)
```

---

## Implementation Strategy

### MVP First (User Stories 1-2 Only - P1 Priority)

1. Complete Phase 1: Setup (T001-T008)
2. Complete Phase 2: Foundational (T009-T017) - **CRITICAL BLOCKER**
3. Complete Phase 3: User Story 1 (T018-T030) - Install, list, attach
4. Complete Phase 4: User Story 2 (T031-T038) - Create sessions
5. **STOP and VALIDATE**: Test US1+US2 independently
6. Deploy/demo MVP release (v1.0.0-alpha)

**MVP Delivers**:
- Installation via Homebrew or manual
- Interactive session list with metadata
- Attach to existing sessions
- Create new named sessions
- Full test coverage for core workflows

### Incremental Delivery (P2 Features)

7. Complete Phase 5: User Story 3 (T039-T047) - Quick switcher
8. Test US1+US2+US3 independently → Deploy v1.0.0-beta1
9. Complete Phase 6: User Story 4 (T048-T058) - Workspaces
10. Test US1-US4 independently → Deploy v1.0.0-beta2

**Beta Delivers**: MVP + Quick switching + Workspace creation

### Full Feature Set (P3 Features)

11. Complete Phase 7: User Story 5 (T059-T070) - Configuration
12. Complete Phase 8: User Story 6 (T071-T085) - Advanced actions
13. Complete Phase 9: User Story 7 (T086-T093) - Cleanup
14. Complete Phase 10: User Story 8 (T094-T104) - Telemetry
15. Complete Phase 11: Polish (T105-T118)
16. Deploy v1.0.0 (final release)

### Parallel Team Strategy

With 3 developers after Foundational phase completes:

- **Developer A**: US1 → US3 → US6 (session management focus)
- **Developer B**: US2 → US4 → US7 (creation/workspace focus)
- **Developer C**: US8 → US5 (telemetry and config - independent)

Stories merge and integrate independently. Each delivers value without breaking others.

---

## Success Criteria Validation

Each user story maps to specification success criteria:

- **US1**: SC-001 (install <60s), SC-002 (list <500ms), SC-011 (graceful errors)
- **US2**: SC-006 (95% users succeed in 5 min)
- **US3**: SC-003 (fuzzy search <100ms), SC-007 (zero nested tmux)
- **US4**: SC-004 (workspace <3s for 4 sessions)
- **US5**: SC-008 (config changes take effect immediately)
- **US6**: SC-010 (docs enable workspace creation <5 min)
- **US7**: SC-012 (stale detection 100% accurate)
- **US8**: SC-008 (stats command works when enabled)
- **All**: SC-005 (macOS/Linux identical), SC-009 (100% CI pass rate)

---

## Notes

- [P] = different files, no dependencies, parallelizable
- [Story] = maps to user story (US1-US8) for traceability
- Each user story is independently testable at its checkpoint
- BATS tests MUST be written before implementation (TDD approach)
- All tasks include exact file paths for clarity
- Commit after each task or logical group
- shellcheck validation required for all bash scripts
- Stop at any checkpoint to validate story independently
- Success Criteria SC-009 requires 100% test pass rate before release
