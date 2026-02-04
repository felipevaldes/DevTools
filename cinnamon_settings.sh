#!/bin/bash
#
# Cinnamon Settings Configuration
# Applies Cinnamon settings from a config file to the current system
#
# This script restores:
#   - dconf/gsettings configuration (themes, panel, keybindings, etc.)
#   - Applet/extension configurations (JSON files from spices directory)
#   - Custom keyboard shortcuts
#
# Usage:
#   ./cinnamon_settings.sh                      # Uses current.conf + current_spices
#   ./cinnamon_settings.sh --config <file>      # Uses specified config file
#   ./cinnamon_settings.sh --list               # List available config files
#   ./cinnamon_settings.sh --dry-run            # Show what would be applied
#

set -euo pipefail

# Source common utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/common.sh" ]; then
    source "${SCRIPT_DIR}/common.sh"
else
    # Fallback print functions if common.sh not available
    print_blue() { echo -e "\033[0;94m${1}\033[0m"; }
    print_green() { echo -e "\033[0;32m${1}\033[0m"; }
    print_yellow() { echo -e "\033[0;33m${1}\033[0m"; }
    print_red() { echo -e "\033[0;31m${1}\033[0m"; }
fi

# Configuration
CONFIG_DIR="${SCRIPT_DIR}/config_files/cinnamon"
DEFAULT_CONFIG="${CONFIG_DIR}/current.conf"
DEFAULT_SPICES="${CONFIG_DIR}/current_spices"
CINNAMON_SPICES_DEST="${HOME}/.config/cinnamon/spices"

# Parse command line arguments
CONFIG_FILE=""
SPICES_DIR=""
LIST_MODE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --config|-c)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --spices|-s)
            SPICES_DIR="$2"
            shift 2
            ;;
        --list|-l)
            LIST_MODE=true
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --config, -c <file>   Use specified config file"
            echo "  --spices, -s <dir>    Use specified spices directory"
            echo "  --list, -l            List available config files"
            echo "  --dry-run, -n         Show what would be applied without making changes"
            echo "  --help, -h            Show this help message"
            echo ""
            echo "If no config file is specified, uses:"
            echo "  Config: $DEFAULT_CONFIG"
            echo "  Spices: $DEFAULT_SPICES"
            exit 0
            ;;
        *)
            print_red "Unknown option: $1"
            exit 1
            ;;
    esac
done

#=============================================================================
# List available config files
#=============================================================================
list_configs() {
    print_blue "Available Cinnamon configuration files:"
    echo ""
    
    if [ ! -d "$CONFIG_DIR" ]; then
        print_yellow "  Config directory not found: $CONFIG_DIR"
        print_yellow "  Run ./export_cinnamon_settings.sh to create it."
        return
    fi
    
    local count=0
    for file in "$CONFIG_DIR"/*_cinnamon.conf; do
        if [ -f "$file" ]; then
            local basename=$(basename "$file")
            local is_current=""
            
            # Check if this is the current config
            if [ -L "$DEFAULT_CONFIG" ]; then
                local link_target=$(readlink "$DEFAULT_CONFIG")
                if [ "$basename" = "$link_target" ]; then
                    is_current=" (current)"
                fi
            fi
            
            # Extract metadata from file
            local hostname=$(grep "^# Exported from:" "$file" 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "unknown")
            local date=$(grep "^# Date:" "$file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "unknown")
            local settings_count=$(grep -c "^[^#\[].*=" "$file" 2>/dev/null || echo "0")
            
            # Check for corresponding spices directory
            local spices_dir="${file%_cinnamon.conf}_spices"
            local has_spices="no"
            [ -d "$spices_dir" ] && has_spices="yes"
            
            echo "  $basename$is_current"
            echo "    Hostname: $hostname"
            echo "    Date: $date"
            echo "    Settings: $settings_count"
            echo "    Has spices: $has_spices"
            echo ""
            ((count++)) || true
        fi
    done
    
    if [ $count -eq 0 ]; then
        print_yellow "  No config files found."
        print_yellow "  Run ./export_cinnamon_settings.sh to create one."
    fi
}

#=============================================================================
# Apply dconf settings from config file
#=============================================================================
apply_dconf_settings() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        print_red "Config file not found: $config_file"
        return 1
    fi
    
    print_blue "Applying dconf settings from: $(basename "$config_file")"
    
    local current_schema=""
    local applied_count=0
    local error_count=0
    local skipped_count=0
    local in_custom_keybinding=false
    local kb_path=""
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        if [ -z "$line" ] || [[ "$line" =~ ^# ]]; then
            continue
        fi
        
        # Check if this is a section header [schema]
        if [[ "$line" =~ ^\[.*\]$ ]]; then
            # Extract schema from [schema]
            current_schema="${line:1:-1}"
            
            # Check if this is a custom keybinding section
            if [[ "$current_schema" =~ ^custom-keybinding: ]]; then
                in_custom_keybinding=true
                kb_path="${current_schema#custom-keybinding:}"
            else
                in_custom_keybinding=false
            fi
            continue
        fi
        
        # Skip if we don't have a schema yet
        if [ -z "$current_schema" ]; then
            continue
        fi
        
        # Parse key=value
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Skip certain dynamic/system-specific settings
            case "$key" in
                night-light-last-coordinates)
                    ((skipped_count++)) || true
                    continue
                    ;;
            esac
            
            if [ "$DRY_RUN" = true ]; then
                if [ "$in_custom_keybinding" = true ]; then
                    echo "  [DRY-RUN] gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$kb_path $key $value"
                else
                    echo "  [DRY-RUN] gsettings set $current_schema $key $value"
                fi
                ((applied_count++)) || true
                continue
            fi
            
            # Apply the setting
            local target_schema="$current_schema"
            if [ "$in_custom_keybinding" = true ]; then
                target_schema="org.cinnamon.desktop.keybindings.custom-keybinding:$kb_path"
            fi
            
            if gsettings set "$target_schema" "$key" "$value" 2>/dev/null; then
                ((applied_count++)) || true
            else
                # Try without quotes for certain value types
                local unquoted_value="${value#\'}"
                unquoted_value="${unquoted_value%\'}"
                
                if gsettings set "$target_schema" "$key" "$unquoted_value" 2>/dev/null; then
                    ((applied_count++)) || true
                else
                    # Don't warn for custom keybindings that might not exist yet
                    if [ "$in_custom_keybinding" != true ]; then
                        print_yellow "  Warning: Failed to apply $target_schema $key"
                    fi
                    ((error_count++)) || true
                fi
            fi
        fi
    done < "$config_file"
    
    echo ""
    print_green "  Settings applied: $applied_count"
    if [ $skipped_count -gt 0 ]; then
        print_yellow "  Settings skipped: $skipped_count (system-specific)"
    fi
    if [ $error_count -gt 0 ]; then
        print_yellow "  Settings failed: $error_count"
    fi
}

#=============================================================================
# Apply spices (applet/extension) configurations
#=============================================================================
apply_spices_configs() {
    local spices_src="$1"
    
    if [ ! -d "$spices_src" ]; then
        print_yellow "Spices directory not found: $spices_src"
        print_yellow "  Skipping applet/extension configuration restore"
        return
    fi
    
    print_blue "Applying applet/extension configurations from: $(basename "$spices_src")"
    
    # Create destination directory if it doesn't exist
    mkdir -p "$CINNAMON_SPICES_DEST"
    
    local copied_count=0
    local spice_count=0
    
    for spice_dir in "$spices_src"/*/; do
        if [ -d "$spice_dir" ]; then
            local spice_name=$(basename "$spice_dir")
            
            # Skip manifest.txt
            if [ "$spice_name" = "manifest.txt" ]; then
                continue
            fi
            
            # Create destination spice directory
            mkdir -p "${CINNAMON_SPICES_DEST}/${spice_name}"
            
            # Copy JSON files
                for json_file in "$spice_dir"*.json; do
                if [ -f "$json_file" ]; then
                    local json_name=$(basename "$json_file")
                    
                    if [ "$DRY_RUN" = true ]; then
                        echo "  [DRY-RUN] cp $json_file -> ${CINNAMON_SPICES_DEST}/${spice_name}/${json_name}"
                    else
                        cp "$json_file" "${CINNAMON_SPICES_DEST}/${spice_name}/"
                    fi
                    ((copied_count++)) || true
                fi
            done
            ((spice_count++)) || true
        fi
    done
    
    echo ""
    print_green "  Spices restored: $spice_count"
    print_green "  Config files copied: $copied_count"
}

#=============================================================================
# Main execution
#=============================================================================
main() {
    # Handle list mode
    if [ "$LIST_MODE" = true ]; then
        list_configs
        exit 0
    fi
    
    print_blue "=========================================="
    print_blue "  Cinnamon Settings Configuration"
    print_blue "=========================================="
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        print_yellow "DRY-RUN MODE: No changes will be made"
        echo ""
    fi
    
    # Determine which config file to use
    if [ -z "$CONFIG_FILE" ]; then
        CONFIG_FILE="$DEFAULT_CONFIG"
    fi
    
    # Determine which spices directory to use
    if [ -z "$SPICES_DIR" ]; then
        # Try to find matching spices directory
        local config_base="${CONFIG_FILE%_cinnamon.conf}"
        if [ -d "${config_base}_spices" ]; then
            SPICES_DIR="${config_base}_spices"
        elif [ -d "$DEFAULT_SPICES" ] || [ -L "$DEFAULT_SPICES" ]; then
            SPICES_DIR="$DEFAULT_SPICES"
        fi
    fi
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        print_red "Config file not found: $CONFIG_FILE"
        echo ""
        print_yellow "Available options:"
        print_yellow "  1. Run ./export_cinnamon_settings.sh to export current settings"
        print_yellow "  2. Specify a config file with --config <file>"
        print_yellow "  3. Use --list to see available config files"
        exit 1
    fi
    
    # Check if gsettings is available
    if ! command -v gsettings &> /dev/null; then
        print_red "Error: gsettings command not found."
        exit 1
    fi
    
    # Apply dconf settings
    apply_dconf_settings "$CONFIG_FILE"
    
    # Apply spices configurations
    if [ -n "$SPICES_DIR" ]; then
        # Resolve symlink if needed
        if [ -L "$SPICES_DIR" ]; then
            local resolved_dir="${CONFIG_DIR}/$(readlink "$SPICES_DIR")"
            if [ -d "$resolved_dir" ]; then
                SPICES_DIR="$resolved_dir"
            fi
        fi
        apply_spices_configs "$SPICES_DIR"
    fi
    
    echo ""
    print_blue "=========================================="
    print_green "Cinnamon configuration applied!"
    print_blue "=========================================="
    echo ""
    print_yellow "Notes:"
    print_yellow "  - Some settings may require logout/login to take effect"
    print_yellow "  - Panel applets must be installed via Cinnamon Settings > Applets"
    print_yellow "  - Extensions must be installed via Cinnamon Settings > Extensions"
    print_yellow "  - Run 'cinnamon --replace &' to reload Cinnamon without logout"
}

# Run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
