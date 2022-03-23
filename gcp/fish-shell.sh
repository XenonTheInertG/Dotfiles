#!/usr/bin/env bash
# Thanks to krypton

sudo apt update
sudo apt install git zsh jq expect sshpass rsync tmux curl wget -y

dir="/disk"

while true; do
    read -p "You want to Persistant disk ? : " yn
    case $yn in
        [Yy]* )
            # Format and setup
            echo "***** Prepare Persistant Disk path:/disk *****  ";
            sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb;
            sudo mkdir -p $dir;
            sudo mount -o discard,defaults /dev/sdb $dir;
            sudo chmod a+w $dir;
            sudo cp /etc/fstab /etc/fstab.backup;
            echo UUID=`sudo blkid -s UUID -o value /dev/sdb` $dir ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab;
            cat /etc/fstab; break;;
        [Nn]* ) break;;
        * ) echo "Please answer y or n.";;
    esac
done

echo "***** Clone AkhilNarang ENV script *****"
git clone https://github.com/akhilnarang/scripts
echo "***** Entering path:/home/"$(whoami)"/scripts/"
cd scripts || exit 1
sudo bash setup/android_build_env.sh
cd ~/

echo "***** Set Up my favorite theme *****"
wget -O ~/.tmux.conf https://github.com/xenontheinertg/dotfiles/raw/master/tmux/tmux.conf

echo "***** Setup git *******"
curl -L https://github.com/xenontheinertg/dotfiles/raw/master/git/build.sh | bash
curl -L https://github.com/xenontheinertg/dotfiles/raw/master/git/gitalias.sh | bash

echo "***** Install fish shell and etc ******"
sudo apt install -y fish tmux jq expect curl ccache wget
wget -O- --no-check-certificate https://get.oh-my.fish | fish

echo "***** Install barom *******"
curl -L https://git.io/JkItH | bash

