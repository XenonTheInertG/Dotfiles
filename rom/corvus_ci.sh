#!/usr/bin/env bash
#
# Copyright (C) 2019-2020 XenonTheInertG
# SPDX-License-Identifier: GPL-3.0-or-later
#
#
 
DEVICE=""
ROM_NAME=""
ROM=""
LINK_MANIFEST=""
BRANCH_MANIFEST=""
USER_SF="xenontheinertg"

CDIR=$PWD
OUT="${CDIR}/out/target/product/${DEVICE}"
JOBS=$(nproc)

# Make It OFFICIAL
export DU_BUILD_TYPE=TESTING
 
# Clone Device Tree, Kernel, and Vendor
# echo "Cloning Device Tree, Kernel and Vendor"
# git clone -b pie https://github.com/KomodOSRom-Devices/device_xiaomi_lavender device/xiaomi/lavender
# git clone --depth=1 -b aosp-eas-inline https://github.com/alanndz/kernel_xiaomi_lavender kernel/xiaomi/lavender
# git clone -b pie https://github.com/KomodOSRom-Devices/vendor_xiaomi_lavender vendor/xiaomi/lavender
 
# Telegram Function
BOT_API_KEY=""
CHAT_ID=
 
function sendInfo() {
    curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d chat_id=$CHAT_ID -d "parse_mode=HTML" -d text="$(
            for POST in "${@}"; do
                echo "${POST}"
            done
        )" &>/dev/null
}
 
function sendLog() {
	curl -F chat_id=$CHAT_ID -F document=@"$BUILDLOG" https://api.telegram.org/bot$BOT_API_KEY/sendDocument &>/dev/null
}

function sendTele() {
    curl -F chat_id=$CHAT_ID -F document=@"$1" https://api.telegram.org/bot$BOT_API_KEY/sendDocument &>/dev/null
}

#####

function repoInit() {
    repo init -u ${LINK_MANIFEST} -b ${BRANCH_MANIFEST}
}

function repoSync() {
    repo sync -c --force-sync --no-tags --no-clone-bundle
}

function statusBuild() {
    if [ "$1" == "rom" ]; then
        cd $OUT
        FILEPATH=$(find -iname "${ROM_NAME}*${DEVICE}*.zip")
        if [[ ! -f $FILEPATH ]]; then
            sendInfo "Build ROM ${ROM_NAME} FAILED, See log. Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
            echo "Build Failed"
            return
        fi
        sendInfo "Build ROM ${ROM_NAME} Success. Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
        cd $CDIR
    elif [ "$1" == "kernel" ]; then
        if [[ ! -f "{OUT}/boot.img" ]]; then
            sendInfo "Build <b>boot.img</b> Only Failed, See log. Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
            echo "Build Failed"
            return
        fi
        sendTele "$FILEPATH"
        sendInfo "Build boot.img Only Success. Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
    elif [ "$1" == "apps" ]; then
        cd $OUT
        FILEPATH=$(find -iname "$2.apk")
        if [[ ! -f $FILEPATH ]]; then
            sendInfo "Build Apps $2 Failed, See log. Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
            echo "Build Failed"
            return
        fi
        sendTele "$FILEPATH"
        if [ "$2" == "Settings" ]; then sendTele $(find -iname "Corvus.apk"); fi
        sendInfo "Build Apps $2 Success!!!. Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
    fi
    echo "Build Success!!!"
}

function sendSFtest() {
    cd $OUT
    FILEPATH=$(find -iname "${ROM_NAME}*${DEVICE}*.zip")
    if [[ ! -f $FILEPATH ]]; then
        echo "File Not Found!!!!"
        return
    fi
    sshpass $(openssl enc -base64 -d <<< YWRtaW4xMjNic2QgCg==) scp $FILEPATH ${USER_SF}@frs.sourceforge.net:/home/frs/project/goodmeow/test/
    echo "Send ROM to SourceForge(test) Success."
    cd $CDIR
}

function sendSFrelease() {
    cd $OUT
    FILEPATH=$(find -iname "${ROM_NAME}*${DEVICE}*.zip")
    if [[ ! -f $FILEPATH ]]; then
        echo "File Not Found!!!!"
        return
    fi
    sshpass '$(openssl enc -base64 -d <<< YWRtaW4xMjNic2QgCg==)' scp $FILEPATH ${USER_SF}@frs.sourceforge.net:/home/frs/project/goodmeow/release/
    echo "Send ROM to SourceForge(release) Success."
    cd $CDIR
}

function timeStart() {
    DATELOG=$(date "+%H%M-%d%m%Y")
    BUILDLOG="$CDIR/out/${ROM_NAME}-${DEVICE}-$DATELOG.log"
    BUILD_START=$(date +"%s")
    DATE=`date`
}

function cache() {
    export USE_CCACHE=1
    export CCACHE_EXEC=$(command -v ccache)
    ccache -M 100G
}

function cleann() {
    clear
    echo "Cleaning ...."
    make clean
    make clobber
}

function buildRom() {
    sendInfo "<b>Starting Build ROM</b>" \
        "<b>ROM Name:</b> <code>${ROM_NAME}</code>" \
        "<b>Branch:</b> <code>${BRANCH_MANIFEST}</code>" \
        "<b>Device:</b> <code>${DEVICE}</code>" \
        "<b>Started at</b> <code>$DATE</code>"
    . build/envsetup.sh
    lunch "${ROM}"_"${DEVICE}"-userdebug
    mka bacon -j"${JOBS}"
}

function buildKernel() {
    sendInfo "<b>Starting Build Kernel</b>" \
        "<b>ROM Name:</b> <code>${ROM_NAME}</code>" \
        "<b>Branch:</b> <code>${BRANCH_MANIFEST}</code>" \
        "<b>Device:</b> <code>${DEVICE}</code>" \
        "<b>Started at</b> <code>$DATE</code>"
    . build/envsetup.sh
    lunch "${ROM}"_"${DEVICE}"-userdebug
    mka bootimage
}

function buildApps() {
    sendInfo "<b>Starting Build Apps</b>" \
        "<b>Apps Name:</b> <code>$1</code>" \
        "<b>ROM Name:</b> <code>${ROM_NAME}</code>" \
        "<b>Branch:</b> <code>${BRANCH_MANIFEST}</code>" \
        "<b>Device:</b> <code>${DEVICE}</code>" \
        "<b>Started at</b> <code>$DATE</code>"
    . build/envsetup.sh
    lunch "${ROM}"_"${DEVICE}"-userdebug
    make $1
}

function timeEnd() {
    BUILD_END=$(date +"%s")
    DIFF=$(($BUILD_END - $BUILD_START))
}

clear
while true; do
    echo -e "\n- - - - Build ROM and other stuff - - - -"
    echo -e "            script by alanndz"
    echo -e "on $(uname -a) "
    echo -e "ROM        = ${ROM_NAME}"
    echo -e "ROM DIR      ${ROM}"
    echo -e "DEVICE     = ${DEVICE}"
    echo -e "Status dt  ="
    echo -e "Device Tree= $(if [ -d device/xiaomi/${DEVICE} ]; then echo "Already"; else echo "Not Found"; fi)"
    echo -e "Common tree= $(if [ -d device/xiaomi/sdm845-common ]; then echo "Already"; else echo "Not Found"; fi)"
    echo -e "Kernel     = $(if [ -d kernel/xiaomi/${DEVICE} ]; then echo "Already"; else echo "Not Found"; fi)"
    echo -e "Vendor     = $(if [ -d vendor/xiaomi/${DEVICE} ]; then echo "Already"; else echo "Not Found"; fi)"
    echo -e "- - - - - - - - - - - - - - - - - - - - - - "
    echo -e "[0] Check check"
    echo -e "[1] Build ROM with ccache"
    echo -e "[2] Build ROM without ccache"
    echo -e "[3] Build Kernel Only"
    echo -e "[4] Build Apps Only"
    echo -e "[5] Clean"
    echo -e "[6] Initial Source code"
    echo -e "[7] Re sync source code"
    echo -e "[8] Send ROM To SouceForge [TESTING]"
    echo -e "[9] Send ROM To SourceForge [RELEASE]"
#    echo -e "[10] Send ROM To Mega.nz" 
    echo -e "[11] Exit"
    echo -ne "\n(i) Please enter a choice[0-11]: "

    read choice
    if [ $choice -eq 0 ]; then
        clear
        . build/envsetup.sh
        lunch "${ROM}"_"${DEVICE}"-userdebug
        read -p "[?] press any key to back menu ..."
        clear
    elif [ $choice -eq 1 ]; then
        clear
        timeStart
        cache
        buildRom 2>&1 | tee "${BUILDLOG}"
        timeEnd "rom"
        statusBuild "rom"
        sendLog
        cd $CDIR
        read -p "[?] press any key to back menu ..."
        clear
    elif [ $choice -eq 2 ]; then
        clear
        timeStart
        buildRom 2>&1 | tee "${BUILDLOG}"
        timeEnd "rom"
        statusBuild "rom"
        sendLog
        cd $CDIR
        read -p "[?] press any key to back menu ..."
        clear
    elif [ $choice -eq 3 ]; then
        clear
        timeStart
        cache
        buildKernel 2>&1 | tee "${BUILDLOG}"
        echo "send Not Available"
        timeEnd "kernel"
        statusBuild "kernel"
        sendLog
        cd $CDIR
        read -p "[?] press any key to back menu ..."
        clear
    elif [ $choice -eq 4 ]; then
        read -p "Insert Packname Apps: " APPS
        clear
        timeStart
        cache
        buildApps $APPS 2>&1 | tee "${BUILDLOG}"
        timeEnd "apps" $APPS
        statusBuild "apps" $APPS
        sendLog
        cd $CDIR
        read -p "[?] press any key to back menu ..."
        clear
    elif [ $choice -eq 5 ]; then
        cleann
        read -p "[?] press any key to back menu ..."
        clear
    elif [ $choice -eq 6 ]; then
        clear
        repoInit
        read -p "[?] press any key to back menu ..."
        clear
    elif [ $choice -eq 7 ]; then
        clear
        repoSync
        read -p "[?] press any key to back menu ..."
        clear
    elif [ $choice -eq 8 ]; then
        clear
        sendSFtest "testing"
        read -p "[?] press any key to back menu ..."
        clear
    elif [ $choice -eq 9 ]; then
        clear
        sendSFrelease "release"
        read -p "[?] press any key to back menu ..."
        clear
#    elif [ $choice -eq 10 ]; then
#        clear
#        cd $OUT
#        FILEPATH=$(find -iname "${ROM_NAME}-*-${DEVICE}-*-*.zip")
#        USER_MEGA=$(openssl enc -base64 -d <<< enhjMDcwQGhpMi5pbgo=)
#        PASS_MEGA=$(openssl enc -base64 -d <<< VURCYWVFWTBlbkYwUjI0elVnbz0K)
#        megaput -u $USER_MEGA -p $(openssl enc -base64 -d <<< $PASS_MEGA) $FILEPATH
#        cd $CDIR
#        read -p "[?] press any key to back menu ..."
#        clear
    elif [ $choice -eq 11 ]; then
        exit
    else
        echo ""
    fi
done
echo -e "$nc"
      echo ""
    fi
done
echo -e "$nc"
 ""
    fi
done
echo -e "$nc"

