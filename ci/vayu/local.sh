#!/usr/bin/env bash
#
# Copyright (C) XenonTheInertG)
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Script Build kernel for vayu or Poco X3 Pro
# Credit to: Rama Bondan Prakoso (rama982)
#

export TZ=":Asia/Dhaka"

while (( ${#} )); do
  case ${1} in
       "-c"|"--clean") CLEAN=true ;;
       "-d"|"--dirty") DIRTY=true ;;
       "-n"|"--codename") shift; CODENAME="-${1}" ;;
       "-C"|"--directory") shift; DIR=${1} ;;
       "-D"|"--defconfig") shift; CONFIG=${1} ;;
       "-e"|"--env") shift; ENV=${1} ;;
       "-r"|"--regen") REGEN=true ;;
  esac
  shift
done

if [[ -n ${DIR} ]]; then
  cd ${DIR}
fi
if [[ ! -f Makefile ]]; then
  echo "This not in rootdir kernel, please check directory again"
  exit 1
fi

# Setup environment
KDIR=$(pwd)
TC="${KDIR}/../tools"
AK=${TC}/AnyKernel
KERNEL_NAME="aLn"
KERNEL_TYPE="EAS"
PHONE="Poco X3 Pro"
DEVICE="vayu"
CONFIG=${CONFIG:-vayu_defconfig}
CODENAME=${CODENAME:--Testing}
CHAT_ID=""
TOKEN=""
DEVELOPER="xenontheinertg"
HOST="noob_vayu-dev"
AK_BRANCH="vayu"

if [[ ! -d $TC/clang || ! -d $TC/gcc64 || ! -d $TC/gcc32 ]]; then
  git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --depth=1 -b master $TC/clang
  git clone https://github.com/mvaisakh/gcc-arm64 --depth=1 $TC/gcc64
  git clone https://github.com/mvaisakh/gcc-arm --depth=1 $TC/gcc32
fi

if [[ ! -d ${AK} ]]; then
  git clone https://github.com/xenontheinertg/AnyKernel3 -b $AK_BRANCH ${AK}
fi

# Setup name
GIT="$(git log --pretty=format:'%h' -1)"
ENDZ="${GIT}-$(date "+%d%m%Y-%H%M")"
KVERSION="${CODENAME}-${GIT}"
ZIP_NAME="${KERNEL_NAME}${CODENAME}-${DEVICE}-${ENDZ}.zip"
LOG=$(echo ${ZIP_NAME} | sed "s/.zip/.log/")
LOGE=$(echo ${ZIP_NAME} | sed "s/.zip/.error.log/")

# Setup clang environment
IMG="$KDIR/out/arch/arm64/boot/Image"
DTBO="$KDIR/out/arch/arm64/boot/dtbo.img"
DTB="$KDIR/out/arch/arm64/boot/dts/qcom"
CL="$TC/clang/clang-r437112b"
export PATH="${CL}/bin:${TC}/gcc64/bin:${TC}/gcc32/bin:$PATH"
export LD_LIBRARY_PATH="${CL}/lib:$LD_LIBRARY_PATH"
KBUILD_COMPILER_STRING=$("${CL}/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

#echo $(which clang)
#echo $(which aarch64-elf-gcc)
#echo $(which arm-eabi-gcc-12.0.0)
#echo $PATH
#echo $KBUILD_COMPILER_STRING

#exit

START=$(date +"%s")

disable_lto() {
  scripts/config --file out/.config -e CONFIG_THINLTO
}

enable_dtbo() {
  scripts/config --file out/.config -e CONFIG_BUILD_ARM64_DTBO_IMG
}

xcache() {
  export CCACHE_EXEC=$(which ccache)
  export USE_CCACHE=1
  export CCACHE_DIR=$KDIR/.ccache
  ccache -M 20G >/dev/null
  # ccache -o compression=true
}

xcache

m() {
  make -j$(nproc --all) O=out \
                        ARCH=arm64 \
                        LOCALVERSION=${KVERSION} \
                        CC="ccache clang" \
                        LLVM=1 \
                        CLANG_TRIPLE=aarch64-elf- \
                        CROSS_COMPILE=aarch64-elf- \
                        CROSS_COMPILE_ARM32=arm-eabi- \
                        ${ENV} \
                        ${@}
}

if [[ -n ${REGEN} ]]; then
  m $CONFIG
  m menuconfig
  m savedefconfig
  cp out/defconfig arch/arm64/configs/$CONFIG
  exit 0
fi

if [[ -n ${CLEAN} ]]; then
  m mrproper 2>/dev/null
  m clean 2>/dev/null
fi

# Build kernel
rm -rf ${IMG}
rm -rf ${DTBO}

m $CONFIG > /dev/null
disable_lto
enable_dtbo
m > >(tee out/${LOG}) 2> >(tee out/${LOGE} >&2)

END=$(date +"%s")
DIFF=$(($END - $START))

sendInfo() {
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d "parse_mode=HTML" -d text="$(
            for POST in "${@}"; do
                echo "${POST}"
            done
        )"
&>/dev/null
}

sendInfo "<b>----- ${KERNEL_NAME} New Kernel -----</b>" \
	"<b>Device:</b> ${DEVICE} or ${PHONE}" \
	"<b>Name:</b> <code>${KERNEL_NAME}${KVERSION}</code>" \
	"<b>Kernel Version:</b> <code>$(make kernelversion)</code>" \
	"<b>Type:</b> <code>${KERNEL_TYPE}</code>" \
	"<b>Branch:</b> <code>$(git branch --show-current)</code>" \
	"<b>Commit:</b> <code>$(git log --pretty=format:'%h : %s' -1)</code>" \
	"<b>Started on:</b> <code>$(hostname)</code>" \
	"<b>Compiler:</b> <code>${KBUILD_COMPILER_STRING}</code>"

push() {
  curl -F document=@"$1" "https://api.telegram.org/bot$TOKEN/sendDocument" \
		-F chat_id="$CHAT_ID" \
		-F "disable_web_page_preview=true" \
		-F "parse_mode=html" \
		-F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | #aLn | <b>vayu</b>"
}

if [[ ! -f ${IMG} ]]; then
  echo "Failed build!"
  push out/${LOG}
  push out/${LOGE}
  exit 1
fi

make -C ${AK} clean
cp ${IMG} ${AK}
cp ${DTBO} ${AK}
find ${DTB} -name "*.dtb" -exec cat {} + > ${AK}/dtb
make -C ${AK} ZIP="${ZIP_NAME}" normal

push ${AK}/${ZIP_NAME}
push out/${LOG}
