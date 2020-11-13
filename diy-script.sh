#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Actions

Diy_Core() {
Author=Hyy2001
Default_Device=d-team_newifi-d2
}

Diy-Part1() {
[ -f feeds.conf.default ] && sed -i "s/#src-git helloworld/src-git helloworld/g" feeds.conf.default
[ ! -d package/lean ] && mkdir package/lean

mv2 mac80211.sh package/kernel/mac80211/files/lib/wifi
mv2 system package/base-files/files/etc/config
mv2 AutoUpdate.sh package/base-files/files/bin
mv2 banner package/base-files/files/etc

# ExtraPackages svn network/services dnsmasq https://github.com/openwrt/openwrt/trunk/package/network/services
# ExtraPackages svn network/services hostapd https://github.com/openwrt/openwrt/trunk/package/network/services
# ExtraPackages svn network/services dropbear https://github.com/openwrt/openwrt/trunk/package/network/services
# ExtraPackages svn network/services ppp https://github.com/openwrt/openwrt/trunk/package/network/services
# ExtraPackages git kernel mt76 https://github.com/openwrt master
# ExtraPackages svn firmware linux-firmware https://github.com/openwrt/openwrt/trunk/package/firmware

ExtraPackages git lean luci-app-autoupdate https://github.com/Hyy2001X main
ExtraPackages git lean luci-theme-argon https://github.com/jerrykuku 18.06
ExtraPackages git lean luci-app-argon-config https://github.com/jerrykuku master
ExtraPackages git lean luci-app-adguardhome https://github.com/Hyy2001X master
ExtraPackages svn lean luci-app-smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages svn lean smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages git lean OpenClash https://github.com/vernesong master
ExtraPackages git lean luci-app-serverchan https://github.com/tty228 master
ExtraPackages svn lean luci-app-socat https://github.com/xiaorouji/openwrt-package/trunk/lienol
# ExtraPackages git lean openwrt-upx https://github.com/Hyy2001X master
# ExtraPackages svn lean luci-app-mentohust https://github.com/project-openwrt/openwrt/trunk/package/ctcgfw
# ExtraPackages svn lean mentohust https://github.com/project-openwrt/openwrt/trunk/package/ctcgfw
# ExtraPackages git lean openwrt-OpenAppFilter https://github.com/Lienol master
# ExtraPackages svn lean AdGuardHome https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
}

Diy-Part2() {
mv2 mwan3 package/feeds/packages/mwan3/files/etc/config
echo "Author: $Author"
echo "Lede Version: $Openwrt_Version"
echo "AutoUpdate Version: $AutoUpdate_Version"
echo "Router: $TARGET_PROFILE"
sed -i "s?$Lede_Version?$Lede_Version Compiled by $Author [$Compile_Date]?g" $Default_File
echo "$Openwrt_Version" > package/base-files/files/etc/openwrt_info
sed -i "s?Openwrt?Openwrt $Openwrt_Version / AutoUpdate $AutoUpdate_Version?g" package/base-files/files/etc/banner
}

Diy-Part3() {
Default_Firmware=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-squashfs-sysupgrade.bin
AutoBuild_Firmware=AutoBuild-$TARGET_PROFILE-Lede-${Openwrt_Version}.bin
AutoBuild_Detail=AutoBuild-$TARGET_PROFILE-Lede-${Openwrt_Version}.detail
mkdir -p bin/Firmware
echo "Firmware: $AutoBuild_Firmware"
mv bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$Default_Firmware bin/Firmware/$AutoBuild_Firmware
echo "[$(date "+%H:%M:%S")] Calculating MD5 and SHA256 ..."
Firmware_MD5=$(md5sum bin/Firmware/$AutoBuild_Firmware | cut -d ' ' -f1)
Firmware_SHA256=$(sha256sum bin/Firmware/$AutoBuild_Firmware | cut -d ' ' -f1)
echo -e "MD5: $Firmware_MD5\nSHA256: $Firmware_SHA256"
touch bin/Firmware/$AutoBuild_Detail
echo -e "\nMD5:$Firmware_MD5\nSHA256:$Firmware_SHA256" >> bin/Firmware/$AutoBuild_Detail
}

ExtraPackages() {
PKG_PROTO=$1
PKG_DIR=$2
PKG_NAME=$3
REPO_URL=$4
REPO_BRANCH=$5
[ -d package/$PKG_DIR/$PKG_NAME ] && rm -rf package/$PKG_DIR/$PKG_NAME
[ -d $PKG_NAME ] && rm -rf $PKG_NAME
Retry_Times=3
while [ ! -f $PKG_NAME/Makefile ]
do
	echo "[$(date "+%H:%M:%S")] Checking out package [$PKG_NAME] from $REPO_URL ..."
	case $PKG_PROTO in
	git)
		git clone -b $REPO_BRANCH $REPO_URL/$PKG_NAME $PKG_NAME > /dev/null 2>&1
	;;
	svn)
		svn checkout $REPO_URL/$PKG_NAME $PKG_NAME > /dev/null 2>&1
	esac
	if [ -f $PKG_NAME/Makefile ] || [ -f $PKG_NAME/README* ];then
		echo "[$(date "+%H:%M:%S")] Package [$PKG_NAME] is detected!"
		mv $PKG_NAME package/$PKG_DIR
		break
	else
		[ $Retry_Times -lt 1 ] && echo "[$(date "+%H:%M:%S")] Skip check out package [$PKG_NAME] ..." && break
		echo "[$(date "+%H:%M:%S")] [$Retry_Times] Checkout failed,retry in 3s ..."
		Retry_Times=$(($Retry_Times - 1))
		rm -rf $PKG_NAME > /dev/null 2>&1
		sleep 3
	fi
done
}

mv2() {
if [ -f $GITHUB_WORKSPACE/Customize/$1 ];then
	echo "[$(date "+%H:%M:%S")] Custom File [$1] is detected!"
	if [ -z $2 ];then
		Patch_Dir=$GITHUB_WORKSPACE/openwrt
	else
		Patch_Dir=$GITHUB_WORKSPACE/openwrt/$2
	fi
	[ ! -d $Patch_Dir ] && mkdir -p $Patch_Dir
	if [ -z $3 ];then
		[ -f $Patch_Dir/$1 ] && rm -f $Patch_Dir/$1 > /dev/null 2>&1
		mv -f $GITHUB_WORKSPACE/Customize/$1 $Patch_Dir/$1
	else
		[ -f $Patch_Dir/$1 ] && rm -f $Patch_Dir/$3 > /dev/null 2>&1
		mv -f $GITHUB_WORKSPACE/Customize/$1 $Patch_Dir/$3
	fi
else
	echo "[$(date "+%H:%M:%S")] Custom File [$1] is not detected!"
fi
}

GET_INFO() {
Diy_Core
cd $GITHUB_WORKSPACE/openwrt
AutoUpdate_Version=$(awk 'NR==6' package/base-files/files/bin/AutoUpdate.sh | awk -F '[="]+' '/Version/{print $2}')
Compile_Date=$(date +'%Y/%m/%d')
Default_File="package/lean/default-settings/files/zzz-default-settings"
Lede_Version=$(egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" $Default_File)
Openwrt_Version="$Lede_Version-`date +%Y%m%d`"
TARGET_PROFILE=$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/')
[ -z "$TARGET_PROFILE" ] && TARGET_PROFILE="$Default_Device"
TARGET_BOARD=$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' .config)
TARGET_SUBTARGET=$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' .config)
echo "$Author" >> $GITHUB_ENV
echo "$Default_Device" >> $GITHUB_ENV
echo "$AutoUpdate_Version" >> $GITHUB_ENV
echo "$Compile_Date" >> $GITHUB_ENV
echo "$Default_File" >> $GITHUB_ENV
echo "$Lede_Version" >> $GITHUB_ENV
echo "$Openwrt_Version" >> $GITHUB_ENV
echo "$TARGET_PROFILE=$(date +"%Y%m%d%H%M")" >> $GITHUB_ENV
echo "$TARGET_BOARD" >> $GITHUB_ENV
echo "$TARGET_SUBTARGET" >> $GITHUB_ENV
}
