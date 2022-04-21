#!/bin/bash

source common.sh

print_green "Copying config files to ~/:"
cp .vimrc ~/
cp .tmux.conf ~/
cp .bash_aliases ~/
cp .bashrc ~/
source ~/.bashrc

print_green "Installing Vim addons"
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
mkdir ~/.vim/backups
mkdir ~/.vim/swaps
print_yellow "Open a new terminal, run vim, and execute :PluginInstall"
print_yellow "Press any key when you are done..."
while [ true ] ; do
    read -t 3 -n 1
    if [ $? = 0 ] ; then
        break ;
    else
        echo "   waiting for the keypress"
    fi
done


print_green "Installing Tmux addons"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

print_yellow "Open a new terminal, run tmux and execute tmux source ~/.tmux.conf"
print_yellow "Then do [prefix] + I to install all plugins"


print_green "Cloning snt-integration-tests..."
git clone git@github.com:sonatus/snt-integration-tests.git

print_green "Done"
