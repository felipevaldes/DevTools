"""
Configuration constants and paths for DevTools.
"""

from pathlib import Path
import os

# Script directory (where bootstrap.sh lives)
SCRIPT_DIR = Path(__file__).parent.parent.parent.resolve()

# User directories
HOME_DIR = Path.home()
CONFIG_DIR = HOME_DIR / ".config"
LOCAL_DIR = HOME_DIR / ".local"
LOCAL_BIN = LOCAL_DIR / "bin"
LOCAL_SHARE = LOCAL_DIR / "share"

# DevTools config files
CONFIG_FILES_DIR = SCRIPT_DIR / "config_files"
FONTS_DIR = SCRIPT_DIR / "fonts"
REMNOTE_DIR = SCRIPT_DIR / "remnote"

# Cinnamon config
CINNAMON_CONFIG_DIR = CONFIG_FILES_DIR / "cinnamon"
CINNAMON_SPICES_SRC = CONFIG_DIR / "cinnamon" / "spices"

# Logging
INSTALL_LOG = CONFIG_DIR / "devtools_install.log"
CHANGES_LOG = CONFIG_DIR / "devtools_changes.log"

# URLs
WALLPAPER_URL = "https://github.com/felipevaldes/DevTools/releases/download/v1.0.0/wallpapers.tar.gz"
STARSHIP_INSTALL_URL = "https://starship.rs/install.sh"
UV_INSTALL_URL = "https://astral.sh/uv/install.sh"

# Theme repositories
THEME_REPOS = {
    "whitesur-gtk": "https://github.com/felipevaldes/WhiteSur-gtk-theme.git",
    "whitesur-icons": "https://github.com/felipevaldes/WhiteSur-icon-theme.git",
    "mcmojave-cursors": "https://github.com/felipevaldes/McMojave-cursors.git",
}

# System packages to install
SYSTEM_PACKAGES = [
    "libcanberra-gtk-module",
    "libglib2.0-dev",
    "libxml2-utils",
    "shotwell",
    "git",
    "curl",
    "wget",
    "unzip",
    "build-essential",
    "dconf-cli",
    "flatpak",
    "code",  # VSCode
]

# Flatpak apps to install (replacing Snap apps)
FLATPAK_APPS = [
    "com.spotify.Client",
    "org.videolan.VLC",
    "com.discordapp.Discord",
]

# Destination paths
WALLPAPER_DEST = Path("/usr/share/backgrounds/big_sur")
FONTS_DEST = LOCAL_SHARE / "fonts"
THEMES_DEST = HOME_DIR / ".themes"
ICONS_DEST = HOME_DIR / ".icons"
