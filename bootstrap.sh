#!/bin/bash
#
# DevTools Bootstrap Script
# Installs uv (Python package manager) and runs the Python CLI
#
# Usage:
#   ./bootstrap.sh              # Run full installation
#   ./bootstrap.sh install      # Run specific command
#   ./bootstrap.sh --help       # Show help
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;94m'
NC='\033[0m'

print_blue() { echo -e "${BLUE}${1}${NC}"; }
print_green() { echo -e "${GREEN}${1}${NC}"; }
print_yellow() { echo -e "${YELLOW}${1}${NC}"; }
print_red() { echo -e "${RED}${1}${NC}"; }

# Check for required tools
check_prerequisites() {
    print_blue "Checking prerequisites..."
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        print_red "Error: curl or wget is required but not installed."
        print_yellow "Install with: sudo apt install curl"
        exit 1
    fi
    
    print_green "  Prerequisites OK"
}

# Install uv if not present
install_uv() {
    if command -v uv &> /dev/null; then
        print_green "  uv is already installed: $(uv --version)"
        return 0
    fi
    
    print_blue "Installing uv (Python package manager)..."
    
    if command -v curl &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        wget -qO- https://astral.sh/uv/install.sh | sh
    fi
    
    # Add uv to PATH for this session
    export PATH="${HOME}/.local/bin:${PATH}"
    
    if command -v uv &> /dev/null; then
        print_green "  uv installed successfully: $(uv --version)"
    else
        print_red "Error: uv installation failed"
        exit 1
    fi
}

# Install Python via uv
install_python() {
    print_blue "Ensuring Python 3.12 is available..."
    
    # uv will automatically install Python if needed when we run uv sync
    # But we can explicitly install it
    if ! uv python list 2>/dev/null | grep -q "3.12"; then
        print_blue "  Installing Python 3.12 via uv..."
        uv python install 3.12
    fi
    
    print_green "  Python ready"
}

# Sync dependencies
sync_dependencies() {
    print_blue "Syncing Python dependencies..."
    
    cd "$SCRIPT_DIR"
    
    if [ ! -f "pyproject.toml" ]; then
        print_red "Error: pyproject.toml not found in $SCRIPT_DIR"
        exit 1
    fi
    
    uv sync
    
    print_green "  Dependencies synced"
}

# Run the Python CLI
run_devtools() {
    cd "$SCRIPT_DIR"
    
    # Pass all arguments to the Python CLI
    if [ $# -eq 0 ]; then
        # Default: run install command
        uv run devtools install
    else
        uv run devtools "$@"
    fi
}

# Main
main() {
    print_blue "=========================================="
    print_blue "  DevTools Bootstrap"
    print_blue "=========================================="
    echo
    
    check_prerequisites
    install_uv
    install_python
    sync_dependencies
    
    echo
    print_blue "=========================================="
    print_blue "  Running DevTools CLI"
    print_blue "=========================================="
    echo
    
    run_devtools "$@"
}

main "$@"
