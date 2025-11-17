# Quickstart Guide: tmux-ls

**Get started with tmux-ls in 5 minutes**

---

## What is tmux-ls?

tmux-ls is your mission control for tmux sessions. It provides:
- **Interactive session picker** with fuzzy search
- **Quick switcher** for switching between sessions when already in tmux
- **Workspace builder** to combine multiple sessions in custom layouts
- **Session lifecycle management** (create, rename, kill, cleanup)
- **Local telemetry** to understand your tmux usage patterns (opt-in)

---

## Installation

### macOS (via Homebrew)

```bash
# Add the tap (one-time setup)
brew tap waystid/tap

# Install tmux-ls
brew install tmux-ls

# Verify installation
tmux-ls --version
```

**That's it!** Homebrew will automatically install dependencies (gum, yq).

---

### Linux (Manual Installation)

```bash
# Install dependencies (adjust for your package manager)
# Debian/Ubuntu
sudo apt install tmux gum yq

# Arch Linux
sudo pacman -S tmux gum yq

# Fedora
sudo dnf install tmux gum yq

# Clone repository
git clone https://github.com/waystid/tmux-ls.git
cd tmux-ls

# Install to ~/.local (or PREFIX=/usr/local for system-wide)
./install.sh

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
tmux-ls --version
```

---

## First Run

### 1. Start tmux (if not already running)

```bash
# Create your first session
tmux new-session -s dev
```

Detach from the session with `Ctrl+b d`.

---

### 2. Launch tmux-ls

```bash
tmux-ls
```

You'll see an interactive menu like this:

```
╭─────────────────────────────────────────────╮
│ tmux-ls - Mission Control                  │
│ 1 active session                            │
├─────────────────────────────────────────────┤
│ > dev              (1 window, 2m uptime)   │
│ ─────────────────────────────────────────── │
│   📝 New tmux session                       │
│   🚀 New Workspace                          │
│   ⚙️  Actions                               │
│   🔧 Configuration                          │
╰─────────────────────────────────────────────╯
```

---

### 3. Navigate the Menu

- **Arrow keys** or **j/k**: Move selection
- **Enter**: Select option
- **Esc** or **q**: Exit

Select your `dev` session and press **Enter** to attach.

---

## Core Workflows

### Workflow 1: Attach to Existing Session

```bash
# Run tmux-ls
tmux-ls

# Use arrow keys to select session
# Press Enter to attach
```

**Result**: You're now inside the selected tmux session.

---

### Workflow 2: Create New Session

```bash
# Run tmux-ls
tmux-ls

# Select "📝 New tmux session"
# Enter session name (e.g., "frontend")
# Press Enter
```

**Result**: New session created and you're attached to it.

---

### Workflow 3: Quick Switcher (Inside tmux)

When you're already inside a tmux session, `tmux-ls` automatically launches the quick switcher:

```bash
# From inside any tmux session
tmux-ls
```

You'll see a fuzzy-searchable list:

```
╭─────────────────────────────────────────────╮
│ Quick Switcher (2 sessions)                │
├─────────────────────────────────────────────┤
│ > dev              (1 window, 5m uptime)   │
│   frontend         (2 windows, 1m uptime)  │
╰─────────────────────────────────────────────╯

Filter: _
```

- **Type** to filter sessions (fuzzy matching)
- **Enter**: Switch to selected session
- **Esc**: Cancel and stay in current session

**Result**: You switch to the selected session without nesting tmux (no tmux inception!).

---

### Workflow 4: Build a Workspace

Combine multiple sessions into a single view with split panes.

```bash
# Create a few sessions first
tmux new-session -d -s api
tmux new-session -d -s frontend
tmux new-session -d -s database

# Run tmux-ls
tmux-ls

# Select "🚀 New Workspace"
# Multi-select sessions (Space to toggle, Enter to confirm):
[x] api
[x] frontend
[x] database

# Choose layout:
> Grid (equal-sized panes)
  Horizontal (side-by-side)
  Vertical (stacked)

# Press Enter
```

**Result**: A new tmux session opens with all three sessions visible in split panes using the grid layout.

---

## Configuration

### Generate Default Config

```bash
tmux-ls config init
```

This creates `~/.config/tmux-ls/config.yml` with default settings:

```yaml
version: "1.0"

ui:
  theme: "charm"
  colors:
    primary: "#00D9FF"
    success: "#00FF00"
    warning: "#FFA500"

workspace:
  default_layout: "grid"
  min_sessions: 2
  max_sessions: 4

cleanup:
  stale_threshold_minutes: 30
  require_confirmation: true

telemetry:
  enabled: false
```

---

### Customize Your Setup

Edit the config file:

```bash
# macOS/Linux
vim ~/.config/tmux-ls/config.yml

# Or use your preferred editor
nano ~/.config/tmux-ls/config.yml
```

**Common customizations**:

```yaml
# Change default workspace layout
workspace:
  default_layout: "horizontal"  # or "vertical", "grid"

# Adjust stale session threshold
cleanup:
  stale_threshold_minutes: 60  # 1 hour instead of 30 minutes

# Enable telemetry (local only, no network calls)
telemetry:
  enabled: true

# Customize colors
ui:
  colors:
    primary: "#FF00FF"  # Magenta accent
```

---

### Validate Your Config

```bash
tmux-ls config validate
```

**Output**:
```
✓ Configuration is valid
  All required fields present and correct.
```

---

## Advanced Features

### Save Workspace as Template

After creating a workspace, you can save it for future use:

1. Build a workspace via interactive menu
2. When prompted "Save as template?", enter a name (e.g., "fullstack")
3. Template saved to `~/.config/tmux-ls/workspaces/fullstack.yml`

**Load template later**:
```bash
tmux-ls workspace create fullstack
```

---

### Clean Up Stale Sessions

Remove sessions that have been idle for a while:

```bash
tmux-ls cleanup
```

**Interactive mode**:
```
Found 3 stale sessions (idle > 30m, no clients):

[x] old-test      (idle 2h 15m, 1 window)
[x] temp-session  (idle 45m, 2 windows)
[ ] dev-backup    (idle 35m, 3 windows)

Select sessions to kill (Space to toggle, Enter to confirm):
```

**Dry run** (see what would be deleted without doing it):
```bash
tmux-ls cleanup --dry-run
```

---

### View Usage Statistics

If telemetry is enabled, see your tmux usage patterns:

```bash
# Enable telemetry first (edit config)
vim ~/.config/tmux-ls/config.yml
# Set telemetry.enabled: true

# Use tmux-ls for a while...

# View stats
tmux-ls stats
```

**Output**:
```
tmux-ls Usage Statistics (last 7 days)

📊 Total Actions: 142
  - attach:           65 (45.8%)
  - workspace_create: 23 (16.2%)
  - switch:           30 (21.1%)

🔥 Most Used Sessions:
  1. dev-api          (35 attaches)
  2. staging          (18 attaches)
  3. test-suite       (12 attaches)

🚀 Workspaces Created: 23
  - grid layout:      15 (65%)
```

**Export to JSON**:
```bash
tmux-ls stats --export my-stats.json
```

---

## Tips & Tricks

### Alias for Speed

Add to your shell config (`~/.bashrc`, `~/.zshrc`):

```bash
alias t='tmux-ls'
```

Now just type `t` to launch tmux-ls.

---

### Keyboard Shortcuts Inside tmux

Create a tmux keybinding to launch tmux-ls:

```bash
# Add to ~/.tmux.conf
bind-key S run-shell 'tmux-ls'
```

Reload tmux config:
```bash
tmux source-file ~/.tmux.conf
```

Now press `Ctrl+b S` to launch the quick switcher.

---

### Prevent Accidental Session Kill

In your config, ensure confirmations are enabled:

```yaml
cleanup:
  require_confirmation: true
```

This prevents accidental session termination.

---

### Use Custom Layouts

For advanced users, you can specify custom tmux layout strings:

```yaml
# In workspace template
layout_type: "custom"
layout_string: "2d3a,272x68,0,0{136x68,0,0,0,135x68,137,0[135x34,137,0,1,135x33,137,35,2]}"
```

Get your current layout string with:
```bash
tmux list-windows -F "#{window_layout}"
```

---

## Troubleshooting

### tmux-ls: command not found

**Cause**: tmux-ls not in PATH.

**Solution**:
```bash
# Check install location
which tmux-ls

# If installed to ~/.local/bin, add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

### tmux server not running

**Cause**: tmux server hasn't been started yet.

**Solution**:
```bash
# Create a session first
tmux new-session -s initial
```

---

### gum not found (degraded mode)

**Cause**: gum dependency not installed.

**Solution** (recommended - install gum):
```bash
# macOS
brew install gum

# Linux (see https://github.com/charmbracelet/gum#installation)
```

**Workaround** (use without gum):
tmux-ls will automatically fall back to basic bash `select` menus if gum is unavailable. The experience is less polished but functional.

---

### Config validation errors

**Cause**: Invalid YAML syntax or values.

**Solution**:
```bash
# Validate and see specific errors
tmux-ls config validate

# Reset to defaults
mv ~/.config/tmux-ls/config.yml ~/.config/tmux-ls/config.yml.bak
tmux-ls config init
```

---

### Sessions not appearing in list

**Cause**: tmux server issue or permission problem.

**Solution**:
```bash
# Verify sessions exist
tmux list-sessions

# Restart tmux server (CAUTION: kills all sessions)
tmux kill-server
tmux new-session -s test
```

---

## What's Next?

### Learn More

- **Full CLI Reference**: See `tmux-ls --help` or `contracts/cli-interface.md`
- **Data Model**: Understand entities and relationships in `data-model.md`
- **Implementation Plan**: Technical details in `plan.md`

---

### Explore Advanced Workflows

1. **Session Templates**: Save common session configurations
2. **Custom Keybindings**: Integrate tmux-ls into your tmux workflow
3. **Workspace Automation**: Script workspace creation for specific projects
4. **Telemetry Analysis**: Export and visualize your tmux usage patterns

---

### Contribute

Found a bug or want a feature?
- **Issues**: https://github.com/waystid/tmux-ls/issues
- **Pull Requests**: https://github.com/waystid/tmux-ls/pulls
- **Discussions**: https://github.com/waystid/tmux-ls/discussions

---

## Quick Reference Card

| Task | Command |
|------|---------|
| Launch interactive menu | `tmux-ls` |
| Quick switcher (inside tmux) | `tmux-ls` |
| Create config file | `tmux-ls config init` |
| Validate config | `tmux-ls config validate` |
| Show current config | `tmux-ls config show` |
| View usage stats | `tmux-ls stats` |
| Clean up stale sessions | `tmux-ls cleanup` |
| List workspace templates | `tmux-ls workspace list` |
| Create workspace from template | `tmux-ls workspace create <name>` |
| Kill a session | `tmux-ls session kill <name>` |
| Rename a session | `tmux-ls session rename <old> <new>` |
| Show version | `tmux-ls --version` |
| Show help | `tmux-ls --help` |

---

**You're all set!** Start managing your tmux sessions like a pro with tmux-ls.

For questions or feedback, visit: https://github.com/waystid/tmux-ls
