#!/bin/bash

source common.sh

WDIR="/tmp/felipe_install"
current_path=$(pwd)


configure_remnote() {
    cd $current_path
    print_blue "Configuring RemNote"
    sudo cp ./remnote/remnote.png /usr/share/icons/
    cp -p ./remnote/remnote.desktop ~/.local/share/applications
    print_yellow "On a new terminal move your latest RemNote AppImage to ~/.local/bin/"
    wait_for_user
    print_green "OK"
}

install_starship() {
    cd $WDIR
    print_blue "Installing Starship"
    temp=starship_temp
    mkdir ${temp}; cd ${temp}
    wget https://starship.rs/install.sh
    mkdir -p ~/.local/bin/
    chmod +x install.sh
    ./install.sh --bin-dir ~/.local/bin/
    cd ../; rm -rf ${temp}
    cp -p ./config_files/starship.toml ~/.config/
    return 0
}

install_tmux() {
    cd $current_path
    print_blue "Installing Tmux"
    sudo apt install -y tmux
    cp ./config_files/.tmux.conf ~/
    print_green "Installing Tmux addons"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    print_yellow "Open a new terminal, run tmux and execute tmux source ~/.tmux.conf"
    print_yellow "Then do [prefix] + I to install all plugins"
}

install_vim() {
    cd $current_path
    print_blue "Installing Vim"
    sudo apt install -y vim
    cp ./config_files/.vimrc ~/
    print_green "Installing Vim addons"
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    mkdir ~/.vim/backups
    mkdir ~/.vim/swaps
    print_yellow "Open a new terminal, run vim, and execute :PluginInstall"
    wait_for_user
}

install_ulauncher() {
    print_blue "Installing Ulauncher"
    sudo add-apt-repository ppa:agornostal/ulauncher && sudo apt update && sudo apt install ulauncher
}

install_albert() {
    cd $WDIR
    print_blue "Installing Albert laubcher"
    sudo nala install libqt6widgets6
    wget https://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/amd64/albert_0.22.17-0+597.1_amd64.deb
    sudo dpkg -i albert_0.22.17-0+597.1_amd64.deb
    cd $current_path
    cp config_files/albert_themes/BigSur_Dark.qss.zip $WDIR
    cp config_files/albert_themes/BigSur_White.qss.zip $WDIR
    cd $WDIR
    unzip BigSur_Dark.qss.zip
    unzip BigSur_White.qss.zip
    sudo cp BigSur_Dark.qss /usr/share/albert/widgetsboxmodel/themes/BigSur_Dark.qss
    sudo cp BigSur_White.qss /usr/share/albert/widgetsboxmodel/themes/BigSur_White.qss
}

install_tabby() {
    cd $current_path
    print_blue "Installing Tabby"
    curl -s https://packagecloud.io/install/repositories/eugeny/tabby/script.deb.sh | sudo bash
    sudo apt install -y tabby-terminal
    cp -p ./config_files/tabby_config.yaml ~/.config/tabby/config.yaml
}

configure_bash() {
    cd $current_path
    print_blue "Configuring bash"
    cp ./config_files/.bash_aliases ~/
    cp ./config_files/.bashrc ~/
    source ~/.bashrc
}

install_plank() {
    cd $WDIR
    print_blue "Installing Plank"
    sudo apt install -y plank
    mkdir -p ~/.local/share/plank/themes/
    cp -r ./WhiteSur-gtk-theme/src/other/plank/theme-Dark/ ~/.local/share/plank/themes/
    cp -r ./WhiteSur-gtk-theme/src/other/plank/theme-Light/ ~/.local/share/plank/themes/
    print_yellow "Open a new terminal and run plank --preferences to set the theme"
    print_green "OK"
    echo
    press_enter_to_continue
}

configure_fonts() {
    cd $current_path
    print_blue "Installing Fonts" 
    mkdir -p ~/.local/share/fonts
    cp -r ./fonts/* ~/.local/share/fonts/
    print_green "OK"
    echo
}

install_wallpapers() {
    cd $current_path
    sudo mkdir -p /usr/share/backgrounds/big_sur/
    sudo cp ./wallpapers/BigSurWallpapers4K.zip /usr/share/backgrounds/big_sur/
    cd /usr/share/backgrounds/big_sur/
    sudo unzip BigSurWallpapers4K.zip
    sudo rm BigSurWallpapers4K.zip
    sudo rm -rf __MACOSX
}

configure_cinnamon() {
    sudo apt install libcanberra-gtk-module libglib2.0-dev libxml2-utils shotwell
    print_blue "Configuring Cinnamon"
    mkdir -p $WDIR
    cp -r cinnamon $WDIR/
    cd $WDIR
    print_blue "Installing GTK themes..."
    git clone git@github.com:felipevaldes/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme
    sudo ./install.sh
    cd ../
    print_blue "Installing icon themes..."
    git clone git@github.com:felipevaldes/WhiteSur-icon-theme.git
    cd WhiteSur-icon-theme
    sudo ./install.sh
    cd ../
    print_blue "Installing cursor themes..."
    git clone git@github.com:felipevaldes/McMojave-cursors.git
    cd McMojave-cursors
    sudo ./install.sh
    cd ../

    print_blue "==================================================================="
    echo
    print_yellow "System Settings/Windows..."
    print_yellow "...in Alt-Tab: "
    show_image_and_wait ./cinnamon/config_pictures/windows_alt_tab.png
    echo

    print_blue "==================================================================="
    echo
    print_yellow "System Settings/Hot Corners: Configure as needed"
    echo
    press_enter_to_continue


    print_blue "==================================================================="
    echo
    print_yellow "System Settings/Extensions..."
    print_yellow "...in Download: "
    print_yellow " - download Transparent Panels"
    print_yellow "...in Manage: "
    print_yellow " - Enable Transparent Panels by clicking in the plus sign at the bottom of the window"
    print_yellow " - Click in the gears to configure the panel..."
    show_image_and_wait ./cinnamon/config_pictures/extensions_transparent_panels.png
    echo

    print_blue "==================================================================="
    echo
    print_yellow "System Settings/Themes..."
    print_yellow "...in Themes: Open the Advanced view and configure as needed or use the image as reference "
    show_image_and_wait ./cinnamon/config_pictures/themes_themes.png
    echo

    print_blue "==================================================================="
    echo
    print_yellow "Panel Configuration..."
    print_yellow " - move the panel to the top"
    print_yellow " - set panel to Edit mode"
    print_yellow " - remove Grouped Window List if so desired"
    print_yellow " - remove separator next to menu in the top left"
    print_yellow " - remove main menu in top left"
    print_yellow " - remove corner bar in the right"
    print_yellow " - modify date format"
    print_yellow " - add user applet (download if needed)"
    print_yellow " - add and configure weather applet (download if needed)"
    print_yellow " - add scale applet (download if needed)"
    print_yellow " - add expo applet (download if needed)"
    print_yellow " - add Cinnamenu and configure applet and configure it"
    echo
    press_enter_to_continue
}

configure_xfce() {
    print_blue "Configuring xfce"
    sudo apt install gtk2-engines-murrine
    git clone git@github.com:felipevaldes/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme
    ./install.sh -c Dark -t all
    cd ../
    git clone git@github.com:felipevaldes/WhiteSur-icon-theme.git
    cd WhiteSur-icon-theme
    ./install.sh
    cd ../

    print_blue "==================================================================="

    echo
    print_yellow "Open Appearance..."
    print_yellow "...in Style:"
    show_image_and_wait ./xfce_config/config_pictures/Appearance_Style.png
    print_yellow "...in Icons:"
    show_image_and_wait ./xfce_config/config_pictures/Appearance_Icons.png
    print_yellow "...in Fonts:"
    show_image_and_wait ./xfce_config/config_pictures/Appearance_Fonts.png
    print_yellow "...in Settings:"
    show_image_and_wait ./xfce_config/config_pictures/Appearance_Settings.png
    echo

    print_blue "==================================================================="

    echo
    print_yellow "Open Window Manager..."
    print_yellow "...in Style:"
    show_image_and_wait ./xfce_config/config_pictures/WindowManager_Style.png

    print_yellow "...in Keyboard:"
    show_image_and_wait ./xfce_config/config_pictures/WindowManager_Keyboard.png

    print_yellow "...in Focus:"
    show_image_and_wait ./xfce_config/config_pictures/WindowManager_Focus.png

    print_yellow "...in Advanced:"
    show_image_and_wait ./xfce_config/config_pictures/WindowManager_Advanced.png
    echo

    print_blue "==================================================================="

    echo
    print_yellow "Open Window Manager Tweaks..."
    print_yellow "...in Cycling:"
    show_image_and_wait ./xfce_config/config_pictures/WMTweaks_Cycling.png

    print_yellow "...in Focus:"
    show_image_and_wait ./xfce_config/config_pictures/WMTweaks_Focus.png

    print_yellow "...in Accessibility:"
    show_image_and_wait ./xfce_config/config_pictures/WMTweaks_Accessibility.png

    print_yellow "...in Workspaces:"
    show_image_and_wait ./xfce_config/config_pictures/WMTweaks_Workspaces.png

    print_yellow "...in Placement:"
    show_image_and_wait ./xfce_config/config_pictures/WMTweaks_Placement.png

    print_yellow "...in Compositor:"
    show_image_and_wait ./xfce_config/config_pictures/WMTweaks_Compositor.png
    echo

    print_blue "==================================================================="

    echo
    print_yellow "Open Desktop..."
    print_yellow "...in Menus:"
    show_image_and_wait ./xfce_config/config_pictures/Desktop_Menus.png

    print_yellow "...in Icons:"
    show_image_and_wait ./xfce_config/config_pictures/Desktop_Icons.png
    echo

    print_blue "==================================================================="

    echo
    print_yellow "Open Panel..."
    print_yellow "...in Display:"
    show_image_and_wait ./xfce_config/config_pictures/Panel_Display.png

    print_yellow "...in Appearance:"
    show_image_and_wait ./xfce_config/config_pictures/Panel_Appearance.png

    print_yellow "...in Items:"
    show_image_and_wait ./xfce_config/config_pictures/Panel_Items.png
    echo

    print_blue "==================================================================="

    echo
    print_yellow "Open Keyboard..."
    print_yellow "...in Application Shortcuts:"
    show_image_and_wait ./xfce_config/config_pictures/Keyboard_AS.png
    echo

    print_blue "==================================================================="
}

show_image_and_wait() {
    print_yellow "      use the image as reference and then close to continue."
    start_animation
    shotwell $1
    stop_animation
    echo
}

wait_for_user() {
    print_yellow "Press any key when you are done..."
    start_animation
    while [ true ] ; do
        read -t 3 -n 1
        if [ $? = 0 ] ; then
            break ;
        fi
    done
    stop_animation
}


###############################################################################
#                                   MAIN                                      #
###############################################################################
# if prompt_yes_no "Do you want to configure xfce?"; then
#     configure_xfce
# else
#     echo "Skipping xfce configuration..."
# fi
print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to configure Cinnamon?"; then
    configure_cinnamon
else
    echo "Skipping Cinnamon configuration..."
fi

print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to configure bash?"; then
    configure_bash
else
    echo "Skipping bash configuration..."
fi

print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to install fonts?"; then
    configure_fonts
else
    echo "Skipping font installation..."
fi

# if prompt_yes_no "Do you want to install ulauncher?"; then
#     configure_ulancher
# else
#     echo "Skipping font installation..."
# fi

print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to install Big Sur Wallpapers?"; then
    install_wallpapers
else
    echo "Skipping Big Sur Wallpaper installation..."
fi

print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to install tabby?"; then
    install_tabby
else
    echo "Skipping tabby installation..."
fi

print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to install starship?"; then
    install_starship
else
    echo "Skipping starship installation..."
fi

print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to install plank?"; then
    install_plank
else
    echo "Skipping plank installation..."
fi

print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to install albert launcher?"; then
    install_albert
else
    echo "Skipping albert launcher installation..."
fi

print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to configure vim?"; then
    install_vim
else
    echo "Skipping vim configuration..."
fi

print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to configure tmux?"; then
    install_tmux
else
    echo "Skipping vim configuration..."
fi

print_blue "==================================================================="
echo
if prompt_yes_no "Do you want to configure remnote?"; then
    configure_remnote
else
    echo "Skipping remnote configuration..."
fi

print_green "Done"
