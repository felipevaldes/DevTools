# DevTools
Development tools and configurations

0. Copy config files to ~/:
    ```
    cp .vimrc ~/
    cp .tmux.config ~/
    ```    
1. Install Vundle, the plug-in manager for Vim (http://github.com/VundleVim/Vundle.Vim:
    - make sure curl is installed
    - clone VundleVim repo:
    ```
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    ```
    - run vim and execute :PluginInstall

2. YouCompleteMe Plugin for Vim requires a compiled component to work:
    ```
    cd ~/.vim/bundle/YouCompleteMe
    ./install.py --all
    ```
    - For more info check https://github.com/Valloric/YouCompleteMe

3. Install latest tmux
4. Install Tmux Plugin Manager (TPM): (https://github.com/tmux-plugins/tpm):
    ```
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ```
    - run tmux and execute tmux source ~/.tmux.conf
    - [prefix] + I to install all plugins
