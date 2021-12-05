#! /usr/bin/bash

wget https://github.com/ProtoDump/rel/releases/download/gdrive/gdrive
chmod +x gdrive
sudo install gdrive /usr/local/bin/gdrive
rm -rf gdrive
gdrive list

