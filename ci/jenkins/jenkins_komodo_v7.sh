#!/bin/bash

# Copyright (C) 2019-2020 XenonTheInertG
# Copyright (C) 2020 @KryPtoN
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
path_ccache="/$HOME/komodo/.ccache"

CDIR=$PWD
OUT="${CDIR}/out/target/product/$device_codename"
ROM_NAME="KomodoOS"
DEVICE="$device_codename"
BRANCH_MANIFEST="dev/ten"
KOMODOFILE="/home/jenkins/file"

# Telegram Function
BOT_API_KEY=""
CHAT_ID=
CHAT_ID_SECOND=

CODE_EXIT=0
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
    repo init -u https://github.com/Komodo-OS-Rom/manifest -b $BRANCH_MANIFEST
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
fi

# Build Variant

if [ "$upload_to_sf" = "release" ]; then
    export KOMODO_VARIANT=RELEASE
fi

if [ "$upload_to_sf" = "test" ]; then
    export KOMODO_VARIANT=BETA
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

telegram_curl() {
	local ACTION=${1}
	shift
	local HTTP_REQUEST=${1}
	shift
	if [ "$HTTP_REQUEST" != "POST_FILE" ]; then
		curl -s -X $HTTP_REQUEST "https://api.telegram.org/bot$BOT_API_KEY/$ACTION" "$@" | jq .
	else
		curl -s "https://api.telegram.org/bot$BOT_API_KEY/$ACTION" "$@" | jq .
	fi
}

telegram_main() {
	local ACTION=${1}
	local HTTP_REQUEST=${2}
	local CURL_ARGUMENTS=()
	while [ "${#}" -gt 0 ]; do
		case "${1}" in
			--animation | --audio | --document | --photo | --video )
				local CURL_ARGUMENTS+=(-F $(echo "${1}" | sed 's/--//')=@"${2}")
				shift
				;;
			--* )
				if [ "$HTTP_REQUEST" != "POST_FILE" ]; then
					local CURL_ARGUMENTS+=(-d $(echo "${1}" | sed 's/--//')="${2}")
				else
					local CURL_ARGUMENTS+=(-F $(echo "${1}" | sed 's/--//')="${2}")
				fi
				shift
				;;
		esac
		shift
	done
	telegram_curl "$ACTION" "$HTTP_REQUEST" "${CURL_ARGUMENTS[@]}"
}

telegram_curl_get() {
	local ACTION=${1}
	shift
	telegram_main "$ACTION" GET "$@"
}

telegram_curl_post() {
	local ACTION=${1}
	shift
	telegram_main "$ACTION" POST "$@"
}

telegram_curl_post_file() {
	local ACTION=${1}
	shift
	telegram_main "$ACTION" POST_FILE "$@"
}

tg_send_message() {
	telegram_main sendMessage POST "$@"
}

tg_edit_message_text() {
	telegram_main editMessageText POST "$@"
}

tg_send_document() {
	telegram_main sendDocument POST_FILE "$@"
}

#####

# Progress
progress(){
 
    echo "BOTLOG: Build tracker process is running..."
    sleep 10;
 
    while [ 1 ]; do 
        if [ ${CODE_EXIT} -ne 0 ]; then
            exit ${CODE_EXIT}
        fi
 
        # Get latest percentage
        PERCENTAGE=$(cat $BUILDLOG | tail -n 1 | awk '{ print $2 }')
        NUMBER=$(echo ${PERCENTAGE} | sed 's/[^0-9]*//g')
 
        # Report percentage to the $CHAT_ID
        if [ "${NUMBER}" != "" ]; then
            if [ "${NUMBER}" -le  "99" ]; then
                if [ "${NUMBER}" != "${NUMBER_OLD}" ] && [ "$NUMBER" != "" ] && ! cat $BUILDLOG | tail  -n 1 | grep "glob" > /dev/null && ! cat $BUILDLOG | tail  -n 1 | grep "including" > /dev/null && ! cat $BUILDLOG | tail  -n 1 | grep "soong" > /dev/null && ! cat $BUILDLOG | tail  -n 1 | grep "finishing" > /dev/null; then
                echo -e "BOTLOG: Percentage changed to ${NUMBER}%"
                build_message "🛠️ Building... ${NUMBER}%" > /dev/null
                fi
            NUMBER_OLD=${NUMBER}
            fi
            if [ "$NUMBER" -eq "99" ] && [ "$NUMBER" != "" ] && ! cat $BUILDLOG | tail  -n 1 | grep "glob" > /dev/null && ! cat $BUILDLOG | tail  -n 1 | grep "including" > /dev/null && ! cat $BUILDLOG | tail  -n 1 | grep "soong" > /dev/null && ! cat $BUILDLOG | tail -n 1 | grep "finishing" > /dev/null; then
                echo "BOTLOG: Build tracker process ended"
                break
            fi
        fi
 
        sleep 10
    done
    return 0
}

#######

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
build_message() {
	if [ "$CI_MESSAGE_ID" = "" ]; then
		CI_MESSAGE_ID=$(tg_send_message --chat_id "$CHAT_ID" --text "<b>====== Starting Build ROM ======</b>
<b>ROM Name:</b> <code>${ROM_NAME}</code>
<b>Branch:</b> <code>${BRANCH_MANIFEST}</code>
<b>Device:</b> <code>${DEVICE}</code>
<b>Command:</b> <code>$target_command</code>
<b>Upload to SF:</b> <code>$upload_to_sf</code>
<b>Started at</b> <code>$DATE</code>
Status: $1" --parse_mode "html" | jq .result.message_id)
	else
		tg_edit_message_text --chat_id "$CHAT_ID" --message_id "$CI_MESSAGE_ID" --text "<b>====== Starting Build ROM ======</b>
<b>ROM Name:</b> <code>${ROM_NAME}</code>
<b>Branch:</b> <code>${BRANCH_MANIFEST}</code>
<b>Device:</b> <code>${DEVICE}</code>
<b>Command:</b> <code>$target_command</code>
<b>Upload to SF:</b> <code>$upload_to_sf</code>
<b>Started at</b> <code>$DATE</code>
Status: $1" --parse_mode "html"
	fi
}

function statusBuild() {
    if [[ $retVal -ne 0 ]]; then
        tg_send_message --chat_id "$CHAT_ID" --text "Build FAILED 💔 with Code Exit ${CODE_EXIT}, See log. Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
        tg_send_message --chat_id "$CHAT_ID_SECOND" --text "Build Failed 💔 with CODE_EXIT ${CODE_EXIT}. @smn"
        echo "Build Failed"
        tg_send_document --chat_id "$CHAT_ID" --document "$BUILDLOG" --reply_to_message_id "$CI_MESSAGE_ID"
        LOGTRIM="$CDIR/out/log_trimmed.log"
        sed -n '/FAILED:/,//p' $BUILDLOG &> $LOGTRIM
        tg_send_document --chat_id "$CHAT_ID" --document "$LOGTRIM" --reply_to_message_id "$CI_MESSAGE_ID"
        exit $retVal
    fi
    OTA=$(find $OUT -name "$ROM_NAME-*json")
    tg_send_document --chat_id "$CHAT_ID" --document "$OTA" --reply_to_message_id "$CI_MESSAGE_ID"
    tg_send_message --chat_id "$CHAT_ID" --text "Build Success ❤️. Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
    tg_send_message --chat_id "$CHAT_ID_SECOND" --text "Build Success ❤️. @smn"
}

timeStart
BUILDLOG="$CDIR/out/${ROM_NAME}-${DEVICE}-${DATELOG}.log"
# time to build bro
build_message "Staring broo...🔥"
source build/envsetup.sh
build_message "lunch komodo_"$device_codename"-"$build_type""
lunch komodo_"$device_codename"-"$build_type"
mkfifo reading
tee "${BUILDLOG}" < reading &
build_message "mka "$target_command" -j"$jobs""
progress &
mka "$target_command" -j"$jobs" > reading
CODE_EXIT=$?
build_message "🛠️ Building..."

# Record exit code after build
retVal=$?
timeEnd
statusBuild
tg_send_document --chat_id "$CHAT_ID" --document "$BUILDLOG" --reply_to_message_id "$CI_MESSAGE_ID"

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

if [ "$upload_to_sf" = "release" ]; then
    build_message "Uploading to sourceforge release 📤"
    mv "$FILEPATH" $KOMODOFILE/komodo-release/$DEVICE/
    sshpass -p '' sftp -oBatchMode=no komodos@frs.sourceforge.net:/home/frs/project/komodos-rom > /dev/null 2>&1 <<EOF
cd $DEVICE
put $FILEPATH
exit
EOF
    build_message "Uploaded on : https://sourceforge.net/projects/komodos-rom/files/$DEVICE/$FILENAME.zip/download"
fi

if [ "$upload_to_sf" = "test" ]; then
    build_message "Uploading to sourceforge test 📤"
    mv "$FILEPATH" $KOMODOFILE/komodo-beta/$DEVICE/
    sshpass -p '' sftp -oBatchMode=no kry9ton@frs.sourceforge.net:/home/frs/project/krypton-project > /dev/null 2>&1 <<EOF
cd Test
put $FILEPATH
exit
EOF
    build_message "Uploaded on : https://sourceforge.net/projects/krypton-project/files/Test/$FILENAME.zip/download"
fi

exit 0

