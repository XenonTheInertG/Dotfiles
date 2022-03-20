#!/bin/bash

#set -e

## Copy this script inside the kernel directory
KERNEL_DIR=$PWD
DEVICE=Beryllium
KERNEL_DEFCONFIG=beryllium_defconfig
ANY_KERNEL3_DIR=$KERNEL_DIR/AnyKernel3/
DATE_CLOCK=$(date +'%H%M-%d%m%y')
FINAL_KERNEL_ZIP="GaijinKernel-Beryllium-"${DATE_CLOCK}".zip"
ZIP9=$KERNEL_DIR/$FINAL_KERNEL_ZIP

BOT_TOKEN=
CHAT_ID=

# Speed up build process
MAKE="./makeparallel"

BUILD_START=$(date +"%s")

function sendinfo() {
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
                        -d chat_id="$CHAT_ID" \
                        -d "disable_web_page_preview=true" \
                        -d "parse_mode=html" \
                        -d text="<b>GaijinKernel</b> new build is up%0AStarted on <code>semaphoreCI</code>%0AFor device $DEVICE%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AStarted on <code>$(TZ=Asia/Jakarta date)</code>%0A<b>CI Workflow information:</b> <a href='https://gmw.semaphoreci.com/workflows/${SEMAPHORE_WORKFLOW_ID}'>here</a>"
}

blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo "**** Setting Toolchain ****"
PATH="/root/clang/bin/:${PATH}"
export LD_LIBRARY_PATH="/root/clang/bin/../lib:${LD_LIBRARY_PATH}"
export ARCH=arm64
# export KBUILD_COMPILER_STRING="NusantaraDevs clang 11.0.0"
export KBUILD_BUILD_USER=semaphoreCI
export KBUILD_BUILD_HOST=fedora31
git config --global user.email "harunbam3@gmail.com"
git config --global user.name "goodmeow"

# Clean build always lol
echo "**** Cleaning ****"
mkdir -p out
#make O=out clean
sendinfo
echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "                   BUILDING KERNEL          "
echo -e "***********************************************$nocol"
make -s -C "$(pwd)" O=out $KERNEL_DEFCONFIG
make -C "$(pwd)" O=out \
                 -j$(nproc) \
                 CC=clang \
                 CLANG_TRIPLE=aarch64-linux-gnu- \
                 CROSS_COMPILE=aarch64-linux-gnu- \
                 CROSS_COMPILE_ARM32=arm-linux-gnueabi-

echo "**** Verify Image.gz-dtb ****"
ls $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb

#Anykernel 3 time!!
echo "**** Verifying AnyKernel3 Directory ****"
ls $ANY_KERNEL3_DIR
echo "**** Removing leftovers ****"
rm -rf $ANY_KERNEL3_DIR/Image.gz-dtb
rm -rf $ANY_KERNEL3_DIR/$FINAL_KERNEL_ZIP

echo "**** Copying Image.gz-dtb ****"
cp $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb $ANY_KERNEL3_DIR/

echo "**** Time to zip up! ****"
cd $ANY_KERNEL3_DIR/
zip -r9 $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP
cp $FINAL_KERNEL_ZIP $KERNEL_DIR/$FINAL_KERNEL_ZIP

function send() {
         curl -F document=@$ZIP9 https://api.telegram.org/bot$BOT_TOKEN/sendDocument \
              -F chat_id="$CHAT_ID" \
              -F "disable_web_page_preview=true" \
              -F "parse_mode=html" \
              -F caption="Build took '$(($DIFF / 60))' minute(s) and '$(($DIFF % 60))' second(s). | For <b>Pocophone F1 (Beryllium) Android 10/Q</b> | <b>$(clang --version | head -n 1 | perl -pe 's/\(https.*?\)//gs' | sed -e 's/  */ /g')</b>"
}

echo "**** Done, here is your sha1 ****"
cd $KERNEL_DIR
#rm -rf $ANY_KERNEL3_DIR/$FINAL_KERNEL_ZIP
rm -rf AnyKernel3/Image.gz-dtb
rm -rf $KERNEL_DIR/out/

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
send
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
sha1sum $KERNEL_DIR/$FINAL_KERNEL_ZIP
