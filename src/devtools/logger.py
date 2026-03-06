"""
Rich-based logging and console output utilities.
"""

import logging
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Optional

from rich.console import Console
from rich.logging import RichHandler
from rich.panel import Panel
from rich.progress import (
    Progress,
    SpinnerColumn,
    TextColumn,
    BarColumn,
    TaskProgressColumn,
    TimeRemainingColumn,
)
from rich.table import Table
from rich.theme import Theme

from . import config

# Custom theme
custom_theme = Theme({
    "info": "cyan",
    "success": "green",
    "warning": "yellow",
    "error": "bright_red bold",
    "error_panel": "bold bright_white on bright_red",
    "step": "blue bold",
})

# Global console
console = Console(theme=custom_theme)

# Configure logging
def setup_logging(verbose: bool = False) -> logging.Logger:
    """Set up Rich logging handler."""
    level = logging.DEBUG if verbose else logging.INFO
    
    logging.basicConfig(
        level=level,
        format="%(message)s",
        datefmt="[%X]",
        handlers=[RichHandler(console=console, rich_tracebacks=True)],
    )
    
    return logging.getLogger("devtools")


logger = setup_logging()


def print_header(title: str) -> None:
    """Print a styled header panel."""
    console.print()
    console.print(Panel(title, style="bold blue", expand=False))
    console.print()


def print_step(step_num: int, total: int, message: str) -> None:
    """Print a step indicator."""
    console.print(f"[step]\\[{step_num}/{total}][/step] {message}")


def print_success(message: str) -> None:
    """Print a success message."""
    console.print(f"[success]✓[/success] {message}")


def print_warning(message: str) -> None:
    """Print a warning message."""
    console.print(f"[warning]⚠[/warning] {message}")


def print_error(message: str) -> None:
    """Print an error message in a visible red panel."""
    console.print()
    console.print(Panel(
        f"[bold bright_white]✗ ERROR[/bold bright_white]\n\n{message}",
        style="bold bright_red",
        border_style="bright_red",
        expand=False,
    ))
    console.print()


def print_exception(error: Exception, context: str = "") -> None:
    """Print exception details in a highly visible format."""
    console.print()
    error_title = "EXCEPTION OCCURRED"
    if context:
        error_title = f"{error_title} - {context}"
    
    error_type = type(error).__name__
    
    error_content = f"[bold bright_white]Type:[/bold bright_white] {error_type}\n"
    error_content += f"[bold bright_white]Message:[/bold bright_white] {error}\n"
    
    if isinstance(error, subprocess.CalledProcessError):
        error_content += f"\n[bold bright_white]Command:[/bold bright_white] {' '.join(error.cmd) if isinstance(error.cmd, list) else error.cmd}\n"
        error_content += f"[bold bright_white]Return Code:[/bold bright_white] {error.returncode}\n"
        if error.stdout:
            error_content += f"\n[bold bright_white]STDOUT:[/bold bright_white]\n{error.stdout}\n"
        if error.stderr:
            error_content += f"\n[bold bright_white]STDERR:[/bold bright_white]\n{error.stderr}\n"
    
    console.print(Panel(
        error_content,
        title=f"[bold bright_white]{error_title}[/bold bright_white]",
        style="bold bright_red",
        border_style="bright_red",
        expand=False,
    ))
    console.print()


def print_info(message: str) -> None:
    """Print an info message."""
    console.print(f"[info]ℹ[/info] {message}")


def create_progress() -> Progress:
    """Create a Rich progress bar."""
    return Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TaskProgressColumn(),
        TimeRemainingColumn(),
        console=console,
    )


def print_table(title: str, columns: list[str], rows: list[list[str]]) -> None:
    """Print a formatted table."""
    table = Table(title=title)
    
    for col in columns:
        table.add_column(col)
    
    for row in rows:
        table.add_row(*row)
    
    console.print(table)


# Changes log for rollback
class ChangesLogger:
    """Logger for tracking changes for rollback."""
    
    def __init__(self, log_path: Optional[Path] = None):
        self.log_path = log_path or config.CHANGES_LOG
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
    
    def log(self, change_type: str, description: str, details: str = "") -> None:
        """Log a change for rollback tracking."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        entry = f"[{timestamp}] [{change_type}] {description} | {details}\n"
        
        with open(self.log_path, "a") as f:
            f.write(entry)
    
    def start_session(self) -> None:
        """Mark the start of an installation session."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(self.log_path, "a") as f:
            f.write(f"\n=== Session started at {timestamp} ===\n")


# Install log for detailed output
class InstallLogger:
    """Logger for detailed installation output."""
    
    def __init__(self, log_path: Optional[Path] = None):
        self.log_path = log_path or config.INSTALL_LOG
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
    
    def log(self, message: str) -> None:
        """Log a message to the install log."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(self.log_path, "a") as f:
            f.write(f"[{timestamp}] {message}\n")
    
    def log_command(self, command: str, output: str, returncode: int) -> None:
        """Log a command execution."""
        self.log(f"CMD: {command}")
        self.log(f"EXIT: {returncode}")
        if output:
            self.log(f"OUTPUT:\n{output}")


# Global loggers
changes_log = ChangesLogger()
install_log = InstallLogger()
