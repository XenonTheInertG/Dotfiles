#!/usr/bin/env bash
#
# Copyright (C)  @xenontheinertg 
# SPDX-License-Identifier: GPL-3.0-or-later
#
# New Automatic Build for global
#
#
# Default Settings
export RELEASE_STATUS
export KERNEL_VERSION
export TYPE_KERNEL
export CODENAME
export USEGCC
export JOBS
export CONFIG_FILE
export DEVICES
export KERNEL_NAME
export PHONE
export token
export SEND_TO_HANA_CI
export ARCH=arm64

DEVELOPER="xenontheinertg-nicklas373"
HOST="fusion_lavender-Dev"

export TZ=":Asia/Dhaka"

# USEGCC
# 0
# 92 = GCC 9.2.0 from Najahi
# 2 = GCC Linaro 4.9.4 (elf version)
# 3 = GCC Linaro 4.9.4 (non-elf version)
 
if [ ! $RELEASE_STATUS ]; then
    RELEASE_STATUS=0
fi
if [ ! $KERNEL_VERSION ]; then
    KERNEL_VERSION="1.00"
fi
if [ ! $TYPE_KERNEL ]; then
    TYPE_KERNEL="IDK"
fi
if [ ! $CODENAME ]; then
    CODENAME="Testing"
fi
if [ ! $KERNEL_NAME ]; then
    KERNEL_NAME="Fusion"
fi
if [ ! $CONFIG_FILE ]; then
    echo "Fill CONFIG_FILE!!!"
    exit 1
fi
if [[ ! $DEVICES || ! $PHONE ]]; then
    echo " Fill DEVICES and PHONE!!!"
    exit 1
fi
if [ ! $JOBS ]; then
    JOBS="$(nproc)"
fi

# Location of Toolchain
KERNELDIR=$PWD
TOOLDIR=$KERNELDIR/.ToolBuild
ZIP_DIR="${TOOLDIR}/AnyKernel3"
OUTDIR="${KERNELDIR}/.Output"
IMAGE="${OUTDIR}/arch/arm64/boot/Image.gz-dtb"

# Download tool
git clone https://github.com/xenontheinertg/AnyKernel3 -b fusion ${ZIP_DIR}
 
if [ $USEGCC -eq 92 ]; then
    git clone -b non-elf/gcc-9.2.0/arm --depth=1 --single-branch https://github.com/chips-project/priv-toolchains "${TOOLDIR}/gcc9.2/arm"
    git clone -b non-elf/gcc-9.2.0/arm64 --depth=1 --single-branch https://github.com/chips-project/priv-toolchains "${TOOLDIR}/gcc9.2/arm64"
    GCC32="${TOOLDIR}/gcc9.2/arm/bin/arm-linux-gnueabi-"
    GCC64="${TOOLDIR}/gcc9.2/arm64/bin/aarch64-linux-gnu-"
elif [ $USEGCC -eq 2 ]; then
    git clone -b elf/gcc-linaro-4.9.4 --depth=1 https://github.com/aln-project/toolchain "${TOOLDIR}/GCC"
    GCC64="${TOOLDIR}/GCC/arm64/bin/aarch64-elf-"
    GCC32="${TOOLDIR}/GCC/arm/bin/arm-eabi-"
elif [ $USEGCC -eq 3 ]; then
    git clone -b non-elf/gcc-linaro-4.9.4 --depth=1 https://github.com/aln-project/toolchain "${TOOLDIR}/GCC"
    GCC64="${TOOLDIR}/GCC/arm64/bin/aarch64-linux-gnu-"
    GCC32="${TOOLDIR}/GCC/arm/bin/arm-linux-gnueabi-"
elif [ $USEGCC -eq 10 ]; then
    git clone -b non-elf/gcc-10.0.0/arm --depth=1 --single-branch https://github.com/chips-project/priv-toolchains "${TOOLDIR}/gcc9.2/arm"
    git clone -b non-elf/gcc-10.0.0/arm64 --depth=1 --single-branch https://github.com/chips-project/priv-toolchains "${TOOLDIR}/gcc9.2/arm64"
    GCC32="${TOOLDIR}/gcc9.2/arm/bin/arm-linux-gnueabi-"
    GCC64="${TOOLDIR}/gcc9.2/arm64/bin/aarch64-linux-gnu-"
elif [ $USEGCC -eq 93 ]; then
    git clone -b master --depth=1 --single-branch https://github.com/AOSPA/android_prebuilts_gcc_linux-x86_arm_arm-eabi "${TOOLDIR}/gcc9.3/arm"
    git clone -b master --depth=1 --single-branch https://github.com/AOSPA/android_prebuilts_gcc_linux-x86_aarch64_aarch64-elf "${TOOLDIR}/gcc9.3/arm64"
    GCC32="${TOOLDIR}/gcc9.3/arm/bin/arm-eabi-"
    GCC64="${TOOLDIR}/gcc9.3/arm64/bin/aarch64-elf-"
fi
TOOL_VERSION=$(${GCC64}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

# Telegram Function
BOT_API_KEY=$(openssl enc -base64 -d <<< "${token}")
if [ ${SEND_TO_HANA_CI} ]; then
    CHAT_ID=$(openssl enc -base64 -d <<< LTEwMDEyNTE5NTM4NDUK)
else
    CHAT_ID=$(openssl enc -base64 -d <<< LTEwMDEyMzAyMDQ5MjMK)
fi
BUILD_FAIL="CAADBQADigADWtMDKL3bJB8yS0yiFgQ"
BUILD_SUCCESS="CAADBQADXgADWtMDKLZjh6sbUrFbFgQ"

function sendInfo() {
    curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d chat_id=$CHAT_ID -d "parse_mode=HTML" -d text="$(
            for POST in "${@}"; do
                echo "${POST}"
            done
        )" 
&>/dev/null
}
 
function sendZip() {
	curl -F chat_id="$CHAT_ID" -F document=@"$ZIP_DIR/$ZIP_NAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
}
 
function sendStick() {
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendSticker -d sticker="${1}" -d chat_id=$CHAT_ID &>/dev/null
}
 
function sendLog() {
	curl -F chat_id="$CHAT_ID" -F document=@"$BUILDLOG" https://api.telegram.org/bot$BOT_API_KEY/sendDocument &>/dev/null
}
 
#####

if [ $RELEASE_STATUS -eq 1 ]; then
	KVERSION="${CODENAME}-${KERNEL_VERSION}"
	ZIP_NAME="${KERNEL_NAME}-${KVERSION}-${DEVICES}-$(date "+%H%M-%d%m%Y").zip"
elif [ $RELEASE_STATUS -eq 0 ]; then
	KVERSION="${CODENAME}-$(git log --pretty=format:'%h' -1)-$(date "+%H%M")"
	ZIP_NAME="${KERNEL_NAME}-${CODENAME}-${DEVICES}-$(git log --pretty=format:'%h' -1)-$(date "+%H%M").zip"
fi

BUILDLOG="${OUTDIR}/${KERNEL_NAME}-${KVERSION}.log"
 
####
 
function make_zip () {
	cd ${ZIP_DIR}/
	make clean &>/dev/null
	if [ ! -f ${IMAGE} ]; then
        	echo -e "Build failed :P";
        	sendInfo "$(echo -e "Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.")";
	        sendInfo "$(echo -e "Kernel compilation failed")";
			sendStick "${BUILD_FAIL}"
			sendLog
        	exit 1;
	fi
	echo "**** Copying zImage ****"
	cp ${IMAGE} ${ZIP_DIR}
	make ZIP="${ZIP_NAME}" normal &>/dev/null
}
 
function clean_outdir() {
    make O=${OUTDIR} clean
    make mrproper
    rm -rf ${OUTDIR}/*
}
 
BUILD_START=$(date +"%s")
DATE=`date`
 
sendInfo "<b>---- ${KERNEL_NAME} New Kernel ----</b>" \
    "<b>Device:</b> ${DEVICES} or ${PHONE}" \
    "<b>Name:</b> <code>${KERNEL_NAME}-${KVERSION}</code>" \
    "<b>Kernel Version:</b> <code>$(make kernelversion)</code>" \
    "<b>Type:</b> <code>${TYPE_KERNEL}</code>" \
    "<b>Commit:</b> <code>$(git log --pretty=format:'%h : %s' -1)</code>" \
    "<b>Started on:</b> <code>$(hostname)</code>" \
    "<b>Compiler:</b> <code>${TOOL_VERSION}</code>" \
    "<b>Started at</b> <code>$DATE</code>"

clean_outdir

function compile() {
    make ARCH=arm64 O="${OUTDIR}" "${CONFIG_FILE}"
    make "-j${JOBS}" O="${OUTDIR}" \
                          ARCH=arm64 \
                          CROSS_COMPILE="${GCC64}" \
                          CROSS_COMPILE_ARM32="${GCC32}" \
                          KBUILD_BUILD_USER="${DEVELOPER}" \
                          KBUILD_BUILD_HOST="${HOST}" \
                          LOCALVERSION="${KVERSION}"
}

compile 2>&1 | tee "${BUILDLOG}"

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

make_zip
# sendInfo "$(echo -e "NOTE!!! INSTALL on ROM ${CODENAME} ONLY!!!")" 
sendZip
sendLog
sendInfo "$(echo -e "Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.")"
sendStick "${BUILD_SUCCESS}"
 

