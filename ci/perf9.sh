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
export ARCH=arm64
DEVELOPER="perf"
HOST="perf_lavender-Dev"

export TZ=":Asia/Dhaka"

# USECLANG
# 0
# 1 = Stock from Google
 
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
    KERNEL_NAME="perf"
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
CLANGDIR="${TOOLDIR}/clang"
ZIP_DIR="${TOOLDIR}/AnyKernel3"
OUTDIR="${KERNELDIR}/.Output"
IMAGE="${OUTDIR}/arch/arm64/boot/Image.gz-dtb"
#DTB="${OUTDIR}/arch/arm64/boot/dts/qcom"

export PATH="${TOOLDIR}/clang/bin:${TOOLDIR}/gcc/arm64/bin:${TOOLDIR}/gcc/arm/bin:${PATH}"

# Download tool
git clone https://github.com/xenontheinertg/AnyKernel3 -b perf ${ZIP_DIR}
 
if [ $USECLANG -eq 1 ]; then
    git clone --depth=1 -b google/clang-9.0.8 https://github.com/aln-project/toolchain "${CLANGDIR}"
    git clone --depth=1 -b google/gcc-4.9.r39 https://github.com/aln-project/toolchain "${TOOLDIR}/gcc"
elif [ $USECLANG -eq 2 ]; then
    git clone --depth=1 -b master https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 "${CLANGDIR}"
    git clone --depth=1 -b google/gcc-4.9.r39 https://github.com/aln-project/toolchain "${TOOLDIR}/gcc"
fi

TOOL_VERSION=$("${CLANGDIR}/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

##
#######

# Telegram Function
BOT_API_KEY=$(openssl enc -base64 -d <<< "${token}")
CHAT_ID=$(openssl enc -base64 -d <<< LTM1OTYzMDM5MAo=)
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

BUILDLOG="${OUTDIR}/build-${CODENAME}-${DEVICES}-$(date "+%H%M-%d%m%Y").log"

if [ $RELEASE_STATUS -eq 1 ]; then
	KVERSION="${CODENAME}-${KERNEL_VERSION}"
	ZIP_NAME="${KERNEL_NAME}-${KVERSION}-${DEVICES}-$(date "+%H%M-%d%m%Y").zip"
elif [ $RELEASE_STATUS -eq 0 ]; then
	KVERSION="${CODENAME}-$(git log --pretty=format:'%h' -1)-$(date "+%H%M")"
	ZIP_NAME="${KERNEL_NAME}-${CODENAME}-${DEVICES}-$(git log --pretty=format:'%h' -1)-$(date "+%H%M").zip"
fi
 
if [ ! -d "${BUILDLOG}" ]; then
 	rm -rf "${BUILDLOG}"
fi
 
####
 
function makeZip() {
    make -C $ZIP_DIR ZIP="${ZIP_NAME}" normal &>/dev/null
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

function compile_clang9() {
    make ARCH=arm64 O="${OUTDIR}" "${CONFIG_FILE}"
    make "-j${JOBS}" O="${OUTDIR}" \
                          ARCH=arm64 \
                          CC=clang \
                          CLANG_TRIPLE=aarch64-linux-gnu- \
                          CROSS_COMPILE=aarch64-linux-android- \
                          CROSS_COMPILE_ARM32=arm-linux-androideabi- \
                          KBUILD_BUILD_USER="${DEVELOPER}" \
                          KBUILD_BUILD_HOST="${HOST}"
}

compile_clang9 2>&1 | tee "${BUILDLOG}"

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

cp ${IMAGE} ${ZIP_DIR}
 
makeZip
sendZip
sendLog
sendInfo "$(echo -e "Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.")"
sendStick "${BUILD_SUCCESS}"
 


