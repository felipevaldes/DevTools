#!/bin/bash
#
# Ubuntu Cinnamon System Configuration Script
# Designed for fresh Ubuntu Cinnamon installations
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Source common utilities
source common.sh

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_LOG="${HOME}/.config/devtools_install.log"
CHANGES_LOG="${HOME}/.config/devtools_changes.log"

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$INSTALL_LOG")"
    mkdir -p "$(dirname "$CHANGES_LOG")"
    echo "=== Installation started at $(date) ===" >> "$INSTALL_LOG"
    echo "=== Changes log started at $(date) ===" >> "$CHANGES_LOG"
}

# Log a change for rollback tracking
log_change() {
    local change_type="$1"
    local description="$2"
    local details="${3:-}"
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] [$change_type] $description | $details" >> "$CHANGES_LOG"
}

# Check if running on Ubuntu Cinnamon
check_system() {
    if [ ! -f /etc/os-release ]; then
        print_red "Cannot detect system. This script is designed for Ubuntu Cinnamon."
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        print_yellow "Warning: This script is designed for Ubuntu. Detected: $ID"
        if ! prompt_yes_no "Continue anyway?"; then
            exit 1
        fi
    fi
    
    if ! command -v cinnamon-settings &> /dev/null; then
        print_yellow "Warning: Cinnamon desktop environment not detected."
        if ! prompt_yes_no "Continue anyway?"; then
            exit 1
        fi
    fi
    
    print_green "System check passed: $PRETTY_NAME"
}

# Update system packages
update_system() {
    print_blue "Updating system packages..."
    sudo apt update -qq
    log_change "SYSTEM" "Updated package lists"
    print_green "System updated"
}

# Install system dependencies
install_dependencies() {
    print_blue "Installing system dependencies..."
    
    local packages=(
        "libcanberra-gtk-module"
        "libglib2.0-dev"
        "libxml2-utils"
        "shotwell"
        "git"
        "curl"
        "wget"
        "unzip"
        "build-essential"
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            sudo apt install -y "$package" >> "$INSTALL_LOG" 2>&1
            log_change "PACKAGE" "Installed package" "$package"
            print_green "  Installed: $package"
        else
            print_yellow "  Already installed: $package"
        fi
    done
    
    print_green "Dependencies installed"
}

# Install fonts
install_fonts() {
    print_blue "Installing custom fonts..."
    
    local fonts_dir="${HOME}/.local/share/fonts"
    mkdir -p "$fonts_dir"
    
    if [ -d "${SCRIPT_DIR}/fonts" ]; then
        cp -r "${SCRIPT_DIR}/fonts"/* "$fonts_dir/"
        log_change "FONTS" "Installed fonts" "${SCRIPT_DIR}/fonts -> $fonts_dir"
        
        # Refresh font cache
        fc-cache -fv >> "$INSTALL_LOG" 2>&1
        print_green "Fonts installed and cache refreshed"
    else
        print_yellow "Fonts directory not found, skipping..."
    fi
}

# Install wallpapers
install_wallpapers() {
    print_blue "Installing wallpapers..."
    
    local wallpaper_source="${SCRIPT_DIR}/wallpapers/BigSurWallpapers4K.zip"
    local wallpaper_dest="/usr/share/backgrounds/big_sur"
    
    if [ -f "$wallpaper_source" ]; then
        sudo mkdir -p "$wallpaper_dest"
        sudo cp "$wallpaper_source" "$wallpaper_dest/"
        cd "$wallpaper_dest"
        sudo unzip -q BigSurWallpapers4K.zip
        sudo rm BigSurWallpapers4K.zip
        sudo rm -rf __MACOSX 2>/dev/null || true
        
        log_change "WALLPAPERS" "Installed wallpapers" "$wallpaper_dest"
        print_green "Wallpapers installed"
    else
        print_yellow "Wallpaper file not found, skipping..."
    fi
}

# Install and configure shell tools

() {
    print_blue "Installing shell tools..."
    
    # Bash configuration
    if [ -f "${SCRIPT_DIR}/config_files/.bashrc" ]; then
        cp "${SCRIPT_DIR}/config_files/.bashrc" "${HOME}/.bashrc"
        log_change "CONFIG" "Installed .bashrc" "${HOME}/.bashrc"
    fi
    
    if [ -f "${SCRIPT_DIR}/config_files/.bash_aliases" ]; then
        cp "${SCRIPT_DIR}/config_files/.bash_aliases" "${HOME}/.bash_aliases"
        log_change "CONFIG" "Installed .bash_aliases" "${HOME}/.bash_aliases"
    fi
    
    # Starship prompt
    if [ -f "${SCRIPT_DIR}/config_files/starship.toml" ]; then
        if ! command -v starship &> /dev/null; then
            print_blue "  Installing Starship..."
            local temp_dir=$(mktemp -d)
            cd "$temp_dir"
            wget -q https://starship.rs/install.sh
            chmod +x install.sh
            mkdir -p "${HOME}/.local/bin"
            ./install.sh --bin-dir "${HOME}/.local/bin" -y >> "$INSTALL_LOG" 2>&1
            cd - > /dev/null
            rm -rf "$temp_dir"
            log_change "TOOL" "Installed Starship" "${HOME}/.local/bin/starship"
        fi
        
        mkdir -p "${HOME}/.config"
        cp "${SCRIPT_DIR}/config_files/starship.toml" "${HOME}/.config/starship.toml"
        log_change "CONFIG" "Installed starship.toml" "${HOME}/.config/starship.toml"
    fi
    
    print_green "Shell tools configured"
}

# Install terminal applications
install_terminal_apps() {
    print_blue "Installing terminal applications..."
    
    # Tmux
    if ! command -v tmux &> /dev/null; then
        sudo apt install -y tmux >> "$INSTALL_LOG" 2>&1
        log_change "PACKAGE" "Installed tmux" "tmux"
    fi
    
    if [ -f "${SCRIPT_DIR}/config_files/.tmux.conf" ]; then
        cp "${SCRIPT_DIR}/config_files/.tmux.conf" "${HOME}/.tmux.conf"
        log_change "CONFIG" "Installed .tmux.conf" "${HOME}/.tmux.conf"
        
        # Install TPM if not exists
        if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
            git clone -q https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
            log_change "TOOL" "Installed TPM" "${HOME}/.tmux/plugins/tpm"
        fi
    fi
    
    # Vim
    if ! command -v vim &> /dev/null; then
        sudo apt install -y vim >> "$INSTALL_LOG" 2>&1
        log_change "PACKAGE" "Installed vim" "vim"
    fi
    
    if [ -f "${SCRIPT_DIR}/config_files/.vimrc" ]; then
        cp "${SCRIPT_DIR}/config_files/.vimrc" "${HOME}/.vimrc"
        log_change "CONFIG" "Installed .vimrc" "${HOME}/.vimrc"
        
        # Install Vundle if not exists
        if [ ! -d "${HOME}/.vim/bundle/Vundle.vim" ]; then
            git clone -q https://github.com/VundleVim/Vundle.vim.git "${HOME}/.vim/bundle/Vundle.vim"
            log_change "TOOL" "Installed Vundle" "${HOME}/.vim/bundle/Vundle.vim"
        fi
        
        # Create vim directories
        mkdir -p "${HOME}/.vim/backups" "${HOME}/.vim/swaps"
    fi
    
    # Tabby terminal
    if ! command -v tabby &> /dev/null; then
        print_blue "  Installing Tabby..."
        curl -s https://packagecloud.io/install/repositories/eugeny/tabby/script.deb.sh | sudo bash >> "$INSTALL_LOG" 2>&1
        sudo apt install -y tabby-terminal >> "$INSTALL_LOG" 2>&1
        log_change "PACKAGE" "Installed Tabby" "tabby-terminal"
    fi
    
    if [ -f "${SCRIPT_DIR}/config_files/tabby_config.yaml" ]; then
        mkdir -p "${HOME}/.config/tabby"
        cp "${SCRIPT_DIR}/config_files/tabby_config.yaml" "${HOME}/.config/tabby/config.yaml"
        log_change "CONFIG" "Installed tabby config" "${HOME}/.config/tabby/config.yaml"
    fi
    
    print_green "Terminal applications installed"
}

# Install desktop applications
install_desktop_apps() {
    print_blue "Installing desktop applications..."
    
    # Ulauncher
    if ! command -v ulauncher &> /dev/null; then
        print_blue "  Installing Ulauncher..."
        sudo add-apt-repository -y ppa:agornostal/ulauncher >> "$INSTALL_LOG" 2>&1
        sudo apt update -qq
        sudo apt install -y ulauncher >> "$INSTALL_LOG" 2>&1
        log_change "PACKAGE" "Installed Ulauncher" "ulauncher"
    fi
    
    # Plank dock
    if ! command -v plank &> /dev/null; then
        sudo apt install -y plank >> "$INSTALL_LOG" 2>&1
        log_change "PACKAGE" "Installed Plank" "plank"
    fi
    
    print_green "Desktop applications installed"
}

# Install Cinnamon themes
install_cinnamon_themes() {
    print_blue "Installing Cinnamon themes..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # GTK Theme
    if [ ! -d "WhiteSur-gtk-theme" ]; then
        print_blue "  Installing WhiteSur GTK theme..."
        git clone -q git@github.com:felipevaldes/WhiteSur-gtk-theme.git 2>/dev/null || \
        git clone -q https://github.com/felipevaldes/WhiteSur-gtk-theme.git
        cd WhiteSur-gtk-theme
        sudo ./install.sh >> "$INSTALL_LOG" 2>&1
        cd ..
        log_change "THEME" "Installed WhiteSur GTK theme" "system-wide"
    fi
    
    # Icon Theme
    if [ ! -d "WhiteSur-icon-theme" ]; then
        print_blue "  Installing WhiteSur icon theme..."
        git clone -q git@github.com:felipevaldes/WhiteSur-icon-theme.git 2>/dev/null || \
        git clone -q https://github.com/felipevaldes/WhiteSur-icon-theme.git
        cd WhiteSur-icon-theme
        sudo ./install.sh >> "$INSTALL_LOG" 2>&1
        cd ..
        log_change "THEME" "Installed WhiteSur icon theme" "system-wide"
    fi
    
    # Cursor Theme
    if [ ! -d "McMojave-cursors" ]; then
        print_blue "  Installing McMojave cursor theme..."
        git clone -q git@github.com:felipevaldes/McMojave-cursors.git 2>/dev/null || \
        git clone -q https://github.com/felipevaldes/McMojave-cursors.git
        cd McMojave-cursors
        sudo ./install.sh >> "$INSTALL_LOG" 2>&1
        cd ..
        log_change "THEME" "Installed McMojave cursor theme" "system-wide"
    fi
    
    # Plank themes
    if [ -d "WhiteSur-gtk-theme/src/other/plank" ]; then
        mkdir -p "${HOME}/.local/share/plank/themes"
        cp -r WhiteSur-gtk-theme/src/other/plank/theme-Dark "${HOME}/.local/share/plank/themes/" 2>/dev/null || true
        cp -r WhiteSur-gtk-theme/src/other/plank/theme-Light "${HOME}/.local/share/plank/themes/" 2>/dev/null || true
        log_change "THEME" "Installed Plank themes" "${HOME}/.local/share/plank/themes"
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    print_green "Cinnamon themes installed"
}

# Configure Cinnamon desktop settings
configure_cinnamon() {
    print_blue "Configuring Cinnamon desktop..."
    
    # Export current settings for rollback
    local backup_dir="${HOME}/.config/cinnamon_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    dconf dump /org/cinnamon/ > "${backup_dir}/cinnamon.dconf" 2>/dev/null || true
    dconf dump /org/cinnamon/panels/ > "${backup_dir}/panels.dconf" 2>/dev/null || true
    log_change "BACKUP" "Backed up Cinnamon settings" "$backup_dir"
    
    # Apply theme settings
    gsettings set org.cinnamon.theme name "WhiteSur-Dark" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.interface gtk-theme "WhiteSur-Dark" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.interface icon-theme "WhiteSur-dark" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.interface cursor-theme "McMojave-cursors" 2>/dev/null || true
    
    log_change "CINNAMON" "Applied theme settings" "WhiteSur-Dark"
    
    print_yellow "Note: Some Cinnamon settings require manual configuration:"
    print_yellow "  - Panel configuration (position, applets)"
    print_yellow "  - Window manager settings"
    print_yellow "  - Extensions (Transparent Panels, etc.)"
    print_yellow "  See cinnamon/config_pictures/ for reference images"
    
    print_green "Cinnamon configuration applied"
}

# Configure RemNote
configure_remnote() {
    print_blue "Configuring RemNote..."
    
    if [ -f "${SCRIPT_DIR}/remnote/remnote.png" ]; then
        sudo cp "${SCRIPT_DIR}/remnote/remnote.png" /usr/share/icons/
        log_change "ICON" "Installed RemNote icon" "/usr/share/icons/remnote.png"
    fi
    
    if [ -f "${SCRIPT_DIR}/remnote/remnote.desktop" ]; then
        mkdir -p "${HOME}/.local/share/applications"
        cp "${SCRIPT_DIR}/remnote/remnote.desktop" "${HOME}/.local/share/applications/"
        log_change "DESKTOP" "Installed RemNote desktop file" "${HOME}/.local/share/applications/remnote.desktop"
    fi
    
    print_yellow "Note: Move RemNote AppImage to ~/.local/bin/ manually"
    print_green "RemNote configured"
}

# Main installation function
main() {
    print_blue "=========================================="
    print_blue "  Ubuntu Cinnamon System Configuration"
    print_blue "=========================================="
    echo
    
    init_logging
    check_system
    
    print_blue "=========================================="
    update_system
    
    print_blue "=========================================="
    install_dependencies
    
    print_blue "=========================================="
    install_fonts
    
    print_blue "=========================================="
    install_wallpapers
    
    print_blue "=========================================="
    install_shell_tools
    
    # print_blue "=========================================="
    # install_terminal_apps
    
    print_blue "=========================================="
    install_desktop_apps
    
    print_blue "=========================================="
    install_cinnamon_themes
    
    print_blue "=========================================="
    configure_cinnamon
    
    print_blue "=========================================="
    if prompt_yes_no "Configure RemNote?"; then
        configure_remnote
    fi
    
    print_blue "=========================================="
    print_green "Installation complete!"
    print_yellow "Installation log: $INSTALL_LOG"
    print_yellow "Changes log: $CHANGES_LOG"
    print_yellow ""
    print_yellow "Next steps:"
    print_yellow "  - Logout and login to apply all changes"
    print_yellow "  - Run 'vim' and execute ':PluginInstall' for Vim plugins"
    print_yellow "  - Run 'tmux' and press [prefix]+I to install Tmux plugins"
    print_yellow "  - Configure Cinnamon panel and extensions manually"
}

# Run main function
main "$@"
