"""
Cinnamon desktop environment configuration: themes, settings export/import.
"""

import json
import re
import shutil
import socket
from datetime import datetime
from pathlib import Path
from typing import Optional

from . import config
from .logger import (
    console,
    print_success,
    print_warning,
    print_error,
    print_info,
    print_table,
    changes_log,
    create_progress,
)
from .utils import (
    run_command,
    git_clone,
    create_temp_dir,
    remove_directory,
    ensure_directory,
    copy_directory,
    dconf_dump,
    dconf_load,
    set_gsetting,
    reset_gsetting,
)


def install_themes() -> None:
    """Install WhiteSur GTK, icon, and cursor themes."""
    temp_dir = create_temp_dir()
    
    try:
        # Install GTK theme
        print_info("Installing WhiteSur GTK theme...")
        gtk_dir = temp_dir / "WhiteSur-gtk-theme"
        if git_clone(config.THEME_REPOS["whitesur-gtk"], gtk_dir):
            run_command(
                ["./install.sh"],
                sudo=True,
                cwd=gtk_dir,
            )
            changes_log.log("THEME", "Installed WhiteSur GTK theme", "system-wide")
            
            # Copy Plank themes if available
            plank_src = gtk_dir / "src" / "other" / "plank"
            if plank_src.exists():
                plank_dest = config.LOCAL_SHARE / "plank" / "themes"
                ensure_directory(plank_dest)
                for theme_dir in plank_src.iterdir():
                    if theme_dir.is_dir() and theme_dir.name.startswith("theme-"):
                        dest = plank_dest / theme_dir.name
                        copy_directory(theme_dir, dest)
                changes_log.log("THEME", "Installed Plank themes", str(plank_dest))
        
        # Install icon theme
        print_info("Installing WhiteSur icon theme...")
        icon_dir = temp_dir / "WhiteSur-icon-theme"
        if git_clone(config.THEME_REPOS["whitesur-icons"], icon_dir):
            run_command(
                ["./install.sh"],
                sudo=True,
                cwd=icon_dir,
            )
            changes_log.log("THEME", "Installed WhiteSur icon theme", "system-wide")
        
        # Install cursor theme
        print_info("Installing McMojave cursor theme...")
        cursor_dir = temp_dir / "McMojave-cursors"
        if git_clone(config.THEME_REPOS["mcmojave-cursors"], cursor_dir):
            run_command(
                ["./install.sh"],
                sudo=True,
                cwd=cursor_dir,
            )
            changes_log.log("THEME", "Installed McMojave cursor theme", "system-wide")
        
        print_success("All themes installed")
    
    finally:
        remove_directory(temp_dir)


def export_cinnamon_settings() -> None:
    """Export all Cinnamon settings to config files."""
    hostname = socket.gethostname()
    date = datetime.now().strftime("%Y%m%d")
    datetime_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    output_base = f"{hostname}_{date}"
    output_file = config.CINNAMON_CONFIG_DIR / f"{output_base}_cinnamon.conf"
    spices_dir = config.CINNAMON_CONFIG_DIR / f"{output_base}_spices"
    
    ensure_directory(config.CINNAMON_CONFIG_DIR)
    
    print_info(f"Exporting settings from: {hostname}")
    print_info(f"Output: {output_file}")
    
    # Export dconf settings
    _export_dconf_settings(output_file, hostname, datetime_str)
    
    # Export custom keybindings
    _export_custom_keybindings(output_file)
    
    # Export spices (applet/extension configs)
    _export_spices(spices_dir, hostname, datetime_str)
    
    # Update symlinks
    _update_symlinks(output_base)
    
    # Count settings
    settings_count = sum(1 for line in output_file.read_text().splitlines() 
                        if line and not line.startswith("#") and not line.startswith("[") and "=" in line)
    
    print_success(f"Exported {settings_count} dconf settings")
    print_info(f"Config file: {output_file}")
    print_info(f"Spices: {spices_dir}")


def _export_dconf_settings(output_file: Path, hostname: str, datetime_str: str) -> None:
    """Export dconf settings to INI-style config file."""
    header = f"""# Cinnamon Settings Configuration
# Exported from: {hostname}
# Date: {datetime_str}
#
# This file contains Cinnamon desktop settings in INI-style format.
# Each section [schema] contains key=value pairs that can be applied
# using gsettings set <schema> <key> <value>

"""
    
    output_file.write_text(header)
    
    # Dump dconf settings
    dconf_output = dconf_dump("/org/cinnamon/")
    
    # Convert dconf format to gsettings schema format
    converted_lines = []
    current_section = ""
    
    for line in dconf_output.splitlines():
        if not line:
            converted_lines.append("")
            continue
        
        if line.startswith("["):
            # Convert [path/to/setting] to [org.cinnamon.path.to.setting]
            path = line[1:-1]
            if path == "/" or path == "":
                schema = "org.cinnamon"
            else:
                path = path.strip("/")
                schema = f"org.cinnamon.{path.replace('/', '.')}"
            
            converted_lines.append(f"[{schema}]")
            current_section = schema
        else:
            converted_lines.append(line)
    
    with open(output_file, "a") as f:
        f.write("\n".join(converted_lines))


def _export_custom_keybindings(output_file: Path) -> None:
    """Export custom keyboard shortcuts."""
    returncode, stdout, _ = run_command(
        ["gsettings", "get", "org.cinnamon.desktop.keybindings", "custom-list"],
        check=False,
    )
    
    if returncode != 0 or stdout.strip() in ("@as []", "[]"):
        print_info("No custom keyboard shortcuts found")
        return
    
    with open(output_file, "a") as f:
        f.write("\n# ============================================\n")
        f.write("# CUSTOM KEYBOARD SHORTCUTS\n")
        f.write("# ============================================\n")
        f.write("[org.cinnamon.desktop.keybindings]\n")
        f.write(f"custom-list={stdout.strip()}\n\n")
        
        # Parse custom-list and export each keybinding
        custom_list = stdout.strip().strip("[]'").replace("'", "").split(",")
        
        for kb in custom_list:
            kb = kb.strip()
            if not kb:
                continue
            
            f.write(f"[custom-keybinding:{kb}]\n")
            
            schema = f"org.cinnamon.desktop.keybindings.custom-keybinding:{kb}"
            for prop in ["name", "command", "binding"]:
                ret, val, _ = run_command(
                    ["gsettings", "get", schema, prop],
                    check=False,
                )
                if ret == 0:
                    f.write(f"{prop}={val.strip()}\n")
            
            f.write("\n")


def _export_spices(spices_dir: Path, hostname: str, datetime_str: str) -> None:
    """Export applet/extension configurations."""
    if spices_dir.exists():
        shutil.rmtree(spices_dir)
    spices_dir.mkdir(parents=True)
    
    if not config.CINNAMON_SPICES_SRC.exists():
        print_warning(f"Spices directory not found: {config.CINNAMON_SPICES_SRC}")
        return
    
    spices_count = 0
    
    for spice_src in config.CINNAMON_SPICES_SRC.iterdir():
        if not spice_src.is_dir():
            continue
        
        # Check for JSON files
        json_files = list(spice_src.glob("*.json"))
        if not json_files:
            continue
        
        spice_dest = spices_dir / spice_src.name
        spice_dest.mkdir()
        
        for json_file in json_files:
            shutil.copy2(json_file, spice_dest)
            spices_count += 1
    
    # Create manifest
    manifest = spices_dir / "manifest.txt"
    with open(manifest, "w") as f:
        f.write(f"# Cinnamon Spices Configuration Manifest\n")
        f.write(f"# Exported from: {hostname}\n")
        f.write(f"# Date: {datetime_str}\n\n")
        f.write("Exported spices:\n")
        for spice in sorted(spices_dir.iterdir()):
            if spice.is_dir():
                f.write(f"  - {spice.name}\n")
    
    print_success(f"Exported {spices_count} spice configuration files")


def _update_symlinks(output_base: str) -> None:
    """Update current.conf and current_spices symlinks."""
    current_conf = config.CINNAMON_CONFIG_DIR / "current.conf"
    current_spices = config.CINNAMON_CONFIG_DIR / "current_spices"
    
    # Remove existing symlinks
    if current_conf.is_symlink():
        current_conf.unlink()
    if current_spices.is_symlink():
        current_spices.unlink()
    
    # Create new symlinks (relative paths for portability)
    current_conf.symlink_to(f"{output_base}_cinnamon.conf")
    current_spices.symlink_to(f"{output_base}_spices")
    
    print_success(f"Updated current.conf -> {output_base}_cinnamon.conf")


def list_cinnamon_configs() -> None:
    """List available Cinnamon configuration files."""
    if not config.CINNAMON_CONFIG_DIR.exists():
        print_warning("No config directory found")
        print_info("Run 'devtools export-cinnamon' to create one")
        return
    
    configs = []
    current_link = config.CINNAMON_CONFIG_DIR / "current.conf"
    current_target = current_link.resolve().name if current_link.is_symlink() else None
    
    for conf_file in sorted(config.CINNAMON_CONFIG_DIR.glob("*_cinnamon.conf")):
        # Read metadata
        content = conf_file.read_text()
        
        hostname = "unknown"
        date = "unknown"
        for line in content.splitlines()[:10]:
            if line.startswith("# Exported from:"):
                hostname = line.split(":", 1)[1].strip()
            elif line.startswith("# Date:"):
                date = line.split(":", 1)[1].strip()
        
        # Count settings
        settings_count = sum(1 for line in content.splitlines() 
                            if line and not line.startswith("#") and not line.startswith("[") and "=" in line)
        
        # Check for spices
        spices_dir = conf_file.parent / conf_file.name.replace("_cinnamon.conf", "_spices")
        has_spices = "Yes" if spices_dir.exists() else "No"
        
        is_current = "✓" if conf_file.name == current_target else ""
        
        configs.append([
            conf_file.name,
            hostname,
            date,
            str(settings_count),
            has_spices,
            is_current,
        ])
    
    if configs:
        print_table(
            "Available Cinnamon Configurations",
            ["File", "Hostname", "Date", "Settings", "Spices", "Current"],
            configs,
        )
    else:
        print_warning("No configuration files found")
        print_info("Run 'devtools export-cinnamon' to create one")


def apply_cinnamon_settings(
    config_path: Optional[Path] = None,
    dry_run: bool = False,
) -> None:
    """Apply Cinnamon settings from config file."""
    if config_path is None:
        config_path = config.CINNAMON_CONFIG_DIR / "current.conf"
    
    # Resolve symlinks
    if config_path.is_symlink():
        config_path = config_path.parent / config_path.resolve().name
    
    if not config_path.exists():
        print_warning(f"Config file not found: {config_path}")
        print_info("Run 'devtools export-cinnamon' to create one")
        return
    
    print_info(f"Applying settings from: {config_path.name}")
    
    # Backup current settings
    if not dry_run:
        backup_dir = config.CONFIG_DIR / f"cinnamon_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        backup_dir.mkdir(parents=True, exist_ok=True)
        backup_file = backup_dir / "cinnamon.dconf"
        backup_file.write_text(dconf_dump("/org/cinnamon/"))
        changes_log.log("BACKUP", "Backed up Cinnamon settings", str(backup_dir))
    
    # Apply dconf settings
    applied, errors, skipped = _apply_dconf_from_config(config_path, dry_run)
    
    # Apply spices
    spices_dir = config_path.parent / config_path.name.replace("_cinnamon.conf", "_spices")
    if spices_dir.exists():
        spices_count = _apply_spices(spices_dir, dry_run)
        print_success(f"Restored {spices_count} spice configurations")
    
    print_success(f"Applied {applied} settings ({skipped} skipped, {errors} errors)")
    
    if not dry_run:
        changes_log.log("CINNAMON", "Applied Cinnamon settings", str(config_path))


def _apply_dconf_from_config(config_path: Path, dry_run: bool) -> tuple[int, int, int]:
    """Apply settings from INI-style config file."""
    applied = 0
    errors = 0
    skipped = 0
    
    content = config_path.read_text()
    current_schema = ""
    in_custom_keybinding = False
    kb_path = ""
    
    # Settings to skip (system-specific)
    skip_keys = {"night-light-last-coordinates"}
    
    for line in content.splitlines():
        line = line.strip()
        
        # Skip empty lines and comments
        if not line or line.startswith("#"):
            continue
        
        # Section header
        if line.startswith("[") and line.endswith("]"):
            current_schema = line[1:-1]
            
            if current_schema.startswith("custom-keybinding:"):
                in_custom_keybinding = True
                kb_path = current_schema.split(":", 1)[1]
            else:
                in_custom_keybinding = False
            continue
        
        # Key=value
        if "=" in line and current_schema:
            key, value = line.split("=", 1)
            
            if key in skip_keys:
                skipped += 1
                continue
            
            if dry_run:
                console.print(f"  [DRY-RUN] gsettings set {current_schema} {key} {value}")
                applied += 1
                continue
            
            # Determine target schema
            if in_custom_keybinding:
                target = f"org.cinnamon.desktop.keybindings.custom-keybinding:{kb_path}"
            else:
                target = current_schema
            
            # Try to apply
            if set_gsetting(target, key, value):
                applied += 1
            else:
                # Try without quotes
                unquoted = value.strip("'\"")
                if set_gsetting(target, key, unquoted):
                    applied += 1
                else:
                    errors += 1
    
    return applied, errors, skipped


def _apply_spices(spices_dir: Path, dry_run: bool) -> int:
    """Apply spices configurations."""
    if not config.CINNAMON_SPICES_SRC.exists():
        config.CINNAMON_SPICES_SRC.mkdir(parents=True)
    
    count = 0
    
    for spice_src in spices_dir.iterdir():
        if not spice_src.is_dir():
            continue
        
        spice_dest = config.CINNAMON_SPICES_SRC / spice_src.name
        
        if dry_run:
            for json_file in spice_src.glob("*.json"):
                console.print(f"  [DRY-RUN] cp {json_file} -> {spice_dest}")
                count += 1
        else:
            spice_dest.mkdir(exist_ok=True)
            for json_file in spice_src.glob("*.json"):
                shutil.copy2(json_file, spice_dest)
                count += 1
    
    return count
