#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Actions

Diy_Core() {
Author=Hyy2001

Default_File=./package/lean/default-settings/files/zzz-default-settings
Lede_Version=`egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" $Default_File`
Openwrt_Version="$Lede_Version-`date +%Y%m%d`"
AutoUpdate_Version=`awk 'NR==6' ./package/base-files/files/bin/AutoUpdate.sh | awk -F'[="]+' '/Version/{print $2}'`
Compile_Date=`date +'%Y/%m/%d'`
Compile_Time=`date +'%Y-%m-%d %H:%M:%S'`
TARGET_PROFILE=`egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/'`
}

GET_TARGET_INFO() {
TARGET_BOARD=`awk -F'[="]+' '/TARGET_BOARD/{print $2}' .config`
TARGET_SUBTARGET=`awk -F'[="]+' '/TARGET_SUBTARGET/{print $2}' .config`
}

ExtraPackages() {
[ -d ./package/lean/$2 ] && rm -rf ./package/lean/$2
[ -d ./$2 ] && rm -rf ./$2
Retry_Times=3
while [ ! -f $2/Makefile ]
do
	echo "[$(date "+%H:%M:%S")] Checking out $2 from $3 ..."
	if [ $1 == git ];then
		git clone -b $4 $3/$2 $2 > /dev/null 2>&1
	else
		svn checkout $3/$2 $2 > /dev/null 2>&1
	fi
	if [ -f $2/Makefile ] || [ -f $2/README* ];then
		echo "[$(date "+%H:%M:%S")] Package $2 detected!"
		case $2 in
		OpenClash)
			mv -f ./$2/luci-app-openclash ./package/lean
		;;
		openwrt-OpenAppFilter)
			mv -f ./$2 ./package/lean
		;;
		*)
			mv -f ./$2 ./package/lean
		esac
		rm -rf ./$2 > /dev/null 2>&1
		break
	else
		[ $Retry_Times -lt 1 ] && echo "[$(date "+%H:%M:%S")] Skip check out package $1 ..." && break
		echo "[$(date "+%H:%M:%S")] [$Retry_Times]Checkout failed,retry in 3s ..."
		Retry_Times=$(($Retry_Times - 1))
		rm -rf ./$2 > /dev/null 2>&1
		sleep 3
	fi
done
}

mv2() {
if [ -f $GITHUB_WORKSPACE/Customize/$1 ];then
	if [ ! -d ./$2 ];then
		echo "[$(date "+%H:%M:%S")] Creating new folder $2 ..."
		mkdir ./$2
	fi
	[ -f ./$2/$1 ] && rm -f ./$2/$1
	echo "[$(date "+%H:%M:%S")] Moving Customize/$1 to $2 ..."
	mv -f $GITHUB_WORKSPACE/Customize/$1 ./$2/$1
else
	echo "[$(date "+%H:%M:%S")] No $1 file detected!"
fi
}

Diy-Part1() {
sed -i "s/#src-git helloworld/src-git helloworld/g" feeds.conf.default
[ ! -d ./package/lean ] && mkdir ./package/lean

mv2 mac80211.sh package/kernel/mac80211/files/lib/wifi
mv2 system package/base-files/files/etc/config
mv2 AutoUpdate.sh package/base-files/files/bin
mv2 firewall.config package/network/config/firewall/files
mv2 banner package/base-files/files/etc

ExtraPackages git luci-app-autoupdate https://github.com/Hyy2001X main
ExtraPackages git luci-theme-argon https://github.com/jerrykuku 18.06
#ExtraPackages svn luci-theme-opentomato https://github.com/kenzok8/openwrt-packages/trunk
#ExtraPackages svn luci-theme-opentomcat https://github.com/kenzok8/openwrt-packages/trunk
#ExtraPackages svn luci-app-adguardhome https://github.com/Lienol/openwrt/trunk/package/diy
ExtraPackages git luci-app-adguardhome https://github.com/Hyy2001X master
ExtraPackages svn luci-app-smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages svn smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages git OpenClash https://github.com/vernesong master
#ExtraPackages git openwrt-OpenAppFilter https://github.com/Lienol master
ExtraPackages git luci-app-serverchan https://github.com/tty228 master
ExtraPackages svn luci-app-socat https://github.com/xiaorouji/openwrt-package/trunk/lienol
}

Diy-Part2() {
mv2 mwan3 package/feeds/packages/mwan3/files/etc
echo "Author: $Author"
echo "Openwrt Version: $Openwrt_Version"
echo "AutoUpdate Version: $AutoUpdate_Version"
echo "Device: $TARGET_PROFILE"
sed -i "s?$Lede_Version?$Lede_Version Compiled by $Author [$Compile_Date]?g" $Default_File
echo "$Openwrt_Version" > ./package/base-files/files/etc/openwrt_info
sed -i "s?Openwrt?Openwrt $Openwrt_Version / AutoUpdate $AutoUpdate_Version?g" ./package/base-files/files/etc/banner
}

Diy-Part3() {
GET_TARGET_INFO
Default_Firmware=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-squashfs-sysupgrade.bin
AutoBuild_Firmware=AutoBuild-$TARGET_PROFILE-Lede-${Openwrt_Version}.bin
AutoBuild_Detail=AutoBuild-$TARGET_PROFILE-Lede-${Openwrt_Version}.detail
mkdir -p ./bin/Firmware
echo "[$(date "+%H:%M:%S")] Moving $Default_Firmware to /bin/Firmware/$AutoBuild_Firmware ..."
mv ./bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$Default_Firmware ./bin/Firmware/$AutoBuild_Firmware
echo "[$(date "+%H:%M:%S")] Calculating MD5 and SHA256 ..."
Firmware_MD5=`md5sum ./bin/Firmware/$AutoBuild_Firmware | cut -d ' ' -f1`
Firmware_SHA256=`sha256sum ./bin/Firmware/$AutoBuild_Firmware | cut -d ' ' -f1`
echo "编译日期:$Compile_Time" > ./bin/Firmware/$AutoBuild_Detail
echo -e "\nMD5:$Firmware_MD5\nSHA256:$Firmware_SHA256" >> ./bin/Firmware/$AutoBuild_Detail
}
