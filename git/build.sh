#!/usr/bin/env bash

N=$(pwd)

echo "Building latest git ..."

cd ~

sudo apt update -y
sudo apt install -y make libssl-dev libghc-zlib-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip

git clone https://github.com/git/git.git

cd git

make prefix=/usr/local all
sudo make prefix=/usr/local install

cd $N
