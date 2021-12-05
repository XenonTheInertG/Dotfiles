#!/usr/bin/env bash
#####################################
echo "***** ZSH INSTALL ANTIGEN *****"

sudo apt-get update
sudo apt-get install zsh -y

#powerline/fonts
sudo apt-get install powerline fonts-powerline -y

wget https://raw.githubusercontent.com/zsh-users/antigen/master/bin/antigen.zsh -P $HOME/
wget https://github.com/goodmeow/myscript/raw/master/dotfiles/.zshrc -P $HOME/
#sudo chsh -s /bin/zsh
zsh
source .zshrc