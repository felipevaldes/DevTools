#!/bin/bash

source common.sh


configure_remnote() {
    print_blue "Configuring RemNote"
    cp -p ./remnote/remnote.png ~/.local/share/icons/
    cp -p ./remnote/RemNote.desktop ~/.local/share/applications
    print_yellow "On a new terminal move your latest RemNote AppImage to ~/.local/bin/"
    wait_for_user
    print_green "OK"
}

install_starship() {
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
    sudo apt install -y tmux
    cp ./config_files/.tmux.conf ~/
    print_green "Installing Tmux addons"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    print_yellow "Open a new terminal, run tmux and execute tmux source ~/.tmux.conf"
    print_yellow "Then do [prefix] + I to install all plugins"
}

install_vim() {
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
    sudo add-apt-repository ppa:agornostal/ulauncher && sudo apt update && sudo apt install ulauncher
}

install_tabby() {
    curl -s https://packagecloud.io/install/repositories/eugeny/tabby/script.deb.sh | sudo bash
    sudo apt install -y tabby-terminal
    cp -p ./config_files/tabby_config.yaml ~/.config/tabby/config.yaml
}

configure_bash() {
    cp ./config_files/.bash_aliases ~/
    cp ./config_files/.bashrc ~/
    source ~/.bashrc
}

install_plank() {
    print_blue "Installing Plank"
    sudo apt install -y plank
    cp -r ./WhiteSur-gtk-theme/src/other/plank/theme-Dark/ ~/.local/share/plank/themes/
    cp -r ./WhiteSur-gtk-theme/src/other/plank/theme-Light/ ~/.local/share/plank/themes/
    print_yellow "Open a new terminal and run plank --preferences to set the theme"
    print_green "OK"
    echo
}

configure_fonts() {
    print_blue "Installing Fonts"
    mkdir -p ~/.local/share/fonts
    cp -r ./xfce_config/fonts/* ~/.local/share/fonts/
    print_green "OK"
    echo
}

configure_xfce() {
    sudo apt install gtk2-engines-murrine
    git clone git@github.com:felipevaldes/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme
    ./install.sh -c Dark -t all
    cd ../
    git clone git@github.com:felipevaldes/WhiteSur-icon-theme.git
    cd WhiteSur-icon-theme
    ./install
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
configure_bash
configure_fonts
configure_xfce

install_ulauncher
install_tabby
install_starship
install_plank
install_vim
install_tmux

print_green "Done"
