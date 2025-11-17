# Feature Specification: tmux-ls - Mission Control for tmux

**Feature Branch**: `001-tmux-ls-cli`
**Created**: 2025-11-17
**Status**: Draft
**Input**: User description: "Transform my custom tmux session picker (triggered via tmux ls) into a polished 'tmux-ls' product. Problem: Today the script lists running tmux sessions, has a 'New tmux session' flow, supports 'New Workspace' (attach 1–4 sessions with configurable layouts), and detects when executed inside tmux to show a quick switcher. It's useful but very ad hoc: no packaging, no config options, minimal error handling, and no docs. Vision: Deliver a CLI-grade experience (installable, versioned, documented) that makes discovering, creating, and combining tmux sessions delightful for engineers who juggle multiple services/projects."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Install and Run Basic Session Management (Priority: P1)

An engineer wants to quickly see all active tmux sessions and attach to one without remembering session names or typing long commands. They install tmux-ls and immediately use it to view and switch between sessions.

**Why this priority**: This is the core value proposition - simplifying the most common tmux workflow. Without this, the tool has no foundation.

**Independent Test**: Can be fully tested by running `tmux-ls` with existing sessions and verifying the interactive session list displays correctly and allows selection/attachment.

**Acceptance Scenarios**:

1. **Given** tmux-ls is installed and multiple tmux sessions exist, **When** user runs `tmux-ls`, **Then** an interactive list of all sessions displays with session names, window counts, and creation times
2. **Given** user is viewing the session list, **When** user selects a session, **Then** tmux attaches to that session immediately
3. **Given** no tmux sessions exist, **When** user runs `tmux-ls`, **Then** system displays "No active sessions" and offers option to create a new session
4. **Given** tmux-ls is not installed, **When** user runs installation command, **Then** tmux-ls installs successfully and is available in PATH on both macOS and Linux

---

### User Story 2 - Create New Sessions with Guided Flow (Priority: P1)

An engineer starting a new project wants to create a named tmux session quickly. They use tmux-ls to create a session with a meaningful name and optional initial commands.

**Why this priority**: Session creation is as fundamental as session listing - engineers need both to manage their workflow effectively.

**Independent Test**: Can be fully tested by selecting "New tmux session" option, entering a session name, and verifying the new session is created and user is attached.

**Acceptance Scenarios**:

1. **Given** user is in the tmux-ls main menu, **When** user selects "New tmux session", **Then** system prompts for a session name
2. **Given** user has entered a valid session name, **When** user confirms, **Then** system creates the session and attaches to it
3. **Given** user enters a session name that already exists, **When** user submits, **Then** system displays error and prompts to choose different name or attach to existing
4. **Given** user wants to cancel session creation, **When** user presses escape or cancel, **Then** system returns to main menu without creating session

---

### User Story 3 - Quick Switcher Inside tmux (Priority: P2)

An engineer already working inside a tmux session wants to quickly switch to another session without detaching. They run tmux-ls from within tmux and get a streamlined switcher that prevents nested tmux inception.

**Why this priority**: This addresses a key pain point for power users who live in tmux - switching contexts should be instant and safe.

**Independent Test**: Can be fully tested by running tmux-ls from inside an active tmux session and verifying it shows the quick switcher interface with fuzzy search.

**Acceptance Scenarios**:

1. **Given** user is inside an active tmux session, **When** user runs `tmux-ls`, **Then** system detects tmux context and displays quick switcher instead of full menu
2. **Given** quick switcher is displayed, **When** user types characters, **Then** session list filters in real-time with fuzzy matching
3. **Given** user selects a different session from quick switcher, **When** user confirms, **Then** tmux switches to that session without nesting
4. **Given** user is in quick switcher, **When** user tries to create nested tmux, **Then** system prevents it and displays warning message
5. **Given** user wants to see session metrics, **When** viewing quick switcher, **Then** each session shows uptime, window count, and active status

---

### User Story 4 - Build Multi-Session Workspace (Priority: P2)

An engineer working on a microservices project needs to monitor multiple services simultaneously. They use tmux-ls to create a workspace that combines 2-4 existing sessions in a custom layout with split panes.

**Why this priority**: Workspace management is a differentiating feature that elevates tmux-ls from simple session management to true "Mission Control" - but it depends on basic session operations working first.

**Independent Test**: Can be fully tested by selecting "New Workspace" option, choosing multiple sessions, selecting a layout, and verifying the workspace displays all sessions in the chosen arrangement.

**Acceptance Scenarios**:

1. **Given** user selects "New Workspace" from main menu, **When** user is prompted, **Then** system shows multi-select list of existing sessions
2. **Given** user has selected 2-4 sessions, **When** user proceeds to layout selection, **Then** system displays visual preview of available layouts (horizontal split, vertical split, grid)
3. **Given** user selects a layout and confirms, **When** workspace is created, **Then** all selected sessions display in separate panes according to chosen layout
4. **Given** one or more selected sessions don't exist, **When** workspace creation is attempted, **Then** system displays which sessions are missing and offers to create them or choose alternatives
5. **Given** user wants to add initial commands to each pane, **When** configuring workspace, **Then** system allows optional command specification for each session pane

---

### User Story 5 - Configure tmux-ls Preferences (Priority: P3)

An engineer wants to customize tmux-ls appearance and behavior to match their personal preferences. They create a configuration file to set colors, default layouts, and UI theme.

**Why this priority**: Configuration is important for user satisfaction but not essential for core functionality - the tool should work well with sensible defaults first.

**Independent Test**: Can be fully tested by creating a config file with specific settings and verifying tmux-ls respects those preferences on next run.

**Acceptance Scenarios**:

1. **Given** tmux-ls is first installed, **When** user runs `tmux-ls config init`, **Then** system creates a default config file at `~/.config/tmux-ls/config.yml` with all options documented
2. **Given** config file exists with custom color settings, **When** user runs tmux-ls, **Then** UI displays using configured colors
3. **Given** user specifies default workspace layout in config, **When** user creates workspace without selecting layout, **Then** system uses configured default
4. **Given** user sets gum theme preference in config, **When** tmux-ls displays interactive elements, **Then** gum components use configured theme
5. **Given** config file has invalid syntax, **When** tmux-ls starts, **Then** system displays specific validation error and falls back to defaults

---

### User Story 6 - Manage Sessions with Advanced Actions (Priority: P3)

An engineer managing many sessions wants to perform bulk operations like killing multiple sessions, renaming sessions, or marking favorites. They use tmux-ls action menu to efficiently manage session lifecycle.

**Why this priority**: These power-user features enhance productivity but aren't required for basic usage - they build on the foundation of session listing and creation.

**Independent Test**: Can be fully tested by accessing the actions menu, selecting an action (kill/rename/favorite), and verifying the operation completes correctly.

**Acceptance Scenarios**:

1. **Given** user is viewing session list, **When** user selects action menu, **Then** system displays available actions: attach, kill, rename, duplicate, pin favorite
2. **Given** user selects "kill" action for a session, **When** user confirms, **Then** system prompts for confirmation and terminates the session only after confirmation
3. **Given** user selects "rename" action, **When** user enters new name, **Then** session name updates and change persists across tmux restarts
4. **Given** user selects "duplicate" action, **When** user confirms, **Then** system creates new session with same window layout as original
5. **Given** user pins a session as favorite, **When** viewing session list, **Then** favorited sessions appear at top with visual indicator
6. **Given** user wants workspace templates, **When** user saves current workspace configuration, **Then** system creates reusable template that can be instantiated later

---

### User Story 7 - Clean Up Stale Sessions (Priority: P3)

An engineer returns to their workstation after days away and has many idle sessions consuming resources. They run tmux-ls and receive a prompt to clean up sessions that have been idle with no attached clients.

**Why this priority**: Session cleanup is a maintenance feature that improves long-term system health but isn't critical for daily workflow.

**Independent Test**: Can be fully tested by creating sessions, leaving them idle for configured duration, and verifying tmux-ls detects and offers to clean them up.

**Acceptance Scenarios**:

1. **Given** sessions exist with no attached clients for > 30 minutes (configurable), **When** user runs tmux-ls, **Then** system displays stale session notification banner
2. **Given** stale sessions are detected, **When** user views session list, **Then** stale sessions show visual indicator with idle duration
3. **Given** user selects "Clean up stale sessions" option, **When** user reviews the list, **Then** system shows multi-select list of stale sessions with option to preserve specific ones
4. **Given** user confirms stale session cleanup, **When** cleanup executes, **Then** system terminates selected sessions and displays summary of freed resources
5. **Given** user wants different stale thresholds, **When** user edits config, **Then** system respects custom idle duration and attached client rules

---

### User Story 8 - Understand Usage Patterns (Priority: P3)

An engineer curious about their tmux usage wants to see metrics about which sessions they use most and workflow patterns. They enable local telemetry to get insights without data leaving their machine.

**Why this priority**: Telemetry is a nice-to-have feature for power users and future product development - it provides value but isn't essential for core workflows.

**Independent Test**: Can be fully tested by enabling telemetry, using tmux-ls for various operations, and running stats command to verify metrics are collected and displayed locally.

**Acceptance Scenarios**:

1. **Given** user enables telemetry in config, **When** user performs tmux-ls operations, **Then** system logs actions locally to `~/.local/share/tmux-ls/telemetry.db`
2. **Given** telemetry is enabled, **When** user runs `tmux-ls stats`, **Then** system displays usage summary: most-used sessions, action frequency, workspace patterns
3. **Given** user wants privacy, **When** telemetry is disabled in config, **Then** system collects no data and displays no stats
4. **Given** telemetry data exists, **When** user runs `tmux-ls stats --export`, **Then** system exports metrics to JSON for external analysis
5. **Given** user wants to reset metrics, **When** user runs `tmux-ls stats --clear`, **Then** system prompts for confirmation and deletes all local telemetry data

---

### Edge Cases

- What happens when tmux server is not running but tmux-ls is executed?
  - System detects absence of tmux server and displays clear message: "tmux server not running. Start tmux first with 'tmux new-session -s [name]'"

- How does system handle workspace creation when selected sessions exceed available screen space?
  - System automatically adjusts layout to fit within terminal dimensions and displays warning if panes will be smaller than minimum usable size (80x24 characters)

- What occurs if config file is corrupted or contains malformed YAML?
  - System logs specific parsing error to stderr, displays user-friendly message indicating config location and line number with error, then falls back to default configuration

- How does quick switcher behave when executed in a tmux session that is the only session?
  - System displays message "Only one session active" with options to create new session or exit

- What happens during session kill if the session has unsaved work or running processes?
  - System shows list of running processes in session and prompts for confirmation before terminating (behavior configurable via --force flag)

- How does system handle extremely long session names in list view?
  - Session names truncate to terminal width minus reserved space for metadata, with ellipsis indicator and full name shown in detail view

- What occurs if user tries to duplicate a session with the same name as existing session?
  - System automatically appends numeric suffix (e.g., "dev-1", "dev-2") and notifies user of renamed duplicate

- How does workspace builder handle missing or unavailable sessions during template instantiation?
  - System displays which sessions are missing, offers to create them with default configuration, or allows user to modify template before applying

- What happens if gum dependency is not installed?
  - System checks for gum on first run, displays installation instructions specific to user's OS, and degrades gracefully to basic interactive prompts using bash `select` if gum is unavailable

- How does system behave on systems with very slow tmux response (network tmux, high load)?
  - System implements configurable timeout (default 5s) for tmux commands and displays spinner during operations, with clear timeout error messages

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide single-command installation via Homebrew tap for macOS and Linux
- **FR-002**: System MUST support manual installation by copying binary to PATH location
- **FR-003**: System MUST detect and display all active tmux sessions with name, window count, creation time, and attached client count
- **FR-004**: Users MUST be able to attach to any listed session through interactive selection
- **FR-005**: System MUST allow creation of new named tmux sessions with validation to prevent duplicate names
- **FR-006**: System MUST detect when running inside an active tmux session and display quick switcher interface instead of full menu
- **FR-007**: System MUST prevent nested tmux execution with clear error messages when attempted from quick switcher
- **FR-008**: System MUST support fuzzy search filtering in quick switcher with real-time results
- **FR-009**: System MUST enable workspace creation combining 2-4 selected sessions in configurable layouts
- **FR-010**: System MUST provide visual layout previews for workspace configurations (horizontal, vertical, grid, custom)
- **FR-011**: System MUST allow optional command specification for each pane in workspace
- **FR-012**: System MUST create and load configuration from `~/.config/tmux-ls/config.yml` with YAML format
- **FR-013**: System MUST support configuration options for colors, default layouts, gum theme, stale session thresholds, and telemetry
- **FR-014**: System MUST validate configuration on startup and display specific errors for invalid syntax
- **FR-015**: System MUST provide action menu with options: attach, kill, rename, duplicate, pin favorite
- **FR-016**: System MUST require confirmation before destructive actions (kill session, bulk cleanup)
- **FR-017**: System MUST detect stale sessions based on configurable criteria (no attached clients + idle duration)
- **FR-018**: System MUST allow multi-select bulk operations for session cleanup
- **FR-019**: System MUST collect local telemetry data when enabled, storing in `~/.local/share/tmux-ls/telemetry.db`
- **FR-020**: System MUST provide stats command showing usage metrics: session frequency, action counts, workspace patterns
- **FR-021**: System MUST allow telemetry data export to JSON format
- **FR-022**: System MUST support graceful degradation when gum dependency is unavailable
- **FR-023**: System MUST implement timeout handling for slow tmux operations with configurable threshold
- **FR-024**: System MUST display session uptime and active/idle status in session listings
- **FR-025**: System MUST support workspace templates that can be saved and reused
- **FR-026**: System MUST handle missing sessions during workspace creation by offering creation or substitution options
- **FR-027**: System MUST automatically version releases with semantic versioning
- **FR-028**: System MUST provide `--version` flag displaying current version and build information
- **FR-029**: System MUST support `--help` flag with comprehensive command documentation
- **FR-030**: System MUST check for tmux server availability and display actionable error if not running

### Key Entities

- **Session**: Represents a tmux session with attributes: name (unique identifier), creation timestamp, window count, attached client count, uptime, idle duration, favorite status (boolean), last accessed timestamp
- **Workspace**: Represents a multi-session layout configuration with attributes: name, layout type (horizontal/vertical/grid/custom), associated session references (2-4 sessions), per-pane commands (optional), template status (boolean)
- **Configuration**: Represents user preferences with attributes: color scheme settings, default layout preference, gum theme identifier, stale session threshold (minutes), telemetry enabled (boolean), custom keybindings
- **Telemetry Event**: Represents logged user action with attributes: timestamp, action type (attach/create/kill/workspace/switch), session identifier, duration, metadata (JSON)
- **Layout Template**: Represents reusable workspace configuration with attributes: name, session count, layout dimensions, pane arrangement, optional startup commands per pane

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can install tmux-ls with a single command and execute successfully within 60 seconds on fresh system
- **SC-002**: Session list displays and interactive selection completes in under 500ms for up to 50 active sessions
- **SC-003**: Quick switcher fuzzy search filters results within 100ms per keystroke for session lists up to 50 items
- **SC-004**: Workspace creation with 4 sessions completes in under 3 seconds including layout rendering
- **SC-005**: System works identically on macOS and Linux without platform-specific bugs (verified through CI test suite)
- **SC-006**: 95% of users can understand and use core features (list, attach, create session) within 5 minutes of first installation without consulting documentation
- **SC-007**: Zero instances of nested tmux sessions created through tmux-ls operations (100% prevention rate)
- **SC-008**: Configuration file changes take effect on next tmux-ls execution without requiring restart or cache clearing
- **SC-009**: All automated tests pass with 100% success rate in CI environment covering session parsing, layout logic, and tmux recursion guards
- **SC-010**: Documentation enables new users to create their first workspace with custom layout within 5 minutes of reading
- **SC-011**: System gracefully handles tmux server unavailability with clear actionable error messages (no crashes or hangs)
- **SC-012**: Stale session detection correctly identifies sessions idle for configured duration with 100% accuracy

## Assumptions

- **A-001**: Users have tmux installed and accessible in PATH (tmux-ls will check but not install tmux)
- **A-002**: Target platforms are macOS 11+ and Linux distributions with bash 4.0+
- **A-003**: Terminal supports minimum 80x24 character dimensions for proper UI rendering
- **A-004**: Users have write permissions to `~/.config/` and `~/.local/share/` for configuration and data storage
- **A-005**: Gum (charm.sh/gum) is preferred for rich UI but optional - system will degrade to basic bash prompts if unavailable
- **A-006**: Default stale session threshold is 30 minutes of idle time with no attached clients
- **A-007**: Workspace templates are stored as YAML files in `~/.config/tmux-ls/workspaces/` directory
- **A-008**: Telemetry data is stored locally only - no network transmission or external analytics services
- **A-009**: Configuration follows XDG Base Directory specification for Linux and standard macOS conventions
- **A-010**: Session metrics (uptime, idle time) are derived from tmux server state, not tracked separately
- **A-011**: Homebrew is the primary distribution channel for macOS; manual installation is fallback for both platforms
- **A-012**: Automated testing uses BATS (Bash Automated Testing System) framework
- **A-013**: Minimum supported tmux version is 2.6 (released 2017) for modern command compatibility
- **A-014**: Documentation is written in Markdown and hosted in repository README with optional GitHub Pages site

## Out of Scope

- Remote tmux server management (connecting to tmux on remote hosts via SSH)
- Integration with project metadata systems (git repositories, IDE project files)
- Graphical user interface or web-based dashboard
- Session recording or playback functionality
- Automated session backup or state persistence beyond tmux's native capabilities
- Plugin system for third-party extensions (deferred to future roadmap)
- Windows/WSL support (focus on native Unix-like environments)
- Cloud synchronization of configuration or telemetry data
- Integration with container orchestration (Docker, Kubernetes session management)
- Scripting API or daemon mode for programmatic control
