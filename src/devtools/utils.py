"""
Utility functions for shell commands, file operations, and system checks.
"""

import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Optional, Tuple
from urllib.request import urlopen, Request
from urllib.error import URLError

from .logger import (
    console,
    print_success,
    print_warning,
    print_error,
    install_log,
    changes_log,
    create_progress,
)


def run_command(
    cmd: list[str] | str,
    capture: bool = True,
    check: bool = True,
    sudo: bool = False,
    shell: bool = False,
    cwd: Optional[Path] = None,
) -> Tuple[int, str, str]:
    """
    Run a shell command.
    
    Returns:
        Tuple of (return_code, stdout, stderr)
    """
    if sudo and isinstance(cmd, list):
        cmd = ["sudo"] + cmd
    elif sudo and isinstance(cmd, str):
        cmd = f"sudo {cmd}"
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=capture,
            text=True,
            check=check,
            shell=shell,
            cwd=cwd,
        )
        
        install_log.log_command(
            str(cmd),
            result.stdout + result.stderr if capture else "",
            result.returncode,
        )
        
        return result.returncode, result.stdout or "", result.stderr or ""
    
    except subprocess.CalledProcessError as e:
        install_log.log_command(
            str(cmd),
            (e.stdout or "") + (e.stderr or ""),
            e.returncode,
        )
        if check:
            raise
        return e.returncode, e.stdout or "", e.stderr or ""


def run_command_with_progress(
    cmd: list[str] | str,
    description: str,
    sudo: bool = False,
    shell: bool = False,
    cwd: Optional[Path] = None,
) -> Tuple[int, str, str]:
    """Run a command with a spinner progress indicator."""
    with create_progress() as progress:
        task = progress.add_task(description, total=None)
        returncode, stdout, stderr = run_command(
            cmd, capture=True, check=False, sudo=sudo, shell=shell, cwd=cwd
        )
        progress.update(task, completed=True)
    
    return returncode, stdout, stderr


def is_package_installed(package: str) -> bool:
    """Check if an apt package is installed."""
    returncode, _, _ = run_command(
        ["dpkg", "-l", package],
        capture=True,
        check=False,
    )
    return returncode == 0


def install_apt_package(package: str, quiet: bool = True) -> bool:
    """Install an apt package."""
    if is_package_installed(package):
        return True
    
    cmd = ["apt", "install", "-y"]
    if quiet:
        cmd.append("-qq")
    cmd.append(package)
    
    returncode, _, _ = run_command(cmd, sudo=True, check=False)
    
    if returncode == 0:
        changes_log.log("PACKAGE", f"Installed {package}", "apt")
        return True
    return False


def remove_apt_package(package: str, purge: bool = False) -> bool:
    """Remove an apt package."""
    if not is_package_installed(package):
        return True
    
    cmd = ["apt", "purge" if purge else "remove", "-y", package]
    returncode, _, _ = run_command(cmd, sudo=True, check=False)
    
    if returncode == 0:
        changes_log.log("PACKAGE", f"Removed {package}", "apt")
        return True
    return False


def command_exists(cmd: str) -> bool:
    """Check if a command exists in PATH."""
    return shutil.which(cmd) is not None


def download_file(url: str, dest: Path, description: str = "Downloading") -> bool:
    """Download a file with progress indication."""
    try:
        with create_progress() as progress:
            task = progress.add_task(description, total=None)
            
            request = Request(url, headers={"User-Agent": "DevTools/2.0"})
            with urlopen(request) as response:
                dest.parent.mkdir(parents=True, exist_ok=True)
                with open(dest, "wb") as f:
                    f.write(response.read())
            
            progress.update(task, completed=True)
        
        return True
    except (URLError, OSError) as e:
        print_error(f"Download failed: {e}")
        return False


def copy_file(src: Path, dest: Path, backup: bool = True) -> bool:
    """Copy a file, optionally backing up the destination."""
    try:
        dest.parent.mkdir(parents=True, exist_ok=True)
        
        if backup and dest.exists():
            backup_path = dest.with_suffix(dest.suffix + ".devtools_backup")
            shutil.copy2(dest, backup_path)
            changes_log.log("BACKUP", f"Backed up {dest.name}", str(backup_path))
        
        shutil.copy2(src, dest)
        changes_log.log("CONFIG", f"Installed {dest.name}", str(dest))
        
        return True
    except OSError as e:
        print_error(f"Failed to copy {src} to {dest}: {e}")
        return False


def copy_directory(src: Path, dest: Path) -> bool:
    """Copy a directory recursively."""
    try:
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src, dest)
        return True
    except OSError as e:
        print_error(f"Failed to copy {src} to {dest}: {e}")
        return False


def create_temp_dir() -> Path:
    """Create a temporary directory."""
    return Path(tempfile.mkdtemp(prefix="devtools_"))


def remove_directory(path: Path, sudo: bool = False) -> bool:
    """Remove a directory recursively."""
    if not path.exists():
        return True
    
    try:
        if sudo:
            run_command(["rm", "-rf", str(path)], sudo=True)
        else:
            shutil.rmtree(path)
        return True
    except OSError as e:
        print_error(f"Failed to remove {path}: {e}")
        return False


def ensure_directory(path: Path) -> None:
    """Ensure a directory exists."""
    path.mkdir(parents=True, exist_ok=True)


def git_clone(repo_url: str, dest: Path, quiet: bool = True) -> bool:
    """Clone a git repository."""
    cmd = ["git", "clone"]
    if quiet:
        cmd.append("-q")
    cmd.extend([repo_url, str(dest)])
    
    returncode, _, _ = run_command(cmd, check=False)
    return returncode == 0


def check_ubuntu() -> Tuple[bool, str]:
    """Check if running on Ubuntu and return the version."""
    os_release = Path("/etc/os-release")
    if not os_release.exists():
        return False, ""
    
    with open(os_release) as f:
        content = f.read()
    
    is_ubuntu = 'ID=ubuntu' in content or 'ID_LIKE=ubuntu' in content
    
    # Extract version
    for line in content.split("\n"):
        if line.startswith("PRETTY_NAME="):
            version = line.split("=")[1].strip('"')
            return is_ubuntu, version
    
    return is_ubuntu, "Unknown"


def check_cinnamon() -> bool:
    """Check if Cinnamon desktop is installed."""
    return command_exists("cinnamon-settings")


def get_gsetting(schema: str, key: str) -> Optional[str]:
    """Get a gsetting value."""
    returncode, stdout, _ = run_command(
        ["gsettings", "get", schema, key],
        check=False,
    )
    if returncode == 0:
        return stdout.strip()
    return None


def set_gsetting(schema: str, key: str, value: str) -> bool:
    """Set a gsetting value."""
    returncode, _, _ = run_command(
        ["gsettings", "set", schema, key, value],
        check=False,
    )
    return returncode == 0


def reset_gsetting(schema: str, key: str) -> bool:
    """Reset a gsetting to default."""
    returncode, _, _ = run_command(
        ["gsettings", "reset", schema, key],
        check=False,
    )
    return returncode == 0


def dconf_dump(path: str) -> str:
    """Dump dconf settings for a path."""
    returncode, stdout, _ = run_command(
        ["dconf", "dump", path],
        check=False,
    )
    return stdout if returncode == 0 else ""


def dconf_load(path: str, data: str) -> bool:
    """Load dconf settings from data."""
    process = subprocess.run(
        ["dconf", "load", path],
        input=data,
        text=True,
        capture_output=True,
    )
    return process.returncode == 0
