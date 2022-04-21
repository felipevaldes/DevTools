#!/bin/bash
source common.sh


host=$1

print_green "Sending key for snbuilder..."
ssh-copy-id snbuilder@${host}

print_yellow "Open a new terminal, and do ssh snbuilder@${host}:"
print_yellow "  run sudo adduser felipe, and fill out the form"
print_yellow "  then run sudo visudo and add felipe to the gang"
print_yellow "Press any key when you are done..."
while [ true ] ; do
    read -t 3 -n 1
    if [ $? = 0 ] ; then
        break ;
    else
        echo "   waiting for the keypress"
    fi
done

print_green "Sending key for felipe..."
ssh-copy-id felipe@${host}
scp ~/.ssh/id_rsa felipe@${host}:~/.ssh/
scp ~/.ssh/id_rsa.pub felipe@${host}:~/.ssh/

print_green "Setting up..."
cmd="mkdir ~/CODE"
ssh felipe@${host} ${cmd}

cmd="git config --global user.name \"Felipe Valdes Valenzuela\""
ssh felipe@${host} ${cmd}

cmd="git config --global user.email felipe.valdes@sonatus.com"
ssh felipe@${host} ${cmd}

cmd="git config --global core.editor \"vim\""
ssh felipe@${host} ${cmd}

print_yellow "Now ssh felipe@${host} and in git clone git@github.com:felipevaldes/DevTools.git ~/CODE/DevTools"
print_green "All Done."