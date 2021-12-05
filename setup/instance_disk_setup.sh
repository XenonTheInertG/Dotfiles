#!/bin/bash

set -e

OURDIR=
PREPARE=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --aws | --AWS )
                PREPARE=aws
                ;;
        --gcp | --GCP )
                PREPARE=gcp
                ;;
        --azure | --AZURE )
                PREPARE=azure
                ;;
        *)
        die "Invalid parameter!" ;;
    esac
    shift
done

if [ -z "$PREPARE" ]; then
    # Format and setup aws
    echo -e "***** Prepare Persistant AWS Disk path:$OURDIR *****"
    sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "$OURDIR"
    sudo mkdir -p /mnt/build
    sudo mount -o discard,defaults "$OURDIR" /mnt/build
    sudo chmod a+w /mnt/build
    #sudo cp /etc/fstab /etc/fstab.backup
    #echo UUID=`sudo blkid -s UUID -o value /nvme0n1` /mnt/build ext4 discard,defaults,nofail 0 2$
    #cat /etc/fstab
    sudo systemctl enable fstrim.timer
    sudo systemctl start fstrim.timer
fi

if [ -z "$PREPARE" ]; then
    # Format and setup azure
    echo -e "***** Prepare Persistant AZURE Disk path:$OURDIR *****"
    sudo mkfs -t ext4 "$OURDIR"
    mkdir "$HOME"/build
    sudo chmod a+w "$HOME"/build
    sudo mount -o discard,defaults "$OURDIR" /mnt/build
    sudo cp /etc/fstab /etc/fstab.backup
    echo UUID=$(sudo blkid -s UUID -o value "$OURDIR") /mnt/build ext4 discard,defaults,nofail 1 2 | sudo tee -a /etc/fstab
fi

if [ -z "$PREPARE" ]; then
    # Format and setup gcp
    echo -e "***** Prepare Persistant GCP Disk path:$OURDIR *****"
    sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
    sudo mkdir -p "$OURDIR"
    sudo mount -o discard,defaults /dev/sdb "$OURDIR"
    sudo chmod a+w "$OURDIR"
    sudo cp /etc/fstab /etc/fstab.backup
    echo UUID=$(sudo blkid -s UUID -o value /dev/sdb) "$OURDIR" ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
    cat /etc/fstab
fi