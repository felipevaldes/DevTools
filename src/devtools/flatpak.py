"""
Package manager migration: Snap removal and Flatpak setup.
"""

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
    command_exists,
    install_apt_package,
    remove_apt_package,
    remove_directory,
)


def get_installed_snaps() -> list[str]:
    """Get list of installed Snap packages."""
    if not command_exists("snap"):
        return []
    
    returncode, stdout, _ = run_command(
        ["snap", "list"],
        check=False,
    )
    
    if returncode != 0:
        return []
    
    snaps = []
    for line in stdout.splitlines()[1:]:  # Skip header
        parts = line.split()
        if parts:
            snap_name = parts[0]
            # Skip core system snaps
            if not snap_name.startswith(("core", "snapd", "bare", "gnome-")):
                snaps.append(snap_name)
    
    return snaps


def purge_snap() -> None:
    """
    Completely remove Snap package manager.
    
    This will:
    1. List and remove all installed Snap packages
    2. Remove snapd package
    3. Remove Snap directories
    4. Prevent snapd from being reinstalled
    """
    print_info("Beginning Snap removal...")
    
    # Check if snap is installed
    if not command_exists("snap"):
        print_info("Snap is not installed, skipping removal")
        return
    
    # Step 1: List installed snaps
    snaps = get_installed_snaps()
    
    if snaps:
        print_info(f"Found {len(snaps)} snap packages to remove")
        
        with create_progress() as progress:
            task = progress.add_task("Removing snaps...", total=len(snaps))
            
            for snap in snaps:
                run_command(
                    ["snap", "remove", "--purge", snap],
                    sudo=True,
                    check=False,
                )
                changes_log.log("SNAP", f"Removed snap package", snap)
                progress.advance(task)
    
    # Step 2: Stop snapd services
    print_info("Stopping snapd services...")
    run_command(["systemctl", "stop", "snapd.service"], sudo=True, check=False)
    run_command(["systemctl", "stop", "snapd.socket"], sudo=True, check=False)
    run_command(["systemctl", "stop", "snapd.seeded.service"], sudo=True, check=False)
    
    # Step 3: Remove snapd
    print_info("Removing snapd package...")
    run_command(["apt", "purge", "-y", "snapd"], sudo=True, check=False)
    run_command(["apt", "autoremove", "-y"], sudo=True, check=False)
    changes_log.log("PACKAGE", "Removed snapd", "apt purge")
    
    # Step 4: Remove snap directories
    print_info("Removing Snap directories...")
    snap_dirs = [
        Path("/snap"),
        Path("/var/snap"),
        Path("/var/lib/snapd"),
        Path("/var/cache/snapd"),
        config.HOME_DIR / "snap",
    ]
    
    for snap_dir in snap_dirs:
        if snap_dir.exists():
            remove_directory(snap_dir, sudo=True)
            changes_log.log("DIRECTORY", f"Removed snap directory", str(snap_dir))
    
    # Step 5: Prevent snapd from being reinstalled
    _prevent_snap_reinstall()
    
    print_success("Snap has been completely removed")


def _prevent_snap_reinstall() -> None:
    """Create apt preferences to prevent snapd reinstallation."""
    print_info("Preventing snapd reinstallation...")
    
    nosnap_content = """# Prevent snapd from being installed
Package: snapd
Pin: release a=*
Pin-Priority: -10
"""
    
    nosnap_path = Path("/etc/apt/preferences.d/nosnap.pref")
    
    # Write via temp file
    temp_file = Path("/tmp/nosnap.pref")
    temp_file.write_text(nosnap_content)
    
    run_command(["cp", str(temp_file), str(nosnap_path)], sudo=True)
    temp_file.unlink()
    
    changes_log.log("CONFIG", "Created nosnap preference", str(nosnap_path))
    print_success("Created apt preference to prevent snapd reinstallation")


def setup_flatpak() -> None:
    """
    Set up Flatpak as the replacement package manager.
    
    This will:
    1. Install Flatpak
    2. Add Flathub repository
    3. Install recommended Flatpak apps
    """
    print_info("Setting up Flatpak...")
    
    # Step 1: Install Flatpak
    if not command_exists("flatpak"):
        print_info("Installing Flatpak...")
        install_apt_package("flatpak")
        
        install_apt_package("gnome-software")
        install_apt_package("gnome-software-plugin-flatpak")
    else:
        print_info("Flatpak is already installed")
    
    # Step 2: Add Flathub repository
    print_info("Adding Flathub repository...")
    returncode, _, _ = run_command(
        [
            "flatpak", "remote-add", "--if-not-exists",
            "flathub", "https://flathub.org/repo/flathub.flatpakrepo"
        ],
        sudo=True,
        check=False,
    )
    
    if returncode == 0:
        changes_log.log("FLATPAK", "Added Flathub repository", "flathub")
        print_success("Flathub repository added")
    
    # Step 3: Install recommended apps
    _install_flatpak_apps()
    
    print_success("Flatpak setup complete")
    print_info("Note: You may need to log out and back in for Flatpak apps to appear in menu")


def _install_flatpak_apps() -> None:
    """Install recommended Flatpak applications."""
    if not config.FLATPAK_APPS:
        return
    
    print_info(f"Installing {len(config.FLATPAK_APPS)} Flatpak apps...")
    
    with create_progress() as progress:
        task = progress.add_task("Installing Flatpak apps...", total=len(config.FLATPAK_APPS))
        
        for app_id in config.FLATPAK_APPS:
            # Check if already installed
            returncode, _, _ = run_command(
                ["flatpak", "info", app_id],
                check=False,
            )
            
            if returncode == 0:
                print_info(f"  {app_id} already installed")
            else:
                # Install the app
                returncode, _, _ = run_command(
                    ["flatpak", "install", "-y", "flathub", app_id],
                    sudo=True,
                    check=False,
                )
                
                if returncode == 0:
                    changes_log.log("FLATPAK", f"Installed Flatpak app", app_id)
                    print_success(f"  Installed {app_id}")
                else:
                    print_warning(f"  Failed to install {app_id}")
            
            progress.advance(task)


def get_installed_flatpaks() -> list[dict]:
    """Get list of installed Flatpak applications."""
    if not command_exists("flatpak"):
        return []
    
    returncode, stdout, _ = run_command(
        ["flatpak", "list", "--app", "--columns=application,name,version"],
        check=False,
    )
    
    if returncode != 0:
        return []
    
    apps = []
    for line in stdout.splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            apps.append({
                "id": parts[0],
                "name": parts[1] if len(parts) > 1 else parts[0],
                "version": parts[2] if len(parts) > 2 else "",
            })
    
    return apps


def list_package_managers() -> None:
    """Show status of package managers (Snap vs Flatpak)."""
    rows = []
    
    # Check Snap
    snap_installed = command_exists("snap")
    snap_status = "Installed" if snap_installed else "Not installed"
    snap_packages = len(get_installed_snaps()) if snap_installed else 0
    rows.append(["Snap", snap_status, str(snap_packages)])
    
    # Check Flatpak
    flatpak_installed = command_exists("flatpak")
    flatpak_status = "Installed" if flatpak_installed else "Not installed"
    flatpak_apps = len(get_installed_flatpaks()) if flatpak_installed else 0
    rows.append(["Flatpak", flatpak_status, str(flatpak_apps)])
    
    print_table(
        "Package Manager Status",
        ["Manager", "Status", "Packages"],
        rows,
    )
    
    # Show Flathub status
    if flatpak_installed:
        returncode, stdout, _ = run_command(
            ["flatpak", "remotes"],
            check=False,
        )
        if "flathub" in stdout.lower():
            print_success("Flathub repository is configured")
        else:
            print_warning("Flathub repository is not configured")
    
    # Check nosnap preference
    nosnap = Path("/etc/apt/preferences.d/nosnap.pref")
    if nosnap.exists():
        print_info("Snap reinstallation is blocked via apt preferences")
