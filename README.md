# DevTools
Development tools and configurations

0. Copy config files to ~/:
    ```
    cp .vimrc ~/
    cp .tmux.config ~/
    cp .bash_alias ~/
    ```    
1. Install Vundle, the plug-in manager for Vim (http://github.com/VundleVim/Vundle.Vim:
    - make sure curl is installed
    - clone VundleVim repo:
    ```
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    ```
    - run vim and execute :PluginInstall
    
2. Create directories for swap files and backup:
    ```
    mkdir ~/.vim/backups
    mkdir ~/.vim/swaps
    ```

3. YouCompleteMe Plugin for Vim requires a compiled component to work:
    ```
    cd ~/.vim/bundle/YouCompleteMe
    ./install.py --all
    ```
    - For more info check https://github.com/Valloric/YouCompleteMe

4. Install latest tmux
5. Install Tmux Plugin Manager (TPM): (https://github.com/tmux-plugins/tpm):
    ```
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ```
    - run tmux and execute tmux source ~/.tmux.conf
    - [prefix] + I to install all plugins

6. Modifiy `.bashrc` to show git branch in the prompt: replace the existing `PS1` line with
```
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[0;91m\]($(git branch 2>/dev/null | grep '^*' | colrm 1 2))\[\033[01;34m\]\$\[\033[00m\] '
```
