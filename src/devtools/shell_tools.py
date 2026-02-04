"""
Shell tools configuration: Starship, tmux, Vim, and terminal apps.
"""

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
    run_command_with_progress,
    command_exists,
    install_apt_package,
    copy_file,
    ensure_directory,
    git_clone,
    create_temp_dir,
    remove_directory,
    download_file,
)


def install_shell_tools() -> None:
    """Install and configure shell tools (Starship, tmux, Vim)."""
    _install_bash_config()
    _install_starship()
    _install_tmux()
    _install_vim()


def _install_bash_config() -> None:
    """Install bash configuration files."""
    print_info("Configuring Bash...")
    
    # .bashrc
    bashrc_src = config.CONFIG_FILES_DIR / ".bashrc"
    if bashrc_src.exists():
        copy_file(bashrc_src, config.HOME_DIR / ".bashrc")
        print_success("  Installed .bashrc")
    
    # .bash_aliases
    bash_aliases_src = config.CONFIG_FILES_DIR / ".bash_aliases"
    if bash_aliases_src.exists():
        copy_file(bash_aliases_src, config.HOME_DIR / ".bash_aliases")
        print_success("  Installed .bash_aliases")


def _install_starship() -> None:
    """Install and configure Starship prompt."""
    print_info("Configuring Starship prompt...")
    
    # Install Starship if not present
    if not command_exists("starship"):
        print_info("  Installing Starship...")
        
        temp_dir = create_temp_dir()
        install_script = temp_dir / "install.sh"
        
        try:
            if download_file(config.STARSHIP_INSTALL_URL, install_script, "Downloading Starship"):
                install_script.chmod(0o755)
                
                ensure_directory(config.LOCAL_BIN)
                
                run_command(
                    [str(install_script), "--bin-dir", str(config.LOCAL_BIN), "-y"],
                    check=False,
                )
                
                changes_log.log("TOOL", "Installed Starship", str(config.LOCAL_BIN / "starship"))
                print_success("  Starship installed")
        finally:
            remove_directory(temp_dir)
    else:
        print_info("  Starship already installed")
    
    # Install config
    starship_config_src = config.CONFIG_FILES_DIR / "starship.toml"
    if starship_config_src.exists():
        starship_config_dest = config.CONFIG_DIR / "starship.toml"
        copy_file(starship_config_src, starship_config_dest)
        print_success("  Installed starship.toml")


def _install_tmux() -> None:
    """Install and configure tmux."""
    print_info("Configuring tmux...")
    
    # Install tmux
    if not command_exists("tmux"):
        install_apt_package("tmux")
        print_success("  Installed tmux")
    else:
        print_info("  tmux already installed")
    
    # Install .tmux.conf
    tmux_conf_src = config.CONFIG_FILES_DIR / ".tmux.conf"
    if tmux_conf_src.exists():
        copy_file(tmux_conf_src, config.HOME_DIR / ".tmux.conf")
        print_success("  Installed .tmux.conf")
    
    # Install TPM (Tmux Plugin Manager)
    tpm_dir = config.HOME_DIR / ".tmux" / "plugins" / "tpm"
    if not tpm_dir.exists():
        print_info("  Installing Tmux Plugin Manager...")
        ensure_directory(tpm_dir.parent)
        
        if git_clone("https://github.com/tmux-plugins/tpm", tpm_dir):
            changes_log.log("TOOL", "Installed TPM", str(tpm_dir))
            print_success("  TPM installed")
            print_info("  Run tmux and press prefix + I to install plugins")
    else:
        print_info("  TPM already installed")


def _install_vim() -> None:
    """Install and configure Vim."""
    print_info("Configuring Vim...")
    
    # Install vim
    if not command_exists("vim"):
        install_apt_package("vim")
        print_success("  Installed vim")
    else:
        print_info("  vim already installed")
    
    # Install .vimrc
    vimrc_src = config.CONFIG_FILES_DIR / ".vimrc"
    if vimrc_src.exists():
        copy_file(vimrc_src, config.HOME_DIR / ".vimrc")
        print_success("  Installed .vimrc")
    
    # Create vim directories
    vim_dirs = [
        config.HOME_DIR / ".vim" / "backups",
        config.HOME_DIR / ".vim" / "swaps",
    ]
    for vim_dir in vim_dirs:
        ensure_directory(vim_dir)
    
    # Install Vundle
    vundle_dir = config.HOME_DIR / ".vim" / "bundle" / "Vundle.vim"
    if not vundle_dir.exists():
        print_info("  Installing Vundle...")
        ensure_directory(vundle_dir.parent)
        
        if git_clone("https://github.com/VundleVim/Vundle.vim.git", vundle_dir):
            changes_log.log("TOOL", "Installed Vundle", str(vundle_dir))
            print_success("  Vundle installed")
            print_info("  Run vim +PluginInstall +qall to install plugins")
    else:
        print_info("  Vundle already installed")


def install_terminal_apps() -> None:
    """Install terminal applications (Tabby)."""
    _install_tabby()


def _install_tabby() -> None:
    """Install and configure Tabby terminal."""
    print_info("Configuring Tabby terminal...")
    
    if not command_exists("tabby"):
        print_info("  Installing Tabby...")
        
        # Add Tabby repository and install
        returncode, _, _ = run_command(
            "curl -s https://packagecloud.io/install/repositories/eugeny/tabby/script.deb.sh | sudo bash",
            shell=True,
            check=False,
        )
        
        if returncode == 0:
            install_apt_package("tabby-terminal")
            changes_log.log("PACKAGE", "Installed Tabby", "tabby-terminal")
            print_success("  Tabby installed")
    else:
        print_info("  Tabby already installed")
    
    # Install Tabby config
    tabby_config_src = config.CONFIG_FILES_DIR / "tabby_config.yaml"
    if tabby_config_src.exists():
        tabby_config_dest = config.CONFIG_DIR / "tabby" / "config.yaml"
        ensure_directory(tabby_config_dest.parent)
        copy_file(tabby_config_src, tabby_config_dest)
        print_success("  Installed Tabby config")


def install_desktop_apps() -> None:
    """Install desktop applications (Ulauncher, Plank)."""
    _install_ulauncher()
    _install_plank()


def _install_ulauncher() -> None:
    """Install Ulauncher application launcher."""
    print_info("Installing Ulauncher...")
    
    if not command_exists("ulauncher"):
        # Add PPA and install
        run_command(
            ["add-apt-repository", "-y", "ppa:agornostal/ulauncher"],
            sudo=True,
            check=False,
        )
        run_command(["apt", "update", "-qq"], sudo=True, check=False)
        
        if install_apt_package("ulauncher"):
            changes_log.log("PACKAGE", "Installed Ulauncher", "ulauncher")
            print_success("  Ulauncher installed")
    else:
        print_info("  Ulauncher already installed")


def _install_plank() -> None:
    """Install Plank dock."""
    print_info("Installing Plank dock...")
    
    if not command_exists("plank"):
        if install_apt_package("plank"):
            changes_log.log("PACKAGE", "Installed Plank", "plank")
            print_success("  Plank installed")
    else:
        print_info("  Plank already installed")


def configure_remnote() -> None:
    """Configure RemNote desktop entry."""
    print_info("Configuring RemNote...")
    
    # Install icon
    remnote_icon_src = config.REMNOTE_DIR / "remnote.png"
    if remnote_icon_src.exists():
        remnote_icon_dest = Path("/usr/share/icons/remnote.png")
        run_command(
            ["cp", str(remnote_icon_src), str(remnote_icon_dest)],
            sudo=True,
            check=False,
        )
        changes_log.log("ICON", "Installed RemNote icon", str(remnote_icon_dest))
        print_success("  Installed RemNote icon")
    
    # Install desktop file
    remnote_desktop_src = config.REMNOTE_DIR / "remnote.desktop"
    if remnote_desktop_src.exists():
        apps_dir = config.LOCAL_SHARE / "applications"
        ensure_directory(apps_dir)
        copy_file(remnote_desktop_src, apps_dir / "remnote.desktop")
        print_success("  Installed RemNote desktop entry")
    
    print_info("Note: Move RemNote AppImage to ~/.local/bin/ manually")
