"""
System-level operations: packages, fonts, wallpapers, and restore functionality.
"""

import shutil
import tarfile
from pathlib import Path

from . import config
from .logger import (
    console,
    print_success,
    print_warning,
    print_error,
    print_info,
    changes_log,
    create_progress,
)
from .utils import (
    run_command,
    is_package_installed,
    install_apt_package,
    remove_apt_package,
    download_file,
    copy_directory,
    ensure_directory,
    remove_directory,
    create_temp_dir,
)


def check_system() -> tuple[bool, str]:
    """Check system compatibility."""
    from .utils import check_ubuntu, check_cinnamon
    
    is_ubuntu, version = check_ubuntu()
    is_cinnamon = check_cinnamon()
    
    return is_ubuntu and is_cinnamon, version


def update_system() -> None:
    """Update system package lists."""
    run_command(["apt", "update", "-qq"], sudo=True, check=False)
    changes_log.log("SYSTEM", "Updated package lists", "apt update")


def install_dependencies() -> None:
    """Install system dependencies."""
    with create_progress() as progress:
        task = progress.add_task(
            "Installing packages...",
            total=len(config.SYSTEM_PACKAGES),
        )
        
        for package in config.SYSTEM_PACKAGES:
            if not is_package_installed(package):
                install_apt_package(package)
            progress.advance(task)


def install_fonts() -> None:
    """Install custom fonts."""
    if not config.FONTS_DIR.exists():
        print_warning(f"Fonts directory not found: {config.FONTS_DIR}")
        return
    
    ensure_directory(config.FONTS_DEST)
    
    # Get all font files
    font_extensions = {".ttf", ".otf", ".woff", ".woff2"}
    font_files = []
    
    for ext in font_extensions:
        font_files.extend(config.FONTS_DIR.rglob(f"*{ext}"))
    
    if not font_files:
        print_warning("No font files found")
        return
    
    with create_progress() as progress:
        task = progress.add_task("Installing fonts...", total=len(font_files))
        
        for font_file in font_files:
            dest = config.FONTS_DEST / font_file.name
            shutil.copy2(font_file, dest)
            progress.advance(task)
    
    # Refresh font cache
    run_command(["fc-cache", "-fv"], check=False)
    
    changes_log.log("FONTS", "Installed fonts", str(config.FONTS_DEST))
    print_success(f"Installed {len(font_files)} fonts")


def install_wallpapers() -> None:
    """Install wallpapers from GitHub release."""
    temp_dir = create_temp_dir()
    archive_path = temp_dir / "wallpapers.tar.gz"
    
    try:
        # Download archive
        if not download_file(
            config.WALLPAPER_URL,
            archive_path,
            "Downloading wallpapers...",
        ):
            print_warning("Failed to download wallpapers")
            return
        
        # Create destination directory
        run_command(
            ["mkdir", "-p", str(config.WALLPAPER_DEST)],
            sudo=True,
        )
        
        # Extract archive
        with create_progress() as progress:
            task = progress.add_task("Extracting wallpapers...", total=None)
            
            run_command(
                ["tar", "-xzf", str(archive_path), "-C", str(config.WALLPAPER_DEST)],
                sudo=True,
            )
            
            progress.update(task, completed=True)
        
        changes_log.log("WALLPAPERS", "Installed wallpapers", str(config.WALLPAPER_DEST))
        print_success(f"Wallpapers installed to {config.WALLPAPER_DEST}")
    
    finally:
        remove_directory(temp_dir)


def restore_system(dry_run: bool = False) -> None:
    """
    Restore system by reading changes log and undoing modifications.
    """
    if not config.CHANGES_LOG.exists():
        print_warning("No changes log found. Nothing to restore.")
        return
    
    with open(config.CHANGES_LOG) as f:
        lines = f.readlines()
    
    # Parse and reverse changes (newest first)
    changes = []
    for line in lines:
        line = line.strip()
        if not line or line.startswith("==="):
            continue
        
        # Parse format: [timestamp] [TYPE] description | details
        try:
            # Extract type
            type_start = line.index("[", line.index("]") + 1) + 1
            type_end = line.index("]", type_start)
            change_type = line[type_start:type_end]
            
            # Extract description and details
            rest = line[type_end + 2:]  # Skip "] "
            if "|" in rest:
                description, details = rest.split("|", 1)
                description = description.strip()
                details = details.strip()
            else:
                description = rest.strip()
                details = ""
            
            changes.append((change_type, description, details))
        except (ValueError, IndexError):
            continue
    
    # Reverse to undo in reverse order
    changes.reverse()
    
    if not changes:
        print_warning("No changes found in log.")
        return
    
    print_info(f"Found {len(changes)} changes to restore")
    
    with create_progress() as progress:
        task = progress.add_task("Restoring...", total=len(changes))
        
        for change_type, description, details in changes:
            if dry_run:
                console.print(f"  [DRY-RUN] Undo [{change_type}]: {description}")
            else:
                _undo_change(change_type, description, details)
            
            progress.advance(task)
    
    print_success("System restored")


def _undo_change(change_type: str, description: str, details: str) -> None:
    """Undo a single change."""
    try:
        if change_type == "PACKAGE":
            # Extract package name from description "Installed <package>"
            package = description.replace("Installed ", "").replace("Removed ", "")
            if "Installed" in description:
                remove_apt_package(package, purge=True)
        
        elif change_type == "CONFIG":
            # Restore from backup if exists
            path = Path(details)
            backup = path.with_suffix(path.suffix + ".devtools_backup")
            if backup.exists():
                shutil.copy2(backup, path)
                backup.unlink()
            elif path.exists():
                path.unlink()
        
        elif change_type == "FONTS":
            # Remove fonts directory
            if config.FONTS_DEST.exists():
                shutil.rmtree(config.FONTS_DEST)
        
        elif change_type == "WALLPAPERS":
            # Remove wallpapers
            if config.WALLPAPER_DEST.exists():
                remove_directory(config.WALLPAPER_DEST, sudo=True)
        
        elif change_type == "THEME":
            # Remove theme directory
            path = Path(details)
            if path.exists():
                if str(path).startswith("/usr"):
                    remove_directory(path, sudo=True)
                else:
                    remove_directory(path)
        
        elif change_type == "TOOL":
            # Remove tool installation
            path = Path(details)
            if path.exists():
                if path.is_dir():
                    remove_directory(path)
                else:
                    path.unlink()
        
        elif change_type == "BACKUP":
            # Skip backup entries
            pass
        
        elif change_type == "CINNAMON":
            # Reset Cinnamon settings - handled separately
            pass
        
    except Exception as e:
        print_warning(f"Failed to undo {change_type}: {e}")
