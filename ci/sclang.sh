#!/usr/bin/env bash
#
# Copyright (C)  @xenontheinertg 
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Credit to @panchajanya1999 for compile use clang
# https://github.com/Panchajanya1999/myscripts/blob/master/kernel.sh
#

export TZ=":Asia/Dhaka"

if [ ! $KERNEL_TYPE ]; then
    TYPE_KERNEL="IDK"
fi
if [ ! $CODENAME ]; then
    CODENAME="Testing"
fi
if [ ! $KERNEL_NAME ]; then
    KERNEL_NAME="aLn"
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
TOOLDIR="$KERNELDIR/.Tool"
ZIP_DIR="${TOOLDIR}/AnyKernel3"
OUTDIR="${KERNELDIR}/out"
IMAGE="${OUTDIR}/arch/arm64/boot/Image.gz-dtb"

if [ "$RELEASE_STATUS" = true ]; then
	KVERSION="${CODENAME}-${RELEASE_VERSION}"
	ZIP_NAME="${KERNEL_NAME}-${KVERSION}-${DEVICES}-$(date "+%H%M-%d%m%Y").zip"
else
	KVERSION="${CODENAME}-$(git log --pretty=format:'%h' -1)-$(date "+%H%M")"
	ZIP_NAME="${KERNEL_NAME}-${CODENAME}-${DEVICES}-$(git log --pretty=format:'%h' -1)-$(date "+%H%M").zip"
fi
BUILDLOG="${OUTDIR}/${KERNEL_NAME}-${KVERSION}.log"

### Clone AnyKernel3 ###
git clone https://github.com/xenontheinertg/AnyKernel3 -b $AK_BRANCH ${ZIP_DIR}
###### Telegram Function #####
BOT_API_KEY=$(openssl enc -base64 -d <<< "${token}")
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

#########################################################################
function exports {
	export ARCH=arm64
	export SUBARCH=arm64
	export KBUILD_BUILD_USER="${DEVELOPER}"
	export KBUILD_BUILD_HOST="${HOST}"
	export LOCALVERSION="-${KVERSION}"
}

function makeZip () {
	make -C "$ZIP_DIR" clean &>/dev/null
	if [ ! -f ${IMAGE} ]; then
        	echo -e "Build failed :P";
		sendLog
        	sendInfo "$(echo -e "Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.")";
	        sendInfo "$(echo -e "Kernel compilation failed")";
		sendStick "${BUILD_FAIL}"
        	exit 1;
	fi
	echo "**** Copying zImage ****"
	cp ${IMAGE} ${ZIP_DIR}
	make -C "$ZIP_DIR" ZIP="${ZIP_NAME}" normal &>/dev/null
}

function clean_outdir() {
	make O=${OUTDIR} clean
	make mrproper
}

function tool_clang {
        git clone --depth=1 https://github.com/sohamxda7/llvm-stable  ${TOOLDIR}/clang
        git clone --depth=1 https://github.com/sohamxda7/llvm-stable -b gcc64 ${TOOLDIR}/gcc
        git clone --depth=1 https://github.com/sohamxda7/llvm-stable -b gcc32 ${TOOLDIR}/gcc32
	export PATH="${TOOLDIR}/clang/bin:${TOOLDIR}/gcc/bin:${TOOLDIR}/gcc32/bin:$PATH"
	CLANGDIR="${TOOLDIR}/clang"
	TOOL_VERSION=$("${CLANGDIR}/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
}

function compile_clang() {
	make O="${OUTDIR}" "${CONFIG_FILE}"
	make O="${OUTDIR}" savedefconfig	
	make -j"$JOBS" O="$OUTDIR" \
		ARCH=arm64 \
		CC=clang \
		CLANG_TRIPLE=aarch64-linux-gnu- \
		CROSS_COMPILE=aarch64-linux-android- \
		CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}

function send_start {
	sendInfo "<b>---- ${KERNEL_NAME} New Kernel ----</b>" \
		"<b>Device:</b> ${DEVICES} or ${PHONE}" \
		"<b>Name:</b> <code>${KERNEL_NAME}-${KVERSION}</code>" \
		"<b>Kernel Version:</b> <code>$(make kernelversion)</code>" \
		"<b>Type:</b> <code>${KERNEL_TYPE}</code>" \
		"<b>Branch:</b> <code>$(git branch --show-current)</code>" \
		"<b>Commit:</b> <code>$(git log --pretty=format:'%h : %s' -1)</code>" \
 		"<b>Started on:</b> <code>$(hostname)</code>" \
		"<b>Compiler:</b> <code>${TOOL_VERSION}</code>" \
		"<b>Started at</b> <code>$DATE</code>"
}

BUILD_START=$(date +"%s")
DATE=`date`

clean_outdir

tool_clang
exports
send_start
compile_clang 2>&1 | tee "${BUILDLOG}"

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

makeZip
sendInfo "$(echo -e "Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.")"
sendLog
sendZip
# sendStick "${BUILD_SUCCESS}"
