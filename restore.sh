#!/bin/bash
#
# Restore Script - Reverts all changes made by install.sh
# Restores system to fresh Ubuntu Cinnamon state
#

set +e  # Don't exit on error during rollback

# Source common utilities
source common.sh

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANGES_LOG="${HOME}/.config/devtools_changes.log"
RESTORE_LOG="${HOME}/.config/devtools_restore.log"

# Initialize restore logging
init_restore_logging() {
    mkdir -p "$(dirname "$RESTORE_LOG")"
    echo "=== Restore started at $(date) ===" >> "$RESTORE_LOG"
}

# Log restore action
log_restore() {
    local action="$1"
    local details="${2:-}"
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $action | $details" >> "$RESTORE_LOG"
    print_green "  ✓ $action"
}

# Check if changes log exists
check_changes_log() {
    if [ ! -f "$CHANGES_LOG" ]; then
        print_red "Changes log not found: $CHANGES_LOG"
        print_yellow "No installation changes detected. Nothing to restore."
        exit 1
    fi
    
    local change_count=$(grep -c "^\[" "$CHANGES_LOG" 2>/dev/null || echo "0")
    if [ "$change_count" -eq 0 ]; then
        print_yellow "Changes log is empty. Nothing to restore."
        exit 0
    fi
    
    print_blue "Found $change_count changes to restore"
}

# Restore Cinnamon settings from backup
restore_cinnamon_settings() {
    print_blue "Restoring Cinnamon settings..."
    
    # Find the most recent backup directory
    local backup_dirs=("${HOME}"/.config/cinnamon_backup_*)
    local latest_backup=""
    
    if [ ${#backup_dirs[@]} -gt 0 ] && [ -e "${backup_dirs[0]}" ]; then
        # Sort by modification time, get most recent
        latest_backup=$(ls -td "${HOME}"/.config/cinnamon_backup_* 2>/dev/null | head -1)
    fi
    
    if [ -n "$latest_backup" ] && [ -d "$latest_backup" ]; then
        print_blue "  Found backup: $latest_backup"
        
        if [ -f "${latest_backup}/cinnamon.dconf" ]; then
            dconf load /org/cinnamon/ < "${latest_backup}/cinnamon.dconf" 2>/dev/null
            log_restore "Restored Cinnamon settings" "from ${latest_backup}/cinnamon.dconf"
        fi
        
        if [ -f "${latest_backup}/panels.dconf" ]; then
            dconf load /org/cinnamon/panels/ < "${latest_backup}/panels.dconf" 2>/dev/null
            log_restore "Restored panel settings" "from ${latest_backup}/panels.dconf"
        fi
    else
        print_yellow "  No Cinnamon backup found, resetting to defaults..."
        
        # Reset key Cinnamon settings to defaults
        gsettings reset org.cinnamon.theme name 2>/dev/null || true
        gsettings reset org.cinnamon.desktop.interface gtk-theme 2>/dev/null || true
        gsettings reset org.cinnamon.desktop.interface icon-theme 2>/dev/null || true
        gsettings reset org.cinnamon.desktop.interface cursor-theme 2>/dev/null || true
        gsettings reset org.cinnamon.desktop.interface font-name 2>/dev/null || true
        gsettings reset org.cinnamon.desktop.wm.preferences titlebar-font 2>/dev/null || true
        gsettings reset org.cinnamon.desktop.keybindings.wm close 2>/dev/null || true
        gsettings reset org.cinnamon panels-enabled 2>/dev/null || true
        gsettings reset org.cinnamon enabled-applets 2>/dev/null || true
        gsettings reset org.cinnamon enabled-extensions 2>/dev/null || true
        
        log_restore "Reset Cinnamon settings" "to defaults"
    fi
}

# Remove installed packages
remove_packages() {
    print_blue "Removing installed packages..."
    
    # Packages installed by install.sh
    local packages=(
        "tmux"
        "vim"
        "tabby-terminal"
        "ulauncher"
        "plank"
        "starship"  # May be installed via script
    )
    
    # Also check for packages logged in changes
    local logged_packages=$(grep "^\[.*\] \[PACKAGE\]" "$CHANGES_LOG" | grep -o "Installed package | [^|]*" | cut -d'|' -f2 | tr -d ' ' | sort -u)
    
    local packages_to_remove=()
    
    # Add packages from changes log
    while IFS= read -r pkg; do
        [ -n "$pkg" ] && packages_to_remove+=("$pkg")
    done <<< "$logged_packages"
    
    # Add hardcoded packages
    for pkg in "${packages[@]}"; do
        packages_to_remove+=("$pkg")
    done
    
    # Remove duplicates and check if installed
    local unique_packages=($(printf '%s\n' "${packages_to_remove[@]}" | sort -u))
    
    for pkg in "${unique_packages[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            sudo apt remove -y "$pkg" >> "$RESTORE_LOG" 2>&1
            log_restore "Removed package" "$pkg"
        fi
    done
    
    # Remove Tabby repository if it was added
    if [ -f /etc/apt/sources.list.d/tabby.list ]; then
        sudo rm -f /etc/apt/sources.list.d/tabby.list
        log_restore "Removed Tabby repository" "/etc/apt/sources.list.d/tabby.list"
    fi
    
    # Remove Ulauncher PPA if it was added
    if grep -q "agornostal/ulauncher" /etc/apt/sources.list.d/*.list 2>/dev/null; then
        sudo add-apt-repository --remove -y ppa:agornostal/ulauncher >> "$RESTORE_LOG" 2>&1
        log_restore "Removed Ulauncher PPA"
    fi
    
    # Clean up
    sudo apt autoremove -y >> "$RESTORE_LOG" 2>&1
    sudo apt autoclean >> "$RESTORE_LOG" 2>&1
}

# Remove installed fonts
remove_fonts() {
    print_blue "Removing installed fonts..."
    
    local fonts_dir="${HOME}/.local/share/fonts"
    
    if [ -d "$fonts_dir" ]; then
        # Check if fonts from install script exist
        if [ -d "${fonts_dir}/SanFranciscoFont-master" ] || \
           [ -d "${fonts_dir}/source-code-pro-2.030R-ro-1.050R-it" ] || \
           [ -d "${fonts_dir}/iosevka-term" ] || \
           [ -f "${fonts_dir}/AvantGarde_LT_Medium.ttf" ] || \
           [ -f "${fonts_dir}/Radio_Space.ttf" ]; then
            
            # Remove fonts installed by script
            rm -rf "${fonts_dir}/SanFranciscoFont-master" 2>/dev/null
            rm -rf "${fonts_dir}/source-code-pro-2.030R-ro-1.050R-it" 2>/dev/null
            rm -rf "${fonts_dir}/iosevka-term" 2>/dev/null
            rm -f "${fonts_dir}/AvantGarde_LT_Medium.ttf" 2>/dev/null
            rm -f "${fonts_dir}/Radio_Space.ttf" 2>/dev/null
            
            # Refresh font cache
            fc-cache -fv >> "$RESTORE_LOG" 2>&1
            log_restore "Removed installed fonts" "$fonts_dir"
        else
            print_yellow "  No fonts from install script found"
        fi
    fi
}

# Remove wallpapers
remove_wallpapers() {
    print_blue "Removing installed wallpapers..."
    
    local wallpaper_dir="/usr/share/backgrounds/big_sur"
    
    if [ -d "$wallpaper_dir" ]; then
        sudo rm -rf "$wallpaper_dir"
        log_restore "Removed wallpapers" "$wallpaper_dir"
    fi
}

# Restore configuration files
restore_config_files() {
    print_blue "Restoring configuration files..."
    
    # List of config files that might have been modified
    local config_files=(
        "${HOME}/.bashrc"
        "${HOME}/.bash_aliases"
        "${HOME}/.vimrc"
        "${HOME}/.tmux.conf"
        "${HOME}/.config/starship.toml"
        "${HOME}/.config/tabby/config.yaml"
    )
    
    # Try to find backups or remove files
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            # Check if this was installed by our script
            local file_name=$(basename "$config_file")
            if grep -q "Installed $file_name" "$CHANGES_LOG" 2>/dev/null; then
                # Try to find backup
                local backup_file=""
                
                # First check devtools_backup_location
                if [ -f "${HOME}/.config/devtools_backup_location" ]; then
                    local backup_dir=$(cat "${HOME}/.config/devtools_backup_location")
                    if [ -d "$backup_dir" ] && [ -f "${backup_dir}/config/${file_name}.backup" ]; then
                        backup_file="${backup_dir}/config/${file_name}.backup"
                    fi
                fi
                
                # Fallback to cinnamon_backup directories
                if [ -z "$backup_file" ]; then
                    local backup_dirs=("${HOME}"/.config/cinnamon_backup_*)
                    for backup_dir in "${backup_dirs[@]}"; do
                        if [ -d "$backup_dir" ] && [ -f "${backup_dir}/config/${file_name}.backup" ]; then
                            backup_file="${backup_dir}/config/${file_name}.backup"
                            break
                        fi
                    done
                fi
                
                # Also check for starship.toml.backup and tabby_config.yaml.backup
                if [ -z "$backup_file" ] && [ "$file_name" = "starship.toml" ]; then
                    if [ -f "${HOME}/.config/devtools_backup_location" ]; then
                        local backup_dir=$(cat "${HOME}/.config/devtools_backup_location")
                        [ -f "${backup_dir}/config/starship.toml.backup" ] && backup_file="${backup_dir}/config/starship.toml.backup"
                    fi
                fi
                
                if [ -z "$backup_file" ] && [ "$file_name" = "config.yaml" ] && [[ "$config_file" == *"tabby"* ]]; then
                    if [ -f "${HOME}/.config/devtools_backup_location" ]; then
                        local backup_dir=$(cat "${HOME}/.config/devtools_backup_location")
                        [ -f "${backup_dir}/config/tabby_config.yaml.backup" ] && backup_file="${backup_dir}/config/tabby_config.yaml.backup"
                    fi
                fi
                
                if [ -n "$backup_file" ] && [ -f "$backup_file" ]; then
                    cp "$backup_file" "$config_file"
                    log_restore "Restored config file" "$config_file (from backup)"
                else
                    # No backup found, remove if it matches our template
                    if [ "$file_name" = ".bashrc" ] || [ "$file_name" = ".bash_aliases" ] || \
                       [ "$file_name" = ".vimrc" ] || [ "$file_name" = ".tmux.conf" ]; then
                        # For these files, we'll just warn - user might have customizations
                        print_yellow "  Warning: $config_file was modified but no backup found"
                        print_yellow "  You may want to manually review/restore this file"
                    else
                        rm -f "$config_file"
                        log_restore "Removed config file" "$config_file"
                    fi
                fi
            fi
        fi
    done
}

# Remove installed tools
remove_tools() {
    print_blue "Removing installed tools..."
    
    # Starship
    if [ -f "${HOME}/.local/bin/starship" ]; then
        rm -f "${HOME}/.local/bin/starship"
        log_restore "Removed Starship" "${HOME}/.local/bin/starship"
    fi
    
    # TPM (Tmux Plugin Manager)
    if [ -d "${HOME}/.tmux/plugins/tpm" ]; then
        rm -rf "${HOME}/.tmux/plugins/tpm"
        log_restore "Removed TPM" "${HOME}/.tmux/plugins/tpm"
    fi
    
    # Vundle
    if [ -d "${HOME}/.vim/bundle/Vundle.vim" ]; then
        rm -rf "${HOME}/.vim/bundle/Vundle.vim"
        log_restore "Removed Vundle" "${HOME}/.vim/bundle/Vundle.vim"
    fi
    
    # Vim directories (if empty)
    if [ -d "${HOME}/.vim/backups" ]; then
        rmdir "${HOME}/.vim/backups" 2>/dev/null || true
    fi
    if [ -d "${HOME}/.vim/swaps" ]; then
        rmdir "${HOME}/.vim/swaps" 2>/dev/null || true
    fi
}

# Remove Cinnamon themes
remove_cinnamon_themes() {
    print_blue "Removing Cinnamon themes..."
    
    # Note: Themes are installed system-wide, so we need sudo
    # This is tricky because we need to know what was installed
    
    print_yellow "  Note: Theme removal requires manual steps:"
    print_yellow "  - WhiteSur GTK theme"
    print_yellow "  - WhiteSur icon theme"
    print_yellow "  - McMojave cursor theme"
    print_yellow "  These are installed system-wide and may require manual removal"
    print_yellow "  or reinstallation of default themes"
    
    # Remove Plank themes (user-specific)
    if [ -d "${HOME}/.local/share/plank/themes" ]; then
        rm -rf "${HOME}/.local/share/plank/themes/theme-Dark" 2>/dev/null
        rm -rf "${HOME}/.local/share/plank/themes/theme-Light" 2>/dev/null
        log_restore "Removed Plank themes" "${HOME}/.local/share/plank/themes"
    fi
}

# Remove desktop files and icons
remove_desktop_files() {
    print_blue "Removing desktop files and icons..."
    
    # RemNote desktop file
    if [ -f "${HOME}/.local/share/applications/remnote.desktop" ]; then
        rm -f "${HOME}/.local/share/applications/remnote.desktop"
        log_restore "Removed RemNote desktop file"
    fi
    
    # RemNote icon
    if [ -f "/usr/share/icons/remnote.png" ]; then
        sudo rm -f /usr/share/icons/remnote.png
        log_restore "Removed RemNote icon" "/usr/share/icons/remnote.png"
    fi
}

# Clean up logs and backups
cleanup_artifacts() {
    print_blue "Cleaning up installation artifacts..."
    
    if prompt_yes_no "Remove installation logs and backups?"; then
        # Remove logs
        rm -f "$CHANGES_LOG" 2>/dev/null
        log_restore "Removed changes log" "$CHANGES_LOG"
        
        # Remove backups (ask for confirmation)
        local backup_dirs=("${HOME}"/.config/cinnamon_backup_*)
        if [ ${#backup_dirs[@]} -gt 0 ] && [ -e "${backup_dirs[0]}" ]; then
            for backup_dir in "${backup_dirs[@]}"; do
                if [ -d "$backup_dir" ]; then
                    rm -rf "$backup_dir"
                    log_restore "Removed backup" "$backup_dir"
                fi
            done
        fi
    else
        print_yellow "  Keeping logs and backups for reference"
    fi
}

# Main restore function
main() {
    print_red "=========================================="
    print_red "  System Restore - Revert Install.sh"
    print_red "=========================================="
    echo
    
    print_red "WARNING: This will revert all changes made by install.sh"
    print_red "This includes:"
    print_red "  - Removing installed packages"
    print_red "  - Restoring/removing configuration files"
    print_red "  - Removing fonts, wallpapers, themes"
    print_red "  - Restoring Cinnamon settings"
    print_red "  - Removing desktop files and icons"
    echo
    
    if ! prompt_yes_no "Are you sure you want to continue?"; then
        print_yellow "Restore cancelled."
        exit 0
    fi
    
    init_restore_logging
    check_changes_log
    
    print_blue "=========================================="
    restore_cinnamon_settings
    
    print_blue "=========================================="
    remove_packages
    
    print_blue "=========================================="
    remove_fonts
    
    print_blue "=========================================="
    remove_wallpapers
    
    print_blue "=========================================="
    restore_config_files
    
    print_blue "=========================================="
    remove_tools
    
    print_blue "=========================================="
    remove_cinnamon_themes
    
    print_blue "=========================================="
    remove_desktop_files
    
    print_blue "=========================================="
    cleanup_artifacts
    
    print_blue "=========================================="
    print_green "Restore complete!"
    print_yellow ""
    print_yellow "Restore log: $RESTORE_LOG"
    print_yellow ""
    print_yellow "Note: Some changes may require logout/login or restart to take effect"
    print_yellow "Note: System-wide themes may require manual removal or default theme reinstallation"
}

# Run main function
main "$@"
