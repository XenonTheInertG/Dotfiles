#!/usr/bin/env bash

REMOTE="git@github.com:NusantaraROM-Devices"

[[ ! -z "$1" ]] && BRANCH="-b $1"

echo "Cloning device tree and vendor tree ..."

git clone "$REMOTE/device_xiaomi_lavender.git" device/xiaomi/lavender "${BRANCH:-}"
git clone "$REMOTE/vendor_xiaomi_lavender.git" vendor/xiaomi/lavender "${BRANCH:-}"

echo "cloning my harware lavender"
rm -rf hardware/xiaomi
git clone git@github.com:HANA-CI-Build-Project/hardware_xiaomi_lavender.git hardware/xiaomi/lavender
