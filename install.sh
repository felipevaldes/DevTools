#!/bin/bash

echo "Copying config files to ~/:"
cp .vimrc ~/
cp .tmux.config ~/
cp .bash_alias ~/
cp .bashrc ~/
source ~/.bashrc

echo "Installing Vim addons"
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
mkdir ~/.vim/backups
mkdir ~/.vim/swaps

echo "Open a new terminal, run vim, and execute :PluginInstall"
echo "Press any key when you are done..."
while [ true ] ; do
    read -t 3 -n 1
    if [ $? = 0 ] ; then
        break ;
    else
        echo "   waiting for the keypress"
    fi
done

echo "Installing Tmux addons"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "Open a new terminal, run tmux and execute tmux source ~/.tmux.conf"
echo "Then do [prefix] + I to install all plugins"

