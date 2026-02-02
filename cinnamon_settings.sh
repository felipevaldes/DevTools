#!/bin/bash
#
# Cinnamon Settings Configuration
# Applies custom Cinnamon settings from current system to fresh installation
#

# This function applies all custom Cinnamon settings
apply_cinnamon_settings() {
    print_blue "Applying Cinnamon desktop settings..."
    
    # ============================================
    # THEME SETTINGS
    # ============================================
    gsettings set org.cinnamon.theme name "WhiteSur-Dark"
    gsettings set org.cinnamon.desktop.interface gtk-theme "WhiteSur-Dark"
    gsettings set org.cinnamon.desktop.interface icon-theme "WhiteSur-dark"
    gsettings set org.cinnamon.desktop.interface cursor-theme "McMojave-cursors"
    gsettings set org.cinnamon.desktop.interface font-name "San Francisco Text 11"
    gsettings set org.cinnamon.desktop.wm.preferences titlebar-font "San Francisco Display Medium 11"
    gsettings set org.cinnamon.desktop.interface cursor-size 24
    gsettings set org.cinnamon.desktop.interface cursor-blink-time 1200
    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.0
    
    # ============================================
    # ALT-TAB SWITCHER SETTINGS
    # ============================================
    gsettings set org.cinnamon alttab-switcher-delay 100
    gsettings set org.cinnamon alttab-switcher-show-all-workspaces false
    gsettings set org.cinnamon alttab-switcher-style "icons+preview"
    gsettings set org.cinnamon alttab-switcher-warp-mouse-pointer true
    
    # ============================================
    # WINDOW MANAGER KEYBINDINGS
    # ============================================
    gsettings set org.cinnamon.desktop.keybindings.wm close "['<Super>w']"
    gsettings set org.cinnamon.desktop.keybindings.wm switch-windows "['<Alt>Tab']"
    gsettings set org.cinnamon.desktop.keybindings.wm switch-panels "['<Super>Tab']"
    gsettings set org.cinnamon.desktop.keybindings.wm begin-move "@as []"
    gsettings set org.cinnamon.desktop.keybindings.wm begin-resize "@as []"
    gsettings set org.cinnamon.desktop.keybindings.wm switch-group "@as []"
    
    # ============================================
    # WINDOW MANAGER PREFERENCES
    # ============================================
    gsettings set org.cinnamon.desktop.wm.preferences min-window-opacity 30
    gsettings set org.cinnamon.desktop.wm.preferences mouse-button-modifier "<Super>"
    
    # ============================================
    # PANEL CONFIGURATION
    # ============================================
    # Panel position: top
    gsettings set org.cinnamon panels-enabled "['1:0:top']"
    gsettings set org.cinnamon panels-height "['1:25']"
    gsettings set org.cinnamon panel-edit-mode false
    
    # Panel applets configuration
    # Note: Applets must be installed first, this sets their order and position
    gsettings set org.cinnamon enabled-applets "['panel1:right:4:systray@cinnamon.org:3', 'panel1:right:5:xapp-status@cinnamon.org:4', 'panel1:right:6:notifications@cinnamon.org:5', 'panel1:right:7:printers@cinnamon.org:6', 'panel1:right:9:removable-drives@cinnamon.org:7', 'panel1:right:10:keyboard@cinnamon.org:8', 'panel1:right:11:favorites@cinnamon.org:9', 'panel1:right:13:network@cinnamon.org:10', 'panel1:right:14:power@cinnamon.org:12', 'panel1:center:0:calendar@cinnamon.org:13', 'panel1:right:0:force-quit@cinnamon.org:15', 'panel1:right:3:weather@mockturtl:17', 'panel1:right:2:expo@cinnamon.org:18', 'panel1:right:1:scale@cinnamon.org:19', 'panel1:right:16:user@cinnamon.org:20', 'panel1:left:0:Cinnamenu@json:21', 'panel1:right:12:sound150@claudiux:22']"
    
    gsettings set org.cinnamon next-applet-id 23
    
    # Panel icon sizes
    gsettings set org.cinnamon panel-zone-symbolic-icon-sizes "[{\"panelId\": 1, \"left\": 28, \"center\": 28, \"right\": 16}]"
    
    # ============================================
    # EXTENSIONS
    # ============================================
    # Note: Extension must be installed via Cinnamon Settings first
    gsettings set org.cinnamon enabled-extensions "['transparent-panels@germanfr']"
    
    # ============================================
    # WORKSPACE/EXPO SETTINGS
    # ============================================
    gsettings set org.cinnamon workspace-expo-view-as-grid true
    
    # Hot corners (all disabled)
    gsettings set org.cinnamon hotcorner-layout "['expo:false:0', 'scale:false:0', 'scale:false:0', 'desktop:false:0']"
    
    # ============================================
    # DESKTOP SETTINGS
    # ============================================
    gsettings set org.cinnamon.desktop.background picture-options "zoom"
    gsettings set org.cinnamon.desktop.background picture-uri "file:///usr/share/backgrounds/linuxmint-wilma/mpiwnicki_torres_del_paine.jpg"
    
    # Desktop slideshow (if using)
    gsettings set org.cinnamon.desktop.background.slideshow delay 15
    gsettings set org.cinnamon.desktop.background.slideshow image-source "xml:///usr/share/cinnamon-background-properties/linuxmint-wilma.xml"
    
    # ============================================
    # PERIPHERAL SETTINGS
    # ============================================
    # Keyboard
    gsettings set org.cinnamon.desktop.peripherals.keyboard delay 500
    gsettings set org.cinnamon.desktop.peripherals.keyboard repeat-interval 30
    
    # Mouse
    gsettings set org.cinnamon.desktop.peripherals.mouse double-click 400
    gsettings set org.cinnamon.desktop.peripherals.mouse drag-threshold 8
    gsettings set org.cinnamon.desktop.peripherals.mouse speed 0.0
    
    # Touchpad
    gsettings set org.cinnamon.desktop.peripherals.touchpad natural-scroll false
    gsettings set org.cinnamon.desktop.peripherals.touchpad speed 0.0
    
    # ============================================
    # SOUND SETTINGS
    # ============================================
    gsettings set org.cinnamon.desktop.sound event-sounds false
    
    # ============================================
    # NOTIFICATIONS
    # ============================================
    gsettings set org.cinnamon.desktop.notifications notification-duration 4
    
    # ============================================
    # SCREENSAVER
    # ============================================
    gsettings set org.cinnamon.desktop.screensaver show-album-art false
    
    # ============================================
    # MEDIA HANDLING
    # ============================================
    gsettings set org.cinnamon.desktop.media-handling autorun-never false
    gsettings set org.cinnamon.desktop.media-handling autorun-x-content-ignore "@as []"
    gsettings set org.cinnamon.desktop.media-handling autorun-x-content-open-folder "['x-content/image-dcf']"
    gsettings set org.cinnamon.desktop.media-handling autorun-x-content-start-app "['x-content/unix-software', 'x-content/image-dcf']"
    
    # ============================================
    # APPLICATION SHORTCUTS
    # ============================================
    gsettings set org.cinnamon.desktop.applications.terminal exec "gnome-terminal"
    gsettings set org.cinnamon.desktop.applications.terminal exec-arg "--"
    gsettings set org.cinnamon.desktop.applications.calculator exec "gnome-calculator"
    
    # ============================================
    # KEYBINDINGS
    # ============================================
    gsettings set org.cinnamon.desktop.keybindings looking-glass-keybinding "['<Primary><Alt>l']"
    gsettings set org.cinnamon.desktop.keybindings.media-keys screensaver "['<Super>l', 'XF86ScreenSaver']"
    
    # ============================================
    # GESTURES (if supported)
    # ============================================
    gsettings set org.cinnamon gestures enabled true
    gsettings set org.cinnamon gestures pinch-percent-threshold 40
    gsettings set org.cinnamon gestures swipe-percent-threshold 60
    gsettings set org.cinnamon gestures swipe-down-2 "PUSH_TILE_DOWN::end"
    gsettings set org.cinnamon gestures swipe-down-3 "TOGGLE_OVERVIEW::end"
    gsettings set org.cinnamon gestures swipe-down-4 "VOLUME_DOWN::end"
    gsettings set org.cinnamon gestures swipe-left-2 "PUSH_TILE_LEFT::end"
    gsettings set org.cinnamon gestures swipe-left-3 "WORKSPACE_NEXT::end"
    gsettings set org.cinnamon gestures swipe-left-4 "WINDOW_WORKSPACE_PREVIOUS::end"
    gsettings set org.cinnamon gestures swipe-right-2 "PUSH_TILE_RIGHT::end"
    gsettings set org.cinnamon gestures swipe-right-3 "WORKSPACE_PREVIOUS::end"
    gsettings set org.cinnamon gestures swipe-right-4 "WINDOW_WORKSPACE_NEXT::end"
    gsettings set org.cinnamon gestures swipe-up-2 "PUSH_TILE_UP::end"
    gsettings set org.cinnamon gestures swipe-up-3 "TOGGLE_EXPO::end"
    gsettings set org.cinnamon gestures swipe-up-4 "VOLUME_UP::end"
    gsettings set org.cinnamon gestures tap-3 "MEDIA_PLAY_PAUSE::end"
    
    # ============================================
    # MUFFIN (Window Manager) SETTINGS
    # ============================================
    gsettings set org.cinnamon.muffin draggable-border-width 10
    gsettings set org.cinnamon.muffin experimental-features "['scale-monitor-framebuffer', 'x11-randr-fractional-scaling']"
    gsettings set org.cinnamon.muffin workspace-cycle true
    
    # ============================================
    # SESSION SETTINGS
    # ============================================
    gsettings set org.cinnamon.session quit-time-delay 60
    
    # ============================================
    # LAUNCHER SETTINGS
    # ============================================
    gsettings set org.cinnamon.launcher check-frequency 300
    gsettings set org.cinnamon.launcher memory-limit 2048
    
    # ============================================
    # DESKLET SETTINGS
    # ============================================
    gsettings set org.cinnamon desklet-snap-interval 25
    gsettings set org.cinnamon enabled-desklets "@as []"
    
    # ============================================
    # SOUND EFFECTS
    # ============================================
    gsettings set org.cinnamon.sounds close-enabled false
    gsettings set org.cinnamon.sounds notification-enabled false
    gsettings set org.cinnamon.sounds switch-enabled false
    gsettings set org.cinnamon.sounds tile-enabled false
    
    # ============================================
    # SETTINGS DAEMON - POWER MANAGEMENT
    # ============================================
    gsettings set org.cinnamon.settings-daemon.plugins.power lid-close-ac-action "suspend"
    gsettings set org.cinnamon.settings-daemon.plugins.power lid-close-battery-action "suspend"
    gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-ac 1800
    gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 1800
    gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
    gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
    
    # ============================================
    # SETTINGS DAEMON - COLOR/NIGHT LIGHT
    # ============================================
    gsettings set org.cinnamon.settings-daemon.plugins.color night-light-enabled true
    gsettings set org.cinnamon.settings-daemon.plugins.color night-light-schedule-mode "manual"
    gsettings set org.cinnamon.settings-daemon.plugins.color night-light-schedule-from 20.75
    gsettings set org.cinnamon.settings-daemon.plugins.color night-light-schedule-to 5.0
    gsettings set org.cinnamon.settings-daemon.plugins.color night-light-temperature 2700
    
    # ============================================
    # SETTINGS DAEMON - KEYBOARD
    # ============================================
    gsettings set org.cinnamon.settings-daemon.peripherals.keyboard numlock-state "off"
    
    # ============================================
    # SETTINGS DAEMON - TOUCHSCREEN
    # ============================================
    gsettings set org.cinnamon.settings-daemon.peripherals.touchscreen orientation-lock true
    
    # ============================================
    # WINDOW EFFECTS
    # ============================================
    gsettings set org.cinnamon window-effect-speed 1
    
    print_green "Cinnamon settings applied"
    
    print_yellow "Note: Some settings require additional setup:"
    print_yellow "  - Panel applets must be installed via Cinnamon Settings > Applets"
    print_yellow "  - Extension 'transparent-panels@germanfr' must be installed via Cinnamon Settings > Extensions"
    print_yellow "  - Some applets may need configuration after installation"
}
