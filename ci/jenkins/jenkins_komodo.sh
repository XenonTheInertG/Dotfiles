#!/bin/bash

# Copyright (C) 2019-2020 XenonTheInertG
# SPDX-License-Identifier: GPL-3.0-or-later

# use_ccache=
# YES - use ccache
# NO - don't use ccache
# CLEAN - clean your ccache (Do this if you getting Toolchain errors related to ccache and it will take some time to clean all ccache files)

# make_clean=
# YES - make clean (this will delete "out" dir from your ROM repo)
# NO - make dirty
# INSTALLCLEAN - make installclean (this will delete all images generated in out dir. useful for rengeneration of images)

# lunch_command
# LineageOS uses "lunch lineage_devicename-userdebug"
# AOSP uses "lunch aosp_devicename-userdebug"
# So enter what your uses in Default Value
# Example - du, xosp, pa, etc

# device_codename
# Enter the device codename that you want to build without qoutes
# Example - "hydrogen" for Mi Max
# "armani" for Redmi 1S

# build_type
# userdebug - Like user but with root access and debug capability; preferred for debugging
# user - Limited access; suited for production
# eng - Development configuration with additional debugging tools

# target_command
# bacon - for compiling rom
# bootimage - for compiling only kernel in ROM Repo
# Settings, SystemUI for compiling particular APK

# Default setting, uncomment if u havent jenkins
# use_ccache=yes # yes | no | clean
# make_clean=yes # yes | no | installclean
# lunch_command=komodo
# device_codename=lavender
# build_type=userdebug
# target_command=bacon
# jobs=8
# upload_to_sf=yes
path_ccache="/mnt/build/jenkins/.ccache"

CDIR=$PWD
OUT="${CDIR}/out/target/product/$device_codename"
ROM_NAME="KomodoOS"
DEVICE="$device_codename"
BRANCH_MANIFEST="ten"
OTA="${OUT}/KomodoOS*.json"
# my Time
export TZ=":Asia/Jakarta"
# Colors makes things beautiful
export TERM=xterm

    red=$(tput setaf 1)             #  red
    grn=$(tput setaf 2)             #  green
    blu=$(tput setaf 4)             #  blue
    cya=$(tput setaf 6)             #  cyan
    txtrst=$(tput sgr0)             #  Reset

if [ "$re_sync" = "yes" ]; then
    repo init -u https://github.com/Komodo-OS-Rom/manifest -b ten
    repo sync -c --force-sync --no-clone-bundle --no-tags
fi 

# CCACHE UMMM!!! Cooks my builds fast

if [ "$use_ccache" = "yes" ]; then
	echo -e ${blu}"CCACHE is enabled for this build"${txtrst}
	export CCACHE_EXEC=$(which ccache)
	export USE_CCACHE=1
	export CCACHE_DIR=$path_ccache
	ccache -M 50G
fi

if [ "$use_ccache" = "clean" ]; then
	export CCACHE_EXEC=$(which ccache)
	export CCACHE_DIR=$path_ccache
	ccache -C
	export USE_CCACHE=1
	ccache -M 50G
	wait
	echo -e ${grn}"CCACHE Cleared"${txtrst};
fi

# Its Clean Time
if [ "$make_clean" = "yes" ]; then
	make clean # && make clobber
	wait
	echo -e ${cya}"OUT dir from your repo deleted"${txtrst};
fi

# Its Images Clean Time
if [ "$make_clean" = "installclean" ]; then
	make installclean
	wait
	echo -e ${cya}"Images deleted from OUT dir"${txtrst};
fi

# Telegram Function
BOT_API_KEY=
CHAT_ID=

function sendInfo() {
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d chat_id=$CHAT_ID -d "parse_mode=HTML" -d text="$(
		for POST in "${@}"; do
			echo "${POST}"
		done
	)" &> /dev/null
}

function sendLog() {
	curl -F chat_id=$CHAT_ID -F document=@"$1" https://api.telegram.org/bot$BOT_API_KEY/sendDocument &>/dev/null
}

function sendTele() {
	curl -F chat_id=$CHAT_ID -F document=@"$1" https://api.telegram.org/bot$BOT_API_KEY/sendDocument &>/dev/null
}

function sendJson() {
	curl -F chat_id=$CHAT_ID -F document=@"$OTA" https://api.telegram.org/bot$BOT_API_KEY/sendDocument &>/dev/null
}

#####

function timeStart() {
	DATELOG=$(date "+%H%M-%d%m%Y")
	BUILD_START=$(date +"%s")
	DATE=`date`
}

function timeEnd() {
	BUILD_END=$(date +"%s")
	DIFF=$(($BUILD_END - $BUILD_START))
}

# Build ROM
function startTele() {
	sendInfo \
	    "<b>====== Starting Build ROM ======</b>" \
		"<b>ROM Name :</b> <code>${ROM_NAME}</code>" \
		"<b>Branch   :</b> <code>${BRANCH_MANIFEST}</code>" \
		"<b>Device   :</b> <code>${DEVICE}</code>" \
		"<b>Command  :</b> <code>$target_command</code>" \
		"<b>Upload to SF:</b> <code>$upload_to_sf</code>" \
		"<b>Started at</b> <code>$(uname -a)</code>" \
		"<b>====== Starting Build ROM ======</b>"
}

function statusBuild() {
    if [[ $retVal -ne 0 ]]; then
        sendInfo "Build FAILED, See log. Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
        echo "Build Failed"
        sendLog "$BUILDLOG"
        LOGTRIM="$CDIR/out/log_trimmed.log"
        sed -n '/FAILED:/,//p' $BUILDLOG &> $LOGTRIM
        sendLog "$LOGTRIM"
        exit $retVal
    fi
    sendJson
    sendInfo "<b>====== Build ROM Completed ======</b>" \
             "Build Success. Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds." \
             "Filename: $FILENAME " \
             "<b>====== Build ROM Completed ======</b>"
}

timeStart
BUILDLOG="$CDIR/out/${ROM_NAME}-${DEVICE}-${DATELOG}.log"
# time to build bro
source build/envsetup.sh
lunch "$lunch_command"_"$device_codename"-"$build_type"
startTele
mkfifo reading
tee "${BUILDLOG}" < reading &
mka "$target_command" -j"$jobs" > reading

# Record exit code after build
retVal=$?
timeEnd
statusBuild
sendLog "$BUILDLOG"

# Detecting file
FILENAME=$(cat $CDIR/out/var-file_name)
if [ "$target_command" = "bacon" ]; then
    #FILEPATH=$(find "$OUT" -iname "${ROM_NAME}*${DEVICE}*zip")
    FILEPATH="$OUT/$FILENAME.zip"
elif [ "$target_command" = "bootimage" ]; then
    FILEPATH=$(find "$OUT" -iname "boot.img" 2>/dev/null)
else
    FILEPATH=$(find "$OUT" -iname "$target_command.apk" 2>/dev/null)
    sendTele "$FILEPATH"
    exit 0
fi

if [ "$upload_to_sf" = "yes" ]; then
    sshpass -p 'komododebes' scp "$FILEPATH" komodos@frs.sourceforge.net:/home/frs/project/komodos-rom/$DEVICE/
fi

if [ "$upload_to_sf" = "krypton-test" ]; then
    sshpass -p '468213790d' scp "$FILEPATH" kry9ton@frs.sourceforge.net:/home/frs/project/krypton-project/Test/
fi

if [ "$upload_to_sf" = "goodmeow-test" ]; then
    sshpass -p 'admin123bsd' scp "$FILEPATH" goodmeow@frs.sourceforge.net:/home/frs/project/goodmeow/test/komodo/
fi
exit 0
