#!/bin/bash

#set -e

## Copy this script inside the kernel directory
KERNEL_DIR=$PWD
KERNEL_DEFCONFIG=dipper_defconfig
ANY_KERNEL3_DIR=$KERNEL_DIR/AnyKernel3/
DATE_CLOCK=$(date +'%H%M-%d%m%y')
FINAL_KERNEL_ZIP="YeetAnotherPerf-dipper-${DATE_CLOCK}.zip"
ZIP9=$KERNEL_DIR/$FINAL_KERNEL_ZIP

BOT_TOKEN=
CHAT_ID=

BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo "$cyan**** Setting Toolchain $red****"
export PATH="/root/proton-clang/bin/:${PATH}"
#export LD_LIBRARY_PATH="/root/clang/bin/../lib:${LD_LIBRARY_PATH}"
export ARCH=arm64
export KBUILD_COMPILER_STRING="Proton-Clang 11.0.0"
export KBUILD_BUILD_USER=CI
export KBUILD_BUILD_HOST=fedora31
git config --global user.email "harunbam3@gmail.com"
git config --global user.name "goodmeow"

# Speed up build process
MAKE="./makeparallel"

# Clean build always lol
echo "**** Cleaning ****"
mkdir -p out
#make O=out clean

echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "                   BUILDING KERNEL          "
echo -e "***********************************************$nocol"
make -s -C "$(pwd)" O=out $KERNEL_DEFCONFIG
make -C "$(pwd)" O=out \
                                -j"$(nproc --all)" \
                                CC=clang \
                                CROSS_COMPILE=aarch64-linux-gnu- \
                                CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                                NM=llvm-nm \
                                OBJCOPY=llvm-objcopy \
                                OBJDUMP=llvm-objdump \
                                STRIP=llvm-strip

echo "**** Verify Image.gz-dtb ****"
ls $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb

#Anykernel 3 time!!
echo "**** Verifying AnyKernel3 Directory ****"
ls $ANY_KERNEL3_DIR
echo ""$yellow"**** Removing leftovers ****"
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
              -F caption="Build took '$(($DIFF / 60))' minutes and '$(($DIFF % 60))' seconds. | for <b> Pocophone F1 - Beryllium - Android 10/Q </b> | <b>$(clang --version | head -n 1 | perl -pe 's/\(https.*?\)//gs' | sed -e 's/  */ /g')</b> | here is your sha $(sha1sum $FINAL_KERNEL_ZIP)"     
}

echo "**** Done, here is your sha1 ****"
cd $KERNEL_DIR
rm -rf $ANY_KERNEL3_DIR/*.zip
rm -rf AnyKernel3/Image.gz-dtb
rm -rf $KERNEL_DIR/out/

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
send
echo -e "$yellow Build completed in '$(($DIFF / 60))' minute(s) and '$(($DIFF % 60))' seconds.$nocol"
