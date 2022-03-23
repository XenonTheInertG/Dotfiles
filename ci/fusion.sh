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
export TARGET_ROM
export USECLANG
export JOBS
export CONFIG_FILE
export DEVICES
export KERNEL_NAME
export PHONE
export token
export SEND_TO_HANA_CI

export ARCH=arm64
export SUBARCH=arm64
DEVELOPER="xenontheinertg-nicklas373"
HOST="fusion_lavender-Dev"

export TZ=":Asia/Dhaka"

# USECLANG
# list:
# nusantara-10
# pendulum-10
# proton-10
# proton-11

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
if [ ! $TARGET_ROM ]; then
    TARGET_ROM="aosp"
fi
if [ ! $USECLANG ]; then
    USECLANG=1
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
# DTB="${OUTDIR}/arch/arm64/boot/dts/qcom"

# Download tool
git clone https://github.com/xenontheinertg/AnyKernel3 -b fusion ${ZIP_DIR}

# CLANGDIR="/root/${USECLANG}"
CLANGDIR="$TOOLDIR/clang-llvm"
git clone --depth=1 https://github.com/Panchajanya1999/clang-llvm.git "$CLANGDIR"

TOOL_VERSION=$("${CLANGDIR}/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
export LD_LIBRARY_PATH="${CLANGDIR}/bin/../lib:$PATH"

##
if [ $RELEASE_STATUS -eq 1 ]; then
	KVERSION="${CODENAME}-${KERNEL_VERSION}"
	ZIP_NAME="${KERNEL_NAME}-${KVERSION}-${DEVICES}-$(date "+%H%M-%d%m%Y").zip"
elif [ $RELEASE_STATUS -eq 0 ]; then
	KVERSION="${CODENAME}-$(git log --pretty=format:'%h' -1)-$(date "+%H%M")"
	ZIP_NAME="${KERNEL_NAME}-${CODENAME}-${DEVICES}-$(git log --pretty=format:'%h' -1)-$(date "+%H%M").zip"
fi

BUILDLOG="${TOOLDIR}/${KERNEL_NAME}-${KVERSION}.log"

#######

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
	curl -F chat_id="$CHAT_ID" -F document=@"$BUILDLOG" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
}
 
#####

####

function makeZip() {
    make -C $ZIP_DIR ZIP="${ZIP_NAME}" normal &>/dev/null
}
 
function cleanOutdir() {
    make O=${OUTDIR} clean
    make mrproper
    rm -rf ${OUTDIR}/
}

function compile_clang10() {
    make ARCH=arm64 O="${OUTDIR}" "${CONFIG_FILE}"
    PATH="${CLANGDIR}/bin:${PATH}" \
    make "-j${JOBS}" O="${OUTDIR}" \
                          ARCH=arm64 \
                          CC=clang \
                          CLANG_TRIPLE=aarch64-linux-gnu- \
                          CROSS_COMPILE=aarch64-linux-gnu- \
                          CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                          LOCALVERSION="-${KVERSION}" \
                          KBUILD_BUILD_USER="${DEVELOPER}" \
                          KBUILD_BUILD_HOST="${HOST}"
}

function lld() {
	make O="${OUTDIR}" "${CONFIG_FILE}"
	PATH="${CLANGDIR}/bin:${PATH}" \
	make -j"$JOBS" O="$OUTDIR" \
		CROSS_COMPILE=aarch64-linux-gnu- \
		CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
		CC=clang \
		AR=llvm-ar \
		NM=llvm-nm \
		LD=ld.lld \
		OBJCOPY=llvm-objcopy \
		OBJDUMP=llvm-objdump \
		STRIP=llvm-strip 2>&1 | tee "$BUILDLOG"
}

# cleanOutdir


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

# compile_clang10 2>&1 | tee "${BUILDLOG}"
lld

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

# check condition
if [ ! -f ${IMAGE} ]; then
    echo -e "Build failed :P";
    sendLog
    sendInfo "<b>Kernel Compilation Failed.</b>" \
             "Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
    sendStick "${BUILD_FAIL}"
    exit 1;
fi

# cp ${DTB}/*.dtb ${ZIP_DIR}/dtbs
cp ${IMAGE} ${ZIP_DIR}

#####

makeZip
sendZip
sendLog
sendInfo "$(echo -e "Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.")"
sendStick "${BUILD_SUCCESS}"
 

