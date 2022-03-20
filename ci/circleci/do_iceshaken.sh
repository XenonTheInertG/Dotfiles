#!/bin/bash
# shellcheck disable=SC2155
# set -e

## Copy this script inside the kernel directory
KERNEL_DIR=$PWD
KERNEL_DEFCONFIG=beryllium_defconfig
ANY_KERNEL3_DIR=$KERNEL_DIR/AnyKernel3/
DATE_CLOCK=$(date +'%H%M-%d%m%y')
FINAL_KERNEL_ZIP="gmw-beryllium-${DATE_CLOCK}.zip"
ZIP9=$KERNEL_DIR/$FINAL_KERNEL_ZIP
BUILDLOG="$KERNEL_DIR/out/$FINAL_KERNEL_ZIP.log"

BOT_TOKEN=""
CHAT_ID=""

BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo -e "$cyan**** Setting Toolchain $red****"
export PATH="/root/proton-clang/bin/:${PATH}"
export ARCH=arm64
export KBUILD_COMPILER_STRING=$(clang --version)
export KBUILD_BUILD_USER=CI
export KBUILD_BUILD_HOST=$(uname -a)
git config --global user.email "harunbam3@gmail.com"
git config --global user.name "goodmeow"

function cleanKernel() {
     echo "**** Cleaning ****"
     echo "$yellow**** Removing leftovers ****"
     rm -rf "$ANY_KERNEL3_DIR"/*.zip "$ANY_KERNEL3_DIR"/Image.gz-dtb "$KERNEL_DIR"/out
     mkdir -p out
}

function compileKernel() {
     echo -e "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
     echo -e "$blue************************************************"
     echo -e "                   BUILDING KERNEL                   "
     echo -e "***********************************************$nocol"
     make -s -C "$(pwd)" O=out "$KERNEL_DEFCONFIG"
     make -C "$(pwd)" O=out \
                              -j"$(nproc --all)" \
                              CC=clang \
                              CROSS_COMPILE=aarch64-linux-gnu- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                              NM=llvm-nm \
                              OBJCOPY=llvm-objcopy \
                              OBJDUMP=llvm-objdump \
                              STRIP=llvm-strip | tee $BUILDLOG
     if [[! -e "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb ]]; then
          echo -e "**** Error found, compiling aborted ****"
          sendLog "$BUILDLOG"
          LOGTRIM="$KERNEL_DIR/out/log_trimmed.log"
          sed -n '/[Error:*]:/,//p' $BUILDLOG &> $LOGTRIM
          sendLog "$LOGTRIM"
          sendInfo "Error found compiling aborted, see error log above."
          exit
     fi
     echo -e "**** Compiling Success ****"
     echo -e "**** Copying Image.gz-dtb ****"
     cp "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb "$ANY_KERNEL3_DIR"/
}

function sendKernel() {
         curl -F document=@"$ZIP9" https://api.telegram.org/bot"$BOT_TOKEN"/sendDocument \
              -F chat_id="$CHAT_ID" \
              -F "disable_web_page_preview=true" \
              -F "parse_mode=html" \
              -F caption= \
              -F "Build took $((DIFF / 60)) minutes and $((DIFF % 60)) seconds." \
              -F "For <b> Pocophone F1 - Beryllium - Android 10/Q </b>" \
              -F "<b>$(clang --version | head -n 1 | perl -pe 's/\(https.*?\)//gs' | sed -e 's/  */ /g')</b>"
              -F "SHA $(sha1sum "$FINAL_KERNEL_ZIP")"     
}

function sendInfo() {
     	curl -s -X POST https://api.telegram.org/bot"$BOT_TOKEN"/sendMessage -d chat_id=$CHAT_ID -d "parse_mode=HTML" -d text="$(
		for POST in "${@}"; do
			echo "${POST}"
		done
	)" &> /dev/null
}

function sendLog() {
	curl -F chat_id=$CHAT_ID -F document=@"$1" https://api.telegram.org/bot"$BOT_TOKEN"/sendDocument &>/dev/null
}

function zipKernel() {
     # Anykernel 3 time!!
     echo -e "**** Time to zip up! ****"
     cd "$ANY_KERNEL3_DIR"/
     zip -r9 "$FINAL_KERNEL_ZIP" * -x README "$FINAL_KERNEL_ZIP"
     cp "$FINAL_KERNEL_ZIP" "$KERNEL_DIR"/"$FINAL_KERNEL_ZIP"
     echo -e "**** Done, here is your sha1 ****"
     cd "$KERNEL_DIR"
}

# Main
retVal=$?
sendInfo
cleanKernel
compileKernel
zipKernel
sendKernel

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in '$(($DIFF / 60))' minute(s) and '$(($DIFF % 60))' seconds.$nocol"
exit