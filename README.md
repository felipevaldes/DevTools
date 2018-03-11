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

3. Install latest tmux (2.6) from source:
    ```
    export VERSION=2.6
    sudo apt-get -y remove tmux
    sudo apt-get -y install wget tar libevent-dev libncurses-dev
    wget https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz
    tar xf tmux-${VERSION}.tar.gz
    rm -f tmux-${VERSION}.tar.gz
    cd tmux-${VERSION}
    ./configure
    make
    sudo make install
    cd -
    sudo rm -rf /usr/local/src/tmux-*
    sudo mv tmux-${VERSION} /usr/local/src
    ```
4. Install Tmux Plugin Manager (TPM): (https://github.com/tmux-plugins/tpm):
    ```
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ```
    - run tmux and execute tmux source ~/.tmux.conf
    - [prefix] + I to install all plugins
