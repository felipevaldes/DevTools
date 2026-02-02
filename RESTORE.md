# Restore Script Documentation

## Overview

The `restore.sh` script reverts all changes made by `install.sh`, restoring your system to a fresh Ubuntu Cinnamon state.

## What Gets Restored

### 1. **Cinnamon Settings**
- Restores from backup created during installation
- If no backup exists, resets key settings to defaults
- Includes themes, panel configuration, keybindings, etc.

### 2. **Installed Packages**
Removes packages installed by `install.sh`:
- `tmux`
- `vim`
- `tabby-terminal`
- `ulauncher`
- `plank`
- `starship` (if installed via script)
- Also removes any packages logged in the changes log

### 3. **Configuration Files**
Restores or removes:
- `~/.bashrc`
- `~/.bash_aliases`
- `~/.vimrc`
- `~/.tmux.conf`
- `~/.config/starship.toml`
- `~/.config/tabby/config.yaml`

If backups exist, files are restored from backup. Otherwise, files are removed (with warnings for important files).

### 4. **Fonts**
Removes fonts installed from `fonts/` directory:
- San Francisco fonts
- Source Code Pro
- Iosevka Term
- AvantGarde
- Radio Space

### 5. **Wallpapers**
Removes wallpapers installed to `/usr/share/backgrounds/big_sur/`

### 6. **Installed Tools**
Removes:
- Starship binary (`~/.local/bin/starship`)
- TPM (Tmux Plugin Manager)
- Vundle (Vim plugin manager)
- Vim backup/swap directories (if empty)

### 7. **Cinnamon Themes**
- Notes that system-wide themes require manual removal
- Removes user-specific Plank themes

### 8. **Desktop Files & Icons**
- Removes RemNote desktop file
- Removes RemNote icon

### 9. **Repositories & PPAs**
- Removes Tabby repository
- Removes Ulauncher PPA

### 10. **Logs & Backups** (Optional)
- Optionally removes installation logs and backups

## Usage

### Basic Usage

```bash
./restore.sh
```

The script will:
1. Check for changes log
2. Ask for confirmation
3. Restore each component systematically
4. Log all restore actions

### What to Expect

1. **Confirmation Prompt**: The script asks for confirmation before proceeding
2. **Progress Messages**: Shows what's being restored
3. **Warnings**: Some operations may show warnings (e.g., themes require manual removal)
4. **Final Summary**: Shows restore log location

## How It Works

### Reading Changes Log

The script reads `${HOME}/.config/devtools_changes.log` to determine what was changed during installation.

### Backup Detection

The script looks for backups in:
1. `${HOME}/.config/devtools_backup_location` - Points to main backup directory
2. `${HOME}/.config/cinnamon_backup_*` - Cinnamon settings backups

### Restore Process

1. **Cinnamon Settings**: Restores from backup or resets to defaults
2. **Packages**: Removes via `apt remove`
3. **Config Files**: Restores from backup or removes
4. **Fonts**: Removes installed fonts
5. **Wallpapers**: Removes wallpaper directory
6. **Tools**: Removes binaries and plugin managers
7. **Themes**: Notes manual removal required
8. **Desktop Files**: Removes desktop files and icons
9. **Cleanup**: Optionally removes logs and backups

## Limitations

### System-Wide Themes

Cinnamon themes (GTK, icons, cursors) are installed system-wide and cannot be automatically removed. The script will:
- Note that manual removal is required
- Remove user-specific theme files (Plank themes)

To manually remove themes:
```bash
# Themes are typically in:
/usr/share/themes/WhiteSur-Dark
/usr/share/icons/WhiteSur-dark
/usr/share/icons/McMojave-cursors
```

### Panel Applets & Extensions

Panel applets and extensions that were installed manually cannot be automatically removed. You'll need to:
- Remove applets via `Cinnamon Settings > Applets`
- Remove extensions via `Cinnamon Settings > Extensions`

### Some Config Files

If config files were modified after installation (not just by install.sh), the restore script may not fully restore them. The script will warn about this.

## Restore Log

All restore actions are logged to:
```
${HOME}/.config/devtools_restore.log
```

This log includes:
- Timestamp of each restore action
- What was restored/removed
- Details about the operation

## Safety Features

1. **Confirmation Required**: Script asks for confirmation before proceeding
2. **Non-Destructive**: Uses `set +e` to continue even if some operations fail
3. **Backup Preservation**: Optionally keeps backups for reference
4. **Warnings**: Warns about files that can't be automatically restored

## After Restore

After running the restore script:

1. **Logout/Login**: Some changes (especially Cinnamon settings) require logout/login
2. **Restart**: A full restart may be needed for all changes to take effect
3. **Manual Cleanup**: Remove system-wide themes manually if needed
4. **Check Logs**: Review `devtools_restore.log` to see what was restored

## Troubleshooting

### "Changes log not found"

This means `install.sh` was never run, or the log was deleted. Nothing to restore.

### "No backup found" for Cinnamon settings

The script will reset Cinnamon settings to defaults instead of restoring from backup.

### Packages won't remove

Some packages may have dependencies. The script uses `apt remove` which should handle this, but you may need to manually clean up with `apt autoremove`.

### Config files not restored

If backups don't exist, the script will remove config files. For important files like `.bashrc`, it will warn instead of removing.

## Example Output

```
==========================================
  System Restore - Revert Install.sh
==========================================

WARNING: This will revert all changes made by install.sh
...

Found 45 changes to restore

==========================================
Restoring Cinnamon settings...
  Found backup: /home/user/.config/cinnamon_backup_20250201_160000
  ✓ Restored Cinnamon settings
  ✓ Restored panel settings

==========================================
Removing installed packages...
  ✓ Removed package: tmux
  ✓ Removed package: vim
  ...

==========================================
Restore complete!
```
