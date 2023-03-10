#!/bin/bash

source common.sh


install_starship() {
    temp=starship_temp
    mkdir ${temp}; cd ${temp}
    wget https://starship.rs/install.sh
    mkdir -p ~/.local/bin/
    chmod +x install.sh
    ./install.sh --bin-dir ~/.local/bin/
    cd ../; rm -rf ${temp}
    cp -p starship.toml ~/.config/
    return 0
}

install_tmux() {
    sudo apt install -y tmux
    cp .tmux.conf ~/
    print_green "Installing Tmux addons"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    print_yellow "Open a new terminal, run tmux and execute tmux source ~/.tmux.conf"
    print_yellow "Then do [prefix] + I to install all plugins"
}

install_vim() {
    cp .vimrc ~/
    print_green "Installing Vim addons"
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    mkdir ~/.vim/backups
    mkdir ~/.vim/swaps
    print_yellow "Open a new terminal, run vim, and execute :PluginInstall"
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

install_ulauncher() {
    sudo add-apt-repository ppa:agornostal/ulauncher && sudo apt update && sudo apt install ulauncher
}

install_tabby() {
    curl -s https://packagecloud.io/install/repositories/eugeny/tabby/script.deb.sh | sudo bash
    sudo apt install -y tabby-terminal
    cp -p tabby_config.yaml ~/.config/tabby/config.yaml
}

config_bash() {
    cp .bash_aliases ~/
    cp .bashrc ~/
    source ~/.bashrc
}

install_plank() {
    sudo apt install -y plank
}


###############################################################################
#                                MAIN EXECUTION                               #
###############################################################################
install_ulauncher
install_tabby
install_starship
install_plank
install_vim
install_tmux

config_bash


print_green "Done"
