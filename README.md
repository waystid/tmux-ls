# tmux-ls - Mission Control for tmux

**Status**: Under Development

A polished CLI tool for discovering, creating, and combining tmux sessions. Transform your tmux workflow from ad-hoc session management to a production-grade mission control experience.

## Overview

tmux-ls provides an interactive terminal UI for managing tmux sessions with features including:

- Interactive session listing and quick attachment
- Quick switcher for in-tmux context switching
- Multi-session workspace creation with custom layouts
- Session lifecycle management (create, rename, kill, duplicate)
- Stale session cleanup
- Local usage telemetry and insights
- Rich configuration support

## Documentation

Full specification and design documents are located in [`docs/specs/`](./docs/specs/):

- [`spec.md`](./docs/specs/spec.md) - Complete feature specification with user stories
- [`plan.md`](./docs/specs/plan.md) - Technical implementation plan
- [`quickstart.md`](./docs/specs/quickstart.md) - User onboarding guide
- [`tasks.md`](./docs/specs/tasks.md) - Development task breakdown
- [`data-model.md`](./docs/specs/data-model.md) - Data entities and validation rules
- [`contracts/`](./docs/specs/contracts/) - API contracts and interfaces

## Installation

**Note**: Installation methods will be available once initial release is complete.

### Homebrew (macOS and Linux)

```bash
# Coming soon
brew install waystid/tap/tmux-ls
```

### Manual Installation

```bash
# Coming soon
curl -sSL https://github.com/waystid/tmux-ls/releases/latest/download/tmux-ls -o /usr/local/bin/tmux-ls
chmod +x /usr/local/bin/tmux-ls
```

## Quick Start

See [`quickstart.md`](./docs/specs/quickstart.md) for detailed getting started instructions.

```bash
# List and attach to sessions
tmux-ls

# Quick switcher (when inside tmux)
tmux-ls

# Create new session
tmux-ls  # Select "New tmux session" from menu

# Create workspace
tmux-ls  # Select "New Workspace" from menu
```

## Requirements

- **tmux**: Version 2.6 or later
- **bash**: Version 4.0 or later
- **gum** (recommended): For rich interactive UI - [charm.sh/gum](https://github.com/charmbracelet/gum)
  - Falls back gracefully to bash `select` if unavailable
- **yq**: For YAML configuration parsing
- **sqlite3**: Pre-installed on macOS 11+/modern Linux (only needed if telemetry enabled)

## Development

This project follows a specification-driven development workflow using SpecKit.

### Tech Stack

- **Language**: Bash 4.0+
- **UI**: gum (with bash fallback)
- **Configuration**: YAML (parsed with yq)
- **Testing**: BATS (Bash Automated Testing System)
- **CI/CD**: GitHub Actions
- **Distribution**: Homebrew tap + direct downloads

### Project Structure

```
tmux-ls/
├── bin/tmux-ls              # Main executable entry point
├── lib/                     # Bash libraries
│   ├── core/               # Session, workspace, config management
│   ├── ui/                 # Menu, switcher, prompts, theming
│   ├── actions/            # Create, kill, rename, workspace operations
│   ├── telemetry/          # Local telemetry collection
│   └── utils/              # Logging, validation, tmux wrappers
├── tests/                   # BATS test suites
│   ├── unit/               # Unit tests for library functions
│   ├── integration/        # End-to-end workflow tests
│   └── fixtures/           # Test data and mock tmux environments
├── docs/                    # Documentation
│   └── specs/              # Design specifications
├── homebrew/                # Homebrew formula
└── .github/workflows/       # CI/CD pipelines
```

### Development Workflow

```bash
# Clone repository
git clone git@github.com:waystid/tmux-ls.git
cd tmux-ls

# Install development dependencies
# (Details coming soon)

# Run tests
bats tests/unit/*.bats
bats tests/integration/*.bats

# Run locally
./bin/tmux-ls
```

## Origin Story

This project was originally conceived and specified within the [infrastructure-as-code](https://github.com/waystid/infrastructure-as-code) repository as a supporting tool for homelab management. The complete specification was developed there using SpecKit workflow, then extracted into this standalone repository for independent development and distribution.

**Specification Source**: The design artifacts in `docs/specs/` were created in the infrastructure-as-code repository at `specs/001-tmux-ls-cli/` and represent the complete planning phase output.

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please read the specification documents to understand the design philosophy and technical approach before submitting PRs.

## Roadmap

See [`tasks.md`](./docs/specs/tasks.md) for the complete development task breakdown across 11 phases:

- Phase 0: Research & Tech Stack Validation
- Phase 1: Project Setup & Scaffolding
- Phase 2: Core Session Management
- Phase 3: Quick Switcher
- Phase 4: Workspace Builder
- Phase 5: Configuration System
- Phase 6: Session Actions & Management
- Phase 7: Stale Session Detection
- Phase 8: Local Telemetry
- Phase 9: Testing & Quality Assurance
- Phase 10: Distribution & Packaging

## Contact

Repository: https://github.com/waystid/tmux-ls
Issues: https://github.com/waystid/tmux-ls/issues
