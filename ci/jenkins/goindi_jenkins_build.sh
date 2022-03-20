#!/bin/bash

user="harun"
rom_dir="ancient12"

# build var
lunch_command="ancient"
device_codename="apollo"
build_type="userdebug"

# Rom G-Apps var
# To build with gapps or no )(yes|no)
gapps_command="ANCIENT_GAPPS" 
with_gapps="yes"

# Make command  : yes|no|bacon
# yes for brunch, no make with romname
# Add bacon for make bacon
# mka for making bacon with mka
use_brunch="bacon"
# Uncomment set to (yes|no(default)|installclean)
make_clean="installclean"
#make_clean="yes"
# If  building apk put the apk name here.
target_name="no"

# neverallow
neverallows_bools=true

# ROM Var
rom_name="Ancient"*.zip # Zip name
# build directory var
if [ -d "/home/${user}" ]; then
        folder="/home/${user}/${rom_dir}"
    else
        folder="/home2/${user}/${rom_dir}"
fi
OUT_PATH="$folder/out/target/product/${device_codename}"
ROM=${OUT_PATH}/${rom_name}

# Ccahe Variables
cache_size=55G # In GB
enable_cache=yes

# Telegram Config
newpeeps=/home/configs/harun.conf
baseconfig=/home/configs/priv.conf

tg_priv(){
	sudo telegram-send --format html "$priv" --config ${newpeeps} --disable-web-page-preview
}

# go to build directory
cd "$folder"

echo -e "Build starting thank you for waiting"
BLINK="https://ci.goindi.org/job/$JOB_NAME/$BUILD_ID/console"

read -r -d '' priv <<EOT
<b>Build Number : $BUILD_ID Started</b> 
<b>Console log:</b> <a href="${BLINK}">here</a>
<b>Happy Building</b>
EOT
tg_priv $priv


# ccache 
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=${enable_cache}
export CCACHE_DIR=/ccache/${user}/${rom_dir}
ccache -M ${cache_size}

if [ -d ${CCACHE_DIR} ]; then
	sudo chmod 777 ${CCACHE_DIR}
	echo "ccache folder already exists."
else
	sudo mkdir -p ${CCACHE_DIR}
	sudo chmod 777 ${CCACHE_DIR}
	echo "modifying ccache dir permission."
fi

# Building 
source build/envsetup.sh
export SELINUX_IGNORE_NEVERALLOWS=$neverallows_bools

if [ "$with_gapps" = "yes" ]; then
	export "$gapps_command"=true
else
	export "$gapps_command"=false
fi

if [ "$make_clean" = "yes" ];  then
     #rm -rf out/
     make clobber
     echo -e "Clean Build";
     elif [ "$make_clean" = "installclean" ]; then
     #rm -rf ${OUT_PATH}
     make installclean
     echo -e "Installclean";
fi

# remove old build zip & lunch device
rm -rf ${OUT_PATH}/*.zip
lunch ${lunch_command}_${device_codename}-${build_type}

if [ "$target_name" = "no" ]; then
	if [ "$use_brunch" = "yes" ]; then
		brunch ${device_codename}
	elif [ "$use_brunch" = "no" ]; then
		make ${lunch_command} -j100
	elif [ "$use_brunch" = "bacon" ]; then
		make bacon -j100
	elif [ "$use_brunch" = "mka" ];	then
		mka bacon -j$(nproc --all)
	else
	make $target_name
	fi
fi

if [ -f $ROM ]; then
	mkdir -p /home/downloads/${user}/${device_codename}
	cp $ROM /home/downloads/${user}/${device_codename}
        cp $ROM $folder

	# zip var
	filename="$(basename $ROM)"
	LINK="https://download.goindi.org/${user}/${device_codename}/${filename}"
	size="$(du -h ${ROM}|awk '{print $1}')"
	mdsum="$(md5sum ${ROM}|awk '{print $1}')"

	read -r -d '' priv <<EOT
	<b>Build Number: $BUILD_ID Completed</b>
	<b>Rom:</b> ${filename}
	<b>Size:</b> <pre>${size}</pre>
	<b>MD5:</b> <pre>${mdsum}</pre>
	<b>Download:</b> <a href="${LINK}">here</a>
EOT
else
	read -r -d '' priv <<EOT
	<b>Build Number: $BUILD_ID Failed</b>
	<b>Error:</b> <a href="https://ci.goindi.org/job/$JOB_NAME/$BUILD_ID/console">here</a>
EOT
fi
tg_priv $priv

read -r -d '' $1 <<EOT
Build for ${user}
Build ID: ${BUILD_ID}
Rom: ${lunch}
EOT
sudo telegram-send --format html "$1" --config ${baseconfig}
