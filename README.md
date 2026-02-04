# DevTools

System configuration and development tools automation for Ubuntu Cinnamon.

This repository contains a Python CLI tool to automate the setup of a fresh Ubuntu Cinnamon installation, replicating a pre-configured development environment including desktop settings, shell tools, themes, and applications.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [What Gets Installed](#what-gets-installed)
3. [Installation Guide](#installation-guide)
4. [Commands](#commands)
5. [Restore / Rollback](#restore--rollback)
6. [Configuration Export](#configuration-export)
7. [Manual Steps](#manual-steps)
8. [Architecture](#architecture)
9. [Development](#development)

---

## Quick Start

### Fresh Installation (New System)

```bash
# 1. Clone this repository
git clone https://github.com/felipevaldes/DevTools.git
cd DevTools

# 2. Run the bootstrap script (installs uv, Python, and runs CLI)
./bootstrap.sh

# Or with options:
./bootstrap.sh install --skip-snap    # Skip Snap removal
./bootstrap.sh install --dry-run      # Preview changes
```

### Export Settings (From Current System)

```bash
# Export Cinnamon settings
./bootstrap.sh export-cinnamon

# Export Firefox extensions and bookmarks
./bootstrap.sh export-firefox
```

### Restore to Fresh State

```bash
./bootstrap.sh restore
```

---

## What Gets Installed

### Package Manager Migration

| From | To | Notes |
|------|-----|-------|
| Snap | Flatpak | Snap is completely removed and blocked |

### Desktop Environment

| Component | Description |
|-----------|-------------|
| WhiteSur-Dark theme | macOS-style GTK theme |
| WhiteSur-dark icons | macOS-style icon theme |
| McMojave-cursors | macOS-style cursor theme |
| San Francisco, Source Code Pro, Iosevka Term, and other fonts | Custom and system fonts (incl. Apple's) |

### Shell Tools

| Tool | Description |
|------|-------------|
| Starship | Cross-shell prompt with Git integration |
| tmux + TPM | Terminal multiplexer with plugin manager |
| Vim + Vundle | Text editor with plugin manager |

### Applications

| Application | Description |
|-------------|-------------|
| Tabby | Modern terminal emulator |
| Ulauncher | Application launcher |
| Plank | macOS-style dock |

### Flatpak Apps (Replacing Snap)

| Application | Flatpak ID |
|-------------|------------|
| Spotify | com.spotify.Client |
| Firefox | org.mozilla.firefox |
| VLC | org.videolan.VLC |
| Discord | com.discordapp.Discord |

---

## Installation Guide

### Prerequisites

- Ubuntu Cinnamon (tested on 22.04+)
- Internet connection
- sudo privileges
- curl or wget

### Step-by-Step Installation

```bash
# 1. Clone the repository
git clone https://github.com/felipevaldes/DevTools.git
cd DevTools

# 2. Run bootstrap (handles everything)
./bootstrap.sh
```

The bootstrap script will:
1. Install **uv** (Python package manager)
2. Install **Python 3.12** via uv
3. Install Python dependencies
4. Run the `devtools install` command

### What the installer does

1. Updates system packages
2. Installs system dependencies (curl, git, build-essential, etc.)
3. Installs fonts
4. Installs wallpapers
5. Configures shell tools (Starship, tmux, Vim)
6. **Removes Snap** and sets up **Flatpak**
7. Installs Cinnamon themes
8. Applies Cinnamon settings
9. Configures Firefox (if exported settings exist)

---

## Commands

### Main Commands

```bash
# Full installation
./bootstrap.sh install

# Installation options
./bootstrap.sh install --dry-run       # Preview without changes
./bootstrap.sh install --skip-snap     # Keep Snap, skip Flatpak
./bootstrap.sh install --skip-firefox  # Skip Firefox configuration
./bootstrap.sh install --skip-themes   # Skip theme installation
./bootstrap.sh install -y              # Answer yes to all prompts

# Restore to pre-installation state
./bootstrap.sh restore
./bootstrap.sh restore --dry-run

# Export settings from current system
./bootstrap.sh export-cinnamon
./bootstrap.sh export-firefox

# Apply Cinnamon settings
./bootstrap.sh apply-cinnamon
./bootstrap.sh apply-cinnamon --config path/to/config.conf
./bootstrap.sh apply-cinnamon --dry-run

# List available configurations
./bootstrap.sh list-configs

# Show version
./bootstrap.sh --version
```

### Direct Python CLI (after bootstrap)

```bash
# Using uv run
uv run devtools install
uv run devtools export-cinnamon
uv run devtools --help
```

---

## Restore / Rollback

The `restore` command reverts changes made by `install`.

```bash
./bootstrap.sh restore
```

This will:
- Remove installed packages
- Remove themes from `~/.themes/` and `~/.icons/`
- Remove fonts
- Remove wallpapers
- Restore backed-up config files
- Reset Cinnamon settings

### Important Notes

- Restore reads from `~/.config/devtools_changes.log`
- Backups are stored with `.devtools_backup` suffix
- Snap will NOT be reinstalled (blocked via apt preferences)

---

## Configuration Export

### Cinnamon Settings

```bash
./bootstrap.sh export-cinnamon
```

Exports:
- **dconf settings** → `config_files/cinnamon/{hostname}_{date}_cinnamon.conf`
- **Applet configs** → `config_files/cinnamon/{hostname}_{date}_spices/`
- **Custom keybindings** → Included in `.conf` file

### Firefox Settings

```bash
./bootstrap.sh export-firefox
```

Exports:
- **Extensions** → `config_files/firefox/extensions.json`
- **Bookmarks** → `config_files/firefox/bookmarks.json` and `bookmarks.html`

### Config File Structure

```
config_files/
├── cinnamon/
│   ├── current.conf              → symlink to active config
│   ├── current_spices            → symlink to active spices
│   └── voyager_20260203_cinnamon.conf
│       voyager_20260203_spices/
├── firefox/
│   ├── extensions.json
│   ├── bookmarks.json
│   └── bookmarks.html
├── .bashrc
├── .bash_aliases
├── .vimrc
├── .tmux.conf
├── starship.toml
└── tabby_config.yaml
```

---

## Manual Steps

These steps **cannot be automated** and must be done after installation:

### 1. Install Cinnamon Applets

Open **Cinnamon Settings > Applets > Download** and install:

| Applet | Purpose |
|--------|---------|
| Cinnamenu | Enhanced application menu |
| Weather | Weather display in panel |
| Sound 150% | Extended volume control |

### 2. Install Cinnamon Extensions

Open **Cinnamon Settings > Extensions > Download** and install:

| Extension | Purpose |
|-----------|---------|
| Transparent Panels | Makes panels translucent |

### 3. Configure Vim Plugins

```bash
vim +PluginInstall +qall
```

### 4. Install tmux Plugins

```bash
tmux
# Press prefix + I (default: Ctrl-b + I)
```

### 5. Import Firefox Bookmarks

If you exported bookmarks:
1. Open Firefox: `Ctrl+Shift+O`
2. Import and Backup > Import from HTML
3. Select `config_files/firefox/bookmarks.html`

### 6. Set Wallpaper

- Open **Cinnamon Settings > Backgrounds**
- Navigate to `/usr/share/backgrounds/big_sur/`

---

## Architecture

### Directory Structure

```
DevTools/
├── bootstrap.sh              # Entry point - installs uv and runs CLI
├── pyproject.toml            # Python project configuration
├── src/
│   └── devtools/
│       ├── __init__.py
│       ├── main.py           # Typer CLI entry point
│       ├── config.py         # Configuration constants
│       ├── logger.py         # Rich logging utilities
│       ├── utils.py          # Shell commands, file operations
│       ├── system.py         # Packages, fonts, wallpapers
│       ├── cinnamon.py       # Cinnamon settings export/import
│       ├── firefox.py        # Firefox extensions/bookmarks
│       ├── flatpak.py        # Snap removal, Flatpak setup
│       └── shell_tools.py    # Starship, tmux, Vim configs
├── config_files/             # Configuration files to deploy
├── fonts/                    # Font files
└── wallpapers/               # Wallpaper archives
```

### Technology Stack

| Component | Technology |
|-----------|------------|
| Package Manager | uv (manages Python + dependencies) |
| Python Version | 3.12+ (installed via uv) |
| CLI Framework | Typer |
| Output/Logging | Rich |

### Flow Diagram

```
bootstrap.sh
    │
    ├── Install uv
    ├── uv python install 3.12
    ├── uv sync (install deps)
    │
    └── uv run devtools install
            │
            ├── system.py      → packages, fonts, wallpapers
            ├── shell_tools.py → starship, tmux, vim
            ├── flatpak.py     → snap removal, flatpak
            ├── cinnamon.py    → themes, settings
            └── firefox.py     → extensions, bookmarks
```

### Changes Log

All modifications are logged to `~/.config/devtools_changes.log`:

```
[2026-02-03 09:30:15] [PACKAGE] Installed curl | apt
[2026-02-03 09:30:20] [FONTS] Installed fonts | /home/user/.local/share/fonts
[2026-02-03 09:30:25] [SNAP] Removed snap package | firefox
[2026-02-03 09:30:30] [FLATPAK] Installed Flatpak app | org.mozilla.firefox
```

---

## Development

### Setup Development Environment

```bash
# Clone repo
git clone https://github.com/felipevaldes/DevTools.git
cd DevTools

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Sync dependencies
uv sync

# Run CLI
uv run devtools --help
```

### Adding New Features

#### Add a new command

Edit `src/devtools/main.py`:

```python
@app.command()
def my_command(
    option: bool = typer.Option(False, "--option", help="Description"),
) -> None:
    """Command description."""
    from .my_module import my_function
    my_function()
```

#### Add a new module

1. Create `src/devtools/my_module.py`
2. Import in command
3. Use utilities from `utils.py` and `logger.py`

### Testing

```bash
# Dry-run installation
uv run devtools install --dry-run

# Test specific command
uv run devtools export-cinnamon
```

---

## Troubleshooting

### uv not found after bootstrap

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Snap apps still appearing

```bash
# Check if snapd is really removed
which snap
dpkg -l snapd

# Verify nosnap preference
cat /etc/apt/preferences.d/nosnap.pref
```

### Flatpak apps not in menu

Log out and log back in, or:

```bash
# Refresh app database
update-desktop-database ~/.local/share/applications
```

### Cinnamon settings not applying

```bash
# Reload Cinnamon
cinnamon --replace &

# Or check for errors
uv run devtools apply-cinnamon 2>&1 | grep -i error
```

---

## License

MIT License - Feel free to use and modify.
