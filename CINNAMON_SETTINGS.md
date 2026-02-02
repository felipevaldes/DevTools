# Cinnamon Settings Configuration

This document describes the custom Cinnamon settings extracted from your current system and how they differ from default Ubuntu Cinnamon installation.

## Overview

The `cinnamon_settings.sh` file contains explicit `gsettings` commands that replicate your current Cinnamon configuration on a fresh Ubuntu Cinnamon installation.

## Key Differences from Default Settings

### 1. **Theme Configuration**
- **GTK Theme**: `WhiteSur-Dark` (default: `Mint-Y-Dark` or `Adwaita-dark`)
- **Icon Theme**: `WhiteSur-dark` (default: `Mint-Y-Dark`)
- **Cursor Theme**: `McMojave-cursors` (default: `DMZ-White` or `Adwaita`)
- **Fonts**: `San Francisco Text 11` and `San Francisco Display Medium 11` (default: Ubuntu fonts)

### 2. **Alt-Tab Switcher**
- **Delay**: 100ms (default: 250ms)
- **Style**: `icons+preview` (default: `icons` or `thumbnails`)
- **Show all workspaces**: `false` (default: `true`)
- **Warp mouse pointer**: `true` (default: `false`)

### 3. **Window Manager Keybindings**
- **Close window**: `<Super>w` (default: `<Alt>F4`)
- **Switch windows**: `<Alt>Tab` (default: same)
- **Switch panels**: `<Super>Tab` (default: not set)

### 4. **Panel Configuration**
- **Position**: Top (default: Bottom)
- **Height**: 25px
- **Applets**: Custom arrangement with:
  - Cinnamenu (left side)
  - Calendar (center)
  - Various system applets (right side)
  - Custom applets: Weather, Expo, Scale, User, Sound150

### 5. **Extensions**
- **Transparent Panels**: `transparent-panels@germanfr` (not in default)

### 6. **Workspace/Expo**
- **Expo view as grid**: `true` (default: `false`)
- **Hot corners**: All disabled (default: may have some enabled)

### 7. **Window Manager Preferences**
- **Min window opacity**: 30 (default: 0)
- **Mouse button modifier**: `<Super>` (default: `<Alt>`)

### 8. **Peripheral Settings**
- **Keyboard delay**: 500ms (default: 300ms)
- **Keyboard repeat interval**: 30ms (default: 20ms)
- **Mouse double-click**: 400ms
- **Touchpad natural scroll**: `false` (default: may vary)

### 9. **Sound Settings**
- **Event sounds**: `false` (default: `true`)
- **All sound effects disabled**: close, notification, switch, tile

### 10. **Power Management**
- **Lid close action**: Suspend (both AC and battery)
- **Display sleep**: 1800 seconds (30 minutes)
- **Inactive timeout**: 0 (disabled)

### 11. **Night Light**
- **Enabled**: `true`
- **Schedule mode**: Manual
- **Schedule**: 20:75 to 5:0
- **Temperature**: 2700K

### 12. **Gestures** (if supported)
- **Enabled**: `true`
- Custom swipe and tap gestures configured

### 13. **Muffin (Window Manager)**
- **Draggable border width**: 10px
- **Experimental features**: Fractional scaling enabled
- **Workspace cycle**: `true`

## Usage

### In Install Script

The `install.sh` script automatically sources and applies these settings:

```bash
source "${SCRIPT_DIR}/cinnamon_settings.sh"
apply_cinnamon_settings
```

### Standalone Usage

You can also run the settings file directly:

```bash
source cinnamon_settings.sh
apply_cinnamon_settings
```

## Manual Steps Required

Some settings cannot be automated and require manual configuration:

1. **Panel Applets**: 
   - Install applets via `Cinnamon Settings > Applets`
   - The script sets the applet order, but applets must be installed first
   - Required applets:
     - `weather@mockturtl` (Weather applet)
     - `expo@cinnamon.org` (Expo applet)
     - `scale@cinnamon.org` (Scale applet)
     - `user@cinnamon.org` (User applet)
     - `Cinnamenu@json` (Cinnamenu)
     - `sound150@claudiux` (Sound applet)

2. **Extensions**:
   - Install `transparent-panels@germanfr` via `Cinnamon Settings > Extensions`
   - The script enables it, but it must be installed first

3. **Applet Configuration**:
   - Some applets may need individual configuration after installation
   - Check applet settings in `Cinnamon Settings > Applets`

## Rollback

To reset to default Cinnamon settings, you can:

1. Use `dconf reset` commands for each setting
2. Or restore from a backup created before installation
3. Or manually reset via `Cinnamon Settings`

## Notes

- Settings are applied using `gsettings` which is the standard way to configure Cinnamon
- Some settings may require a logout/login or restart to take full effect
- Panel applet IDs are system-specific and may need adjustment on different systems
- The extension ID `transparent-panels@germanfr` must match exactly what's available in Cinnamon Spices
