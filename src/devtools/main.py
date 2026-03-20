"""
DevTools CLI - Main entry point.

Usage:
    devtools install [--dry-run] [--skip-snap] [--skip-firefox]
    devtools restore [--dry-run]
    devtools export-cinnamon
    devtools export-firefox
"""

from typing import Optional

import typer
from rich.prompt import Confirm

from . import __version__
from .logger import (
    console,
    print_header,
    print_step,
    print_success,
    print_warning,
    print_error,
    print_info,
    changes_log,
)
from .utils import check_ubuntu, check_cinnamon

app = typer.Typer(
    name="devtools",
    help="Ubuntu Cinnamon System Configuration CLI",
    add_completion=False,
)


def version_callback(value: bool) -> None:
    """Print version and exit."""
    if value:
        console.print(f"DevTools v{__version__}")
        raise typer.Exit()


@app.callback()
def main(
    version: Optional[bool] = typer.Option(
        None,
        "--version",
        "-v",
        callback=version_callback,
        is_eager=True,
        help="Show version and exit.",
    ),
) -> None:
    """DevTools - Ubuntu Cinnamon System Configuration."""
    pass


@app.command()
def install(
    dry_run: bool = typer.Option(
        False,
        "--dry-run",
        "-n",
        help="Show what would be done without making changes.",
    ),
    skip_snap: bool = typer.Option(
        False,
        "--skip-snap",
        help="Skip Snap removal and Flatpak setup.",
    ),
    skip_firefox: bool = typer.Option(
        False,
        "--skip-firefox",
        help="Skip Firefox configuration.",
    ),
    skip_themes: bool = typer.Option(
        False,
        "--skip-themes",
        help="Skip theme installation.",
    ),
    yes: bool = typer.Option(
        False,
        "--yes",
        "-y",
        help="Answer yes to all prompts.",
    ),
) -> None:
    """
    Install and configure the system.
    
    This command will:
    - Install system dependencies
    - Install fonts and wallpapers
    - Configure shell tools (Starship, Vim)
    - Remove Snap and install Flatpak (unless --skip-snap)
    - Install Cinnamon themes
    - Apply Cinnamon settings
    - Configure Firefox (unless --skip-firefox)
    """
    from .system import (
        check_system,
        update_system,
        install_dependencies,
        install_fonts,
        install_wallpapers,
    )
    from .shell_tools import install_shell_tools, install_terminal_apps
    from .flatpak import purge_snap, setup_flatpak
    from .cinnamon import install_themes, apply_cinnamon_settings
    from .firefox import configure_firefox
    
    print_header("DevTools System Configuration")
    
    if dry_run:
        print_warning("DRY-RUN MODE: No changes will be made")
        console.print()
    
    # System check
    is_ubuntu, version_str = check_ubuntu()
    if not is_ubuntu:
        print_warning(f"Not running Ubuntu (detected: {version_str})")
        if not yes and not Confirm.ask("Continue anyway?"):
            raise typer.Exit(1)
    else:
        print_success(f"System: {version_str}")
    
    if not check_cinnamon():
        print_warning("Cinnamon desktop not detected")
        if not yes and not Confirm.ask("Continue anyway?"):
            raise typer.Exit(1)
    
    # Start logging session
    if not dry_run:
        changes_log.start_session()
    
    total_steps = 9
    if skip_snap:
        total_steps -= 1
    if skip_firefox:
        total_steps -= 1
    if skip_themes:
        total_steps -= 1
    
    step = 1
    
    # Step 1: Update system
    print_step(step, total_steps, "Updating system packages...")
    if not dry_run:
        update_system()
    print_success("System updated")
    step += 1
    
    # Step 2: Install dependencies
    print_step(step, total_steps, "Installing system dependencies...")
    if not dry_run:
        install_dependencies()
    print_success("Dependencies installed")
    step += 1
    
    # Step 3: Install fonts
    print_step(step, total_steps, "Installing fonts...")
    if not dry_run:
        install_fonts()
    print_success("Fonts installed")
    step += 1
    
    # Step 4: Install wallpapers
    print_step(step, total_steps, "Installing wallpapers...")
    if not dry_run:
        install_wallpapers()
    print_success("Wallpapers installed")
    step += 1
    
    # Step 5: Shell tools
    print_step(step, total_steps, "Configuring shell tools...")
    if not dry_run:
        install_shell_tools()
        install_terminal_apps()
    print_success("Shell tools configured")
    step += 1
    
    # Step 6: Snap/Flatpak
    if not skip_snap:
        print_step(step, total_steps, "Removing Snap and setting up Flatpak...")
        if not dry_run:
            if yes or Confirm.ask("Remove Snap and install Flatpak?", default=True):
                purge_snap()
                setup_flatpak()
        print_success("Package manager migration complete")
        step += 1
    
    # Step 7: Themes
    if not skip_themes:
        print_step(step, total_steps, "Installing Cinnamon themes...")
        if not dry_run:
            install_themes()
        print_success("Themes installed")
        step += 1
    
    # Step 8: Cinnamon settings
    print_step(step, total_steps, "Applying Cinnamon settings...")
    if not dry_run:
        apply_cinnamon_settings()
    print_success("Cinnamon settings applied")
    step += 1
    
    # Step 9: Firefox
    if not skip_firefox:
        print_step(step, total_steps, "Configuring Firefox...")
        if not dry_run:
            configure_firefox()
        print_success("Firefox configured")
        step += 1
    
    console.print()
    print_header("Installation Complete!")
    
    print_info("Next steps:")
    console.print("  • Log out and log back in to apply all changes")
    console.print("  • Run [cyan]vim +PluginInstall +qall[/cyan] to install Vim plugins")
    console.print("  • Run [cyan]cinnamon --replace &[/cyan] to reload Cinnamon")


@app.command()
def restore(
    dry_run: bool = typer.Option(
        False,
        "--dry-run",
        "-n",
        help="Show what would be restored without making changes.",
    ),
    yes: bool = typer.Option(
        False,
        "--yes",
        "-y",
        help="Answer yes to all prompts.",
    ),
) -> None:
    """
    Restore system to pre-installation state.
    
    Reads the changes log and reverses all tracked modifications.
    """
    from .system import restore_system
    
    print_header("DevTools System Restore")
    
    if dry_run:
        print_warning("DRY-RUN MODE: No changes will be made")
        console.print()
    
    if not yes and not Confirm.ask(
        "This will undo all DevTools changes. Continue?",
        default=False,
    ):
        raise typer.Exit(0)
    
    restore_system(dry_run=dry_run)
    
    print_header("Restore Complete!")


@app.command("export-cinnamon")
def export_cinnamon() -> None:
    """
    Export current Cinnamon settings.
    
    Exports dconf settings, applet configurations, and custom keybindings
    to config_files/cinnamon/.
    """
    from .cinnamon import export_cinnamon_settings
    
    print_header("Export Cinnamon Settings")
    
    export_cinnamon_settings()
    
    print_success("Cinnamon settings exported!")


@app.command("export-firefox")
def export_firefox_cmd() -> None:
    """
    Export Firefox extensions and bookmarks.
    
    Exports the current Firefox profile's extensions and bookmarks
    to config_files/firefox/.
    """
    from .firefox import export_firefox
    
    print_header("Export Firefox Settings")
    
    export_firefox()
    
    print_success("Firefox settings exported!")


@app.command("apply-cinnamon")
def apply_cinnamon(
    config_file: Optional[str] = typer.Option(
        None,
        "--config",
        "-c",
        help="Path to config file (default: current.conf)",
    ),
    dry_run: bool = typer.Option(
        False,
        "--dry-run",
        "-n",
        help="Show what would be applied without making changes.",
    ),
) -> None:
    """
    Apply Cinnamon settings from config file.
    """
    from .cinnamon import apply_cinnamon_settings
    from pathlib import Path
    
    print_header("Apply Cinnamon Settings")
    
    if dry_run:
        print_warning("DRY-RUN MODE: No changes will be made")
        console.print()
    
    config_path = Path(config_file) if config_file else None
    apply_cinnamon_settings(config_path=config_path, dry_run=dry_run)
    
    print_success("Cinnamon settings applied!")


@app.command("list-configs")
def list_configs() -> None:
    """
    List available Cinnamon configuration files.
    """
    from .cinnamon import list_cinnamon_configs
    
    list_cinnamon_configs()


if __name__ == "__main__":
    app()
