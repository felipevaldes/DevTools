# DevTools

System configuration and development tools automation for Ubuntu Cinnamon.

This repository contains scripts to automate the setup of a fresh Ubuntu Cinnamon installation, replicating a pre-configured development environment including desktop settings, shell tools, themes, and applications.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [What Gets Installed](#what-gets-installed)
3. [Installation Guide](#installation-guide)
4. [Restore / Rollback](#restore--rollback)
5. [Cinnamon Configuration](#cinnamon-configuration)
6. [Manual Steps](#manual-steps)
7. [Architecture](#architecture)
8. [Modifying the Scripts](#modifying-the-scripts)

---

## Quick Start

### Fresh Installation (New System)
```bash
# 1. Clone this repository
git clone https://github.com/felipevaldes/DevTools.git
cd DevTools

# 2. Run the installation script
./install.sh

# 3. Complete manual steps (see below)
```

### Export Settings (From Current System)
```bash
# Export your current Cinnamon settings
./export_cinnamon_settings.sh

# Commit the exported config files
git add config_files/cinnamon/
git commit -m "Export Cinnamon settings from $(hostname)"
```

### Restore to Fresh State
```bash
./restore.sh
```

---

## What Gets Installed

### Desktop Environment
| Component | Description |
|-----------|-------------|
| WhiteSur-Dark theme | macOS-style GTK theme |
| WhiteSur-dark icons | macOS-style icon theme |
| McMojave-cursors | macOS-style cursor theme |
| San Francisco fonts | Apple's system fonts |

### Shell Tools
| Tool | Description |
|------|-------------|
| Starship | Cross-shell prompt with Git integration |
| tmux | Terminal multiplexer |
| Vim + Vundle | Text editor with plugin manager |

### Applications
| Application | Description |
|-------------|-------------|
| Tabby | Modern terminal emulator |
| Albert | Application launcher |
| RemNote | Note-taking app (manual desktop entry) |

### Fonts
- San Francisco (Display & Text)
- Source Code Pro
- Iosevka Term
- Avant Garde LT Medium
- Radio Space

---

## Installation Guide

### Prerequisites
- Ubuntu Cinnamon (tested on 22.04+)
- Internet connection
- sudo privileges

### Step-by-Step Installation

```bash
# 1. Clone the repository
git clone https://github.com/felipevaldes/DevTools.git
cd DevTools

# 2. Make scripts executable (if needed)
chmod +x install.sh export_cinnamon_settings.sh cinnamon_settings.sh restore.sh

# 3. Run installation
./install.sh
```

The installer will:
1. ✅ Install system dependencies (curl, git, unzip, dconf-cli)
2. ✅ Install fonts to `/usr/share/fonts/`
3. ✅ Install wallpapers to `/usr/share/backgrounds/big_sur/`
4. ✅ Configure shell tools (Starship, tmux + TPM, Vim + Vundle)
5. ✅ Install Tabby terminal
6. ✅ Install desktop applications (Albert)
7. ✅ Install Cinnamon themes (WhiteSur GTK, icons, cursors)
8. ✅ Apply Cinnamon settings from config file
9. ✅ Create RemNote desktop entry

### After Installation
```bash
# Reload Cinnamon to apply changes
cinnamon --replace &

# Or log out and log back in
```

---

## Restore / Rollback

The `restore.sh` script reverts changes made by `install.sh`.

### Full Restore
```bash
./restore.sh
```

This will:
- Remove installed packages
- Remove themes from `~/.themes/` and `~/.icons/`
- Remove fonts from `/usr/share/fonts/`
- Remove wallpapers from `/usr/share/backgrounds/big_sur/`
- Restore backed-up config files (`.bashrc`, `.vimrc`, etc.)
- Reset Cinnamon settings to defaults

### Important Notes
- Restore reads from `~/.config/devtools_changes.log`
- Backups are stored with `.devtools_backup` suffix
- Cinnamon settings are reset using `gsettings reset`

---

## Cinnamon Configuration

### Export Your Settings
```bash
./export_cinnamon_settings.sh
```

This exports:
1. **dconf settings** → `{hostname}_{date}_cinnamon.conf`
   - Themes, fonts, panel configuration
   - Keybindings and shortcuts
   - Power, sound, and peripheral settings
   
2. **Applet/extension configs** → `{hostname}_{date}_spices/`
   - Weather applet settings
   - Cinnamenu configuration
   - All other applet JSON configs

3. **Custom keyboard shortcuts** → Included in `.conf` file

### Apply Settings
```bash
# Use current config (linked by export script)
./cinnamon_settings.sh

# Use specific config file
./cinnamon_settings.sh --config config_files/cinnamon/myconfig.conf

# Preview changes without applying
./cinnamon_settings.sh --dry-run

# List available configs
./cinnamon_settings.sh --list
```

### Config File Structure
```
config_files/cinnamon/
├── current.conf              → symlink to active config
├── current_spices            → symlink to active spices dir
├── voyager_20260203_cinnamon.conf
└── voyager_20260203_spices/
    ├── manifest.txt
    ├── Cinnamenu@json/
    │   └── 21.json
    ├── weather@mockturtl/
    │   └── 17.json
    └── ...
```

---

## Manual Steps

These steps **cannot be automated** and must be done after running `install.sh`:

### 1. Install Cinnamon Applets
Open **Cinnamon Settings > Applets > Download** and install:

| Applet | Purpose |
|--------|---------|
| `Cinnamenu` | Enhanced application menu |
| `Weather` | Weather display in panel |
| `Sound 150%` | Extended volume control |

### 2. Install Cinnamon Extensions
Open **Cinnamon Settings > Extensions > Download** and install:

| Extension | Purpose |
|-----------|---------|
| `Transparent Panels` | Makes panels translucent |

### 3. Configure Vim Plugins
```bash
vim +PluginInstall +qall
```

### 4. Install tmux Plugins
```bash
# Start tmux
tmux

# Press prefix + I (default: Ctrl-b + I) to install plugins
```

### 5. Compile YouCompleteMe (Optional)
```bash
cd ~/.vim/bundle/YouCompleteMe
./install.py --all
```

### 6. Albert Configuration
- Open Albert preferences
- Set hotkey (recommended: `Super + Space`)
- Import theme from `config_files/albert_themes/`

### 7. Set Wallpaper
- Open **Cinnamon Settings > Backgrounds**
- Navigate to `/usr/share/backgrounds/big_sur/`
- Select preferred wallpaper

---

## Architecture

### Directory Structure
```
DevTools/
├── install.sh                    # Main installation script
├── restore.sh                    # Rollback/restore script
├── export_cinnamon_settings.sh   # Export current Cinnamon config
├── cinnamon_settings.sh          # Apply Cinnamon config from file
├── common.sh                     # Shared utility functions
│
├── config_files/
│   ├── cinnamon/                 # Exported Cinnamon configs
│   │   ├── current.conf          # → symlink to active config
│   │   ├── current_spices        # → symlink to active spices
│   │   └── {host}_{date}_*.conf  # Config snapshots
│   │
│   ├── .bashrc                   # Bash configuration
│   ├── .bash_aliases             # Bash aliases
│   ├── .vimrc                    # Vim configuration
│   ├── .tmux.conf                # tmux configuration
│   ├── starship.toml             # Starship prompt config
│   └── tabby_config.yaml         # Tabby terminal config
│
├── fonts/                        # Font files
│   ├── SanFranciscoFont-master/
│   ├── source-code-pro-*/
│   └── ...
│
├── wallpapers/                   # Wallpaper archives
│   └── wallpapers.tar.gz         # Downloaded from GitHub Release
│
└── remnote/                      # RemNote desktop entry
    ├── remnote.desktop
    └── remnote.png
```

### Script Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         install.sh                               │
├─────────────────────────────────────────────────────────────────┤
│  1. init_logging()          Create changes log                  │
│  2. check_system()          Verify Ubuntu Cinnamon              │
│  3. install_dependencies()  apt install curl, git, etc.         │
│  4. install_fonts()         Copy fonts to /usr/share/fonts      │
│  5. install_wallpapers()    Extract to /usr/share/backgrounds   │
│  6. install_shell_tools()   Starship, tmux, Vim configs         │
│  7. install_terminal_apps() Tabby terminal                      │
│  8. install_desktop_apps()  Albert launcher                     │
│  9. install_cinnamon_themes() WhiteSur GTK, icons, cursors      │
│ 10. configure_cinnamon()    Apply settings via cinnamon_settings│
│ 11. configure_remnote()     Create desktop entry                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    cinnamon_settings.sh                         │
├─────────────────────────────────────────────────────────────────┤
│  Reads: config_files/cinnamon/current.conf                      │
│  Reads: config_files/cinnamon/current_spices/                   │
│                                                                 │
│  • Parses INI-style config file                                 │
│  • Applies each setting with gsettings set                      │
│  • Copies applet JSON configs to ~/.config/cinnamon/spices/     │
└─────────────────────────────────────────────────────────────────┘
```

### Changes Log

All modifications are logged to `~/.config/devtools_changes.log`:

```
[2026-02-03 09:30:15] [PACKAGE] Installed curl | apt
[2026-02-03 09:30:20] [FONTS] Installed San Francisco | /usr/share/fonts/
[2026-02-03 09:30:25] [CONFIG] Installed .bashrc | /home/user/.bashrc
[2026-02-03 09:30:25] [BACKUP] Backed up .bashrc | /home/user/.bashrc.devtools_backup
[2026-02-03 09:30:30] [THEME] Installed WhiteSur-Dark | /home/user/.themes/
[2026-02-03 09:30:35] [CINNAMON] Applied settings | config_files/cinnamon/current.conf
```

This log is read by `restore.sh` to undo changes.

---

## Modifying the Scripts

### Adding a New Package

Edit `install.sh`, find the `install_dependencies()` function:

```bash
install_dependencies() {
    local packages=(
        "curl"
        "git"
        "your-new-package"  # ← Add here
    )
    # ...
}
```

### Adding a New Config File

1. Add the file to `config_files/`
2. Update `install_shell_tools()` in `install.sh`:

```bash
# Example: Adding a new config file
if [ -f "${SCRIPT_DIR}/config_files/.myconfig" ]; then
    backup_and_install "${SCRIPT_DIR}/config_files/.myconfig" "${HOME}/.myconfig"
fi
```

### Adding a New Theme

Edit `install.sh`, find the `install_cinnamon_themes()` function and add a new download block:

```bash
# Download and install your theme
if [ ! -d "${HOME}/.themes/YourTheme" ]; then
    git clone https://github.com/user/YourTheme.git /tmp/YourTheme
    cp -r /tmp/YourTheme/theme "${HOME}/.themes/YourTheme"
    log_change "THEME" "Installed YourTheme" "${HOME}/.themes/YourTheme"
fi
```

### Adding Custom Keybindings

1. Set up your keybindings in Cinnamon Settings
2. Run `./export_cinnamon_settings.sh` to capture them
3. Commit the updated config file

### Changing Cinnamon Settings

1. Configure Cinnamon as desired through Settings
2. Export: `./export_cinnamon_settings.sh`
3. The new settings will be in `config_files/cinnamon/`
4. Update the `current.conf` symlink if needed:
   ```bash
   cd config_files/cinnamon
   ln -sf yourconfig_cinnamon.conf current.conf
   ln -sf yourconfig_spices current_spices
   ```

### Testing Changes

```bash
# Dry-run to preview Cinnamon settings
./cinnamon_settings.sh --dry-run

# Test on a VM before deploying to real hardware
```

---

## Troubleshooting

### Cinnamon settings not applying
```bash
# Reload Cinnamon
cinnamon --replace &

# Or check for errors
./cinnamon_settings.sh 2>&1 | grep -i error
```

### Applets not showing in panel
1. Ensure applets are installed via Cinnamon Settings
2. The config only sets applet *positions*, not installations
3. After installing applets, they should appear automatically

### Themes not appearing
```bash
# Verify theme installation
ls ~/.themes/
ls ~/.icons/

# Rebuild font cache
sudo fc-cache -fv
```

### Restore script fails
```bash
# Check the changes log
cat ~/.config/devtools_changes.log

# Manual cleanup if needed
rm -rf ~/.themes/WhiteSur*
rm -rf ~/.icons/WhiteSur*
```

---

## Legacy Manual Steps

For reference, here are the original manual configuration steps this automation replaces:

<details>
<summary>Click to expand legacy instructions</summary>

1. Copy config files to ~/:
    ```
    cp .vimrc ~/
    cp .tmux.config ~/
    cp .bash_alias ~/
    ```    
2. Install Vundle, the plug-in manager for Vim:
    ```
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    ```
    - run vim and execute :PluginInstall
    
3. Create directories for swap files and backup:
    ```
    mkdir ~/.vim/backups
    mkdir ~/.vim/swaps
    ```

4. YouCompleteMe Plugin for Vim requires a compiled component:
    ```
    cd ~/.vim/bundle/YouCompleteMe
    ./install.py --all
    ```

5. Install Tmux Plugin Manager (TPM):
    ```
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ```
    - run tmux and execute tmux source ~/.tmux.conf
    - [prefix] + I to install all plugins

</details>

---

## License

MIT License - Feel free to use and modify these scripts.
