#!/usr/bin/env bash
#
# Copyright (C)  @xenontheinertg 
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Credit to @panchajanya1999 for compile use clang
# https://github.com/Panchajanya1999/myscripts/blob/master/kernel.sh
#
# New Automatic Build for global
#
#
# Example CONFIGURATION
# export RELEASE_STATUS=0 # 0 for false | 1 for true
# export KERNEL_NAME="aLn"
# export CODENAME="Blood Voivode"
# export RELEASE_VERSION="1.00"
# export KERNEL_TYPE="EAS"
# export PHONE="Redmi Note 7"
# export DEVICES="lavender"
# export CONFIG_FILE="lavender_defconfig" # Defconfig
# export USECLANG="nusantara-10" # explain in bottom
# export USEGCC=93 # explain in bottom
# export CHAT_ID=-11234566
# export COMPILER_IS_CLANG=true # true for using clang | false for gcc
# AK_BRANCH="lavender"
# export JOBS=8
#
# # USECLANG
# list:
# nusantara-10
# pendulum-10
# proton-10
# proton-11
# proton-12
#
# USEGCC
# 0
# 92 = GCC 9.2.0 from Najahi
# 93 = GCC 9.3.0 elf
# 2 = GCC Linaro 4.9.4 (elf version)
# 3 = GCC Linaro 4.9.4 (non-elf version)
#

export RELEASE_STATUS
export RELEASE_VERSION
export KERNEL_NAME
export KERNEL_TYPE
export CODENAME
export CONFIG_FILE
export DEVICES
export PHONE
export token
export CHAT_ID
export COMPILER_IS_CLANG
export USEGCC
export USECLANG
export DEVELOPER
export HOST
export AK_BRANCH
export JOBS
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
OUTDIR="${KERNELDIR}/.Out"
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
	if [ "$COMPILER_IS_CLANG" = true ]; then
		export LD_LIBRARY_PATH="${CLANGDIR}/bin/../lib:$PATH"
		PATH="${CLANGDIR}/bin:${PATH}"
		export PATH
	fi
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

function tool_gcc {
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
}

function tool_clang {
	CLANGDIR="/root/$USECLANG"
	TOOL_VERSION=$("${CLANGDIR}/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
}

function compile_gcc() {
	make O="${OUTDIR}" "${CONFIG_FILE}"
	make -j"$JOBS" O="${OUTDIR}" \
		CROSS_COMPILE="${GCC64}" \
		CROSS_COMPILE_ARM32="${GCC32}"
}

function compile_clang() {
	make O="${OUTDIR}" "${CONFIG_FILE}"
	make -j"$JOBS" O="$OUTDIR" \
		CROSS_COMPILE=aarch64-linux-gnu- \
		CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
		CC=clang \
		AR=llvm-ar \
		NM=llvm-nm \
		LD=ld.lld \
		OBJCOPY=llvm-objcopy \
		OBJDUMP=llvm-objdump \
		STRIP=llvm-strip
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

if [ "$COMPILER_IS_CLANG" = true ]; then
	tool_clang
	exports
	send_start
	compile_clang 2>&1 | tee "${BUILDLOG}"
else
	tool_gcc
	exports
	send_start
	compile_gcc 2>&1 | tee "${BUILDLOG}"
fi

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

makeZip
sendInfo "$(echo -e "Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.")"
sendLog
sendZip
# sendStick "${BUILD_SUCCESS}"
