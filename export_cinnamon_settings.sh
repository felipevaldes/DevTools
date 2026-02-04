#!/bin/bash
#
# Export Cinnamon Settings
# Exports all Cinnamon settings including:
#   - dconf settings (themes, panel, keybindings, etc.)
#   - Applet/extension configurations (JSON files)
#   - Custom keyboard shortcuts
#
# Output: {hostname}_{date}_cinnamon.conf + spices/ directory
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
OUTPUT_DIR="${SCRIPT_DIR}/config_files/cinnamon"
HOSTNAME=$(hostname)
DATE=$(date +%Y%m%d)
DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
OUTPUT_BASE="${HOSTNAME}_${DATE}"
OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_BASE}_cinnamon.conf"
SPICES_DIR="${OUTPUT_DIR}/${OUTPUT_BASE}_spices"
CURRENT_LINK="${OUTPUT_DIR}/current.conf"
CURRENT_SPICES_LINK="${OUTPUT_DIR}/current_spices"

# Cinnamon spices config location
CINNAMON_SPICES_SRC="${HOME}/.config/cinnamon/spices"

# Create output directories
mkdir -p "$OUTPUT_DIR"

print_blue "Exporting Cinnamon settings..."
print_blue "  Hostname: $HOSTNAME"
print_blue "  Output: $OUTPUT_FILE"

#=============================================================================
# PART 1: Export dconf settings (themes, panel config, keybindings, etc.)
#=============================================================================
export_dconf_settings() {
    print_blue "Exporting dconf settings..."
    
    # Write header
    cat > "$OUTPUT_FILE" << EOF
# Cinnamon Settings Configuration
# Exported from: $HOSTNAME
# Date: $DATETIME
#
# This file contains Cinnamon desktop settings in INI-style format.
# Each section [schema] contains key=value pairs that can be applied
# using gsettings set <schema> <key> <value>
#
# COMPONENTS:
#   1. This file (.conf) - dconf/gsettings configuration
#   2. ${OUTPUT_BASE}_spices/ - Applet/extension JSON configs
#
# To apply these settings, use:
#   ./cinnamon_settings.sh --config "$OUTPUT_FILE"
#
# Or set as current config:
#   ln -sf "${OUTPUT_BASE}_cinnamon.conf" current.conf
#   ln -sf "${OUTPUT_BASE}_spices" current_spices

EOF

    # Dump all cinnamon settings and parse
    dconf dump /org/cinnamon/ | while IFS= read -r line; do
        # Skip empty lines
        if [ -z "$line" ]; then
            echo "" >> "$OUTPUT_FILE"
            continue
        fi
        
        # Check if this is a section header [path]
        if [[ "$line" =~ ^\[.*\]$ ]]; then
            # Extract path from [path]
            local path="${line:1:-1}"
            
            # Convert to schema format
            if [ "$path" = "/" ]; then
                current_schema="org.cinnamon"
            else
                # Remove leading slash if present, then prepend org.cinnamon
                path="${path#/}"
                current_schema="org.cinnamon.${path//\//.}"
            fi
            
            echo "[$current_schema]" >> "$OUTPUT_FILE"
        else
            # This is a key=value line, write as-is
            echo "$line" >> "$OUTPUT_FILE"
        fi
    done
    
    local count=$(grep -c "^[^#\[].*=" "$OUTPUT_FILE" 2>/dev/null || echo "0")
    print_green "  Exported $count dconf settings"
}

#=============================================================================
# PART 2: Export custom keyboard shortcuts
#=============================================================================
export_custom_keybindings() {
    print_blue "Exporting custom keyboard shortcuts..."
    
    # Check if there are custom keybindings
    local custom_list=$(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null || echo "@as []")
    
    if [ "$custom_list" = "@as []" ] || [ "$custom_list" = "[]" ]; then
        print_yellow "  No custom keyboard shortcuts found"
        return
    fi
    
    # Add custom keybindings section to config file
    echo "" >> "$OUTPUT_FILE"
    echo "# ============================================" >> "$OUTPUT_FILE"
    echo "# CUSTOM KEYBOARD SHORTCUTS" >> "$OUTPUT_FILE"
    echo "# ============================================" >> "$OUTPUT_FILE"
    echo "[org.cinnamon.desktop.keybindings]" >> "$OUTPUT_FILE"
    echo "custom-list=$custom_list" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Export each custom keybinding
    # Parse the custom-list to get individual keybinding paths
    local keybindings=$(echo "$custom_list" | tr -d "[]'" | tr ',' '\n')
    local kb_count=0
    
    for kb in $keybindings; do
        if [ -n "$kb" ]; then
            kb=$(echo "$kb" | tr -d ' ')
            local schema="org.cinnamon.desktop.keybindings.custom-keybinding:$kb"
            
            echo "[custom-keybinding:$kb]" >> "$OUTPUT_FILE"
            
            # Get each property
            local name=$(gsettings get org.cinnamon.desktop.keybindings.custom-keybinding:$kb name 2>/dev/null || echo "''")
            local command=$(gsettings get org.cinnamon.desktop.keybindings.custom-keybinding:$kb command 2>/dev/null || echo "''")
            local binding=$(gsettings get org.cinnamon.desktop.keybindings.custom-keybinding:$kb binding 2>/dev/null || echo "''")
            
            echo "name=$name" >> "$OUTPUT_FILE"
            echo "command=$command" >> "$OUTPUT_FILE"
            echo "binding=$binding" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            
            ((kb_count++))
        fi
    done
    
    print_green "  Exported $kb_count custom keyboard shortcuts"
}

#=============================================================================
# PART 3: Export applet/extension configurations (JSON files)
#=============================================================================
export_spices_configs() {
    print_blue "Exporting applet/extension configurations..."
    
    # Remove existing spices directory if it exists
    if [ -d "$SPICES_DIR" ]; then
        rm -rf "$SPICES_DIR"
    fi
    mkdir -p "$SPICES_DIR"
    
    local spices_count=0
    
    # Check if source directory exists
    if [ ! -d "$CINNAMON_SPICES_SRC" ]; then
        print_yellow "  No spices config directory found at: $CINNAMON_SPICES_SRC"
        return
    fi
    
    # Copy all JSON config files
    # Use shopt to handle empty globs gracefully
    shopt -s nullglob
    
    for spice_dir in "$CINNAMON_SPICES_SRC"/*; do
        if [ -d "$spice_dir" ]; then
            local spice_name=$(basename "$spice_dir")
            local has_json=false
            
            # Check if there are any JSON files first
            for json_file in "$spice_dir"/*.json; do
                if [ -f "$json_file" ]; then
                    has_json=true
                    break
                fi
            done
            
            # Only create directory and copy if there are JSON files
            if [ "$has_json" = true ]; then
                mkdir -p "${SPICES_DIR}/${spice_name}"
                
                # Copy all JSON files from this spice's directory
                for json_file in "$spice_dir"/*.json; do
                    if [ -f "$json_file" ]; then
                        cp "$json_file" "${SPICES_DIR}/${spice_name}/"
                        ((spices_count++)) || true
                    fi
                done
            fi
        fi
    done
    
    shopt -u nullglob
    
    # Create a manifest file listing all exported spices
    cat > "${SPICES_DIR}/manifest.txt" << EOF
# Cinnamon Spices Configuration Manifest
# Exported from: $HOSTNAME
# Date: $DATETIME
#
# This directory contains JSON configuration files for Cinnamon applets,
# extensions, and desklets. These are copied from:
#   $CINNAMON_SPICES_SRC
#
# Structure:
#   {applet-name}/
#     {applet-name}.json or {instance-id}.json
#
# To restore, copy contents to ~/.config/cinnamon/spices/

EOF
    
    # List all exported spices
    echo "Exported spices:" >> "${SPICES_DIR}/manifest.txt"
    shopt -s nullglob
    for spice_dir in "$SPICES_DIR"/*/; do
        if [ -d "$spice_dir" ]; then
            local name=$(basename "$spice_dir")
            echo "  - $name" >> "${SPICES_DIR}/manifest.txt"
        fi
    done
    shopt -u nullglob
    
    print_green "  Exported $spices_count spice configuration files"
}

#=============================================================================
# PART 4: Update symlinks to current config
#=============================================================================
update_current_links() {
    print_blue "Updating current config links..."
    
    # Update main config symlink
    if [ -L "$CURRENT_LINK" ]; then
        rm "$CURRENT_LINK"
    elif [ -f "$CURRENT_LINK" ]; then
        mv "$CURRENT_LINK" "${CURRENT_LINK}.backup"
    fi
    ln -s "${OUTPUT_BASE}_cinnamon.conf" "$CURRENT_LINK"
    print_green "  current.conf -> ${OUTPUT_BASE}_cinnamon.conf"
    
    # Update spices directory symlink
    if [ -L "$CURRENT_SPICES_LINK" ]; then
        rm "$CURRENT_SPICES_LINK"
    elif [ -d "$CURRENT_SPICES_LINK" ]; then
        mv "$CURRENT_SPICES_LINK" "${CURRENT_SPICES_LINK}.backup"
    fi
    ln -s "${OUTPUT_BASE}_spices" "$CURRENT_SPICES_LINK"
    print_green "  current_spices -> ${OUTPUT_BASE}_spices"
}

#=============================================================================
# MAIN
#=============================================================================
main() {
    print_blue "=========================================="
    print_blue "  Cinnamon Settings Export"
    print_blue "=========================================="
    echo
    
    # Check if dconf is available
    if ! command -v dconf &> /dev/null; then
        print_red "Error: dconf command not found. Please install dconf-cli."
        exit 1
    fi
    
    # Check if running Cinnamon
    if ! command -v cinnamon-settings &> /dev/null; then
        print_yellow "Warning: Cinnamon doesn't appear to be installed."
        print_yellow "Continuing anyway..."
    fi
    
    # Export all components
    export_dconf_settings
    export_custom_keybindings
    export_spices_configs
    
    # Update symlinks
    update_current_links
    
    echo
    print_blue "=========================================="
    print_green "Export complete!"
    print_blue "=========================================="
    echo
    print_yellow "Exported files:"
    print_yellow "  Config: $OUTPUT_FILE"
    print_yellow "  Spices: $SPICES_DIR/"
    echo
    print_yellow "To use on another system:"
    print_yellow "  1. Copy config_files/cinnamon/ to the target system"
    print_yellow "  2. Run: ./cinnamon_settings.sh"
}

# Run main
main "$@"
