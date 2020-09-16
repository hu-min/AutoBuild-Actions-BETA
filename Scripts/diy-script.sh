#!/bin/bash
# AutoBuild Script Module by Hyy2001
# AutoBuild Actions

Diy_Core() {
Author=Hyy2001
AutoUpdate_Github=https://github.com/Hyy2001X/Openwrt-AutoUpdate
TARGET_BOARD=ramips
TARGET_SUBTARGET=mt7621
TARGET_PROFILE=d-team_newifi-d2
}

ExtraPackages() {
[ -d ./package/lean/$2 ] && rm -rf ./package/lean/$2
[ -d ./$2 ] && rm -rf ./$2
while [ ! -f $2/Makefile ]
do
	echo "Checking out $2 from $3 ..."
	if [ $1 == git ];then
		git clone -b $4 $3/$2 $2 > /dev/null 2>&1
	else
		svn checkout $3/$2 $2 > /dev/null 2>&1
	fi
	if [ ! -f $2/Makefile ];then
		echo "Checkout failed,retry in 3s."
		rm -rf $2 > /dev/null 2>&1
		sleep 3
	fi
done
echo "Package $2 detected!"
mv $2 ./package/lean
}

Diy-Part1() {
sed -i "s/#src-git helloworld/src-git helloworld/g" feeds.conf.default
ExtraPackages git luci-theme-argon https://github.com/jerrykuku 18.06
ExtraPackages svn luci-app-openclash https://github.com/vernesong/OpenClash/trunk
ExtraPackages svn luci-app-adguardhome https://github.com/Lienol/openwrt/trunk/package/diy
ExtraPackages svn luci-app-smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages svn smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
[ -d ./Openwrt-AutoUpdate ] && rm -rf ./Openwrt-AutoUpdate
git clone -b master $AutoUpdate_Github
mv Openwrt-AutoUpdate/AutoUpdate.sh ./package/base-files/files/bin
}

Diy-Part2() {
Date=`date +%Y/%m/%d`
DefaultFile=./package/lean/default-settings/files/zzz-default-settings
Version=`egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" $DefaultFile`
#Openwrt 主界面显示作者、编译日期
if [ ! $(grep -o "Compiled by $Author" $DefaultFile | wc -l) = "1" ];then
	sed -i "s?$Version?$Version Compiled by $Author [$Date]?g" $DefaultFile
fi
Old_Date=`egrep -o "[0-9]+\/[0-9]+\/[0-9]+" $DefaultFile`
if [ ! $Date == $Old_Date ];then
	sed -i "s?$Old_Date?$Date?g" $DefaultFile
fi
echo "$Version-`date +%Y%m%d`" > ./package/base-files/files/etc/openwrt_date
}

Diy-Part3() {
Compile_Time=`date +'%Y-%m-%d %H:%M:%S'`
Version=`egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" ./package/lean/default-settings/files/zzz-default-settings`
Default_Firmware=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-squashfs-sysupgrade.bin
AutoBuild_Firmware=AutoBuild-$TARGET_PROFILE-Lede-$Version`(date +-%Y%m%d.bin)`
AutoBuild_Detail=AutoBuild-$TARGET_PROFILE-Lede-$Version`(date +-%Y%m%d.detail)`

mkdir -p ./bin/Firmware
mv ./bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$Default_Firmware ./bin/Firmware/$AutoBuild_Firmware
cd ./bin/Firmware
Firmware_Size=`ls -l $AutoBuild_Firmware | awk '{print $5}'`
Firmware_Size_MB=`awk 'BEGIN{printf "固件大小:%.2fMB\n",'$((Firmware_Size))'/1000000}'`
Firmware_MD5=`md5sum $AutoBuild_Firmware | cut -d ' ' -f1`
Firmware_SHA256=`sha256sum $AutoBuild_Firmware | cut -d ' ' -f1`
echo "$Firmware_Size_MB" > ./$AutoBuild_Detail
echo -e "编译日期:$Compile_Time\n" >> ./$AutoBuild_Detail
echo -e "MD5:$Firmware_MD5\nSHA256:$Firmware_SHA256" >> ./$AutoBuild_Detail
cd ../..
}
