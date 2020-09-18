#!/bin/bash
# AutoBuild Script Module by Hyy2001
# AutoUpdate

Version=V2.0
Updated=2020.09.09

Github=https://github.com/Hyy2001X/Openwrt-AutoUpdate
Github_Release=$Github/releases/tag/AutoUpdate
Github_Download=$Github/releases/download/AutoUpdate

clear
if [ ! -f /etc/openwrt_date ];then
	echo "AutoUpdate 不兼容当前固件!"
	exit
fi
echo -e "Auto-Update Script $Version by Hyy2001\n"
CURRENT_VERSION=`cat /etc/openwrt_date`
if [ "$CURRENT_VERSION" == "" ]; then
	echo -e "警告:当前固件信息获取失败!\n"
	CURRENT_VERSION=未知
fi
cd /tmp
echo "正在获取云端固件信息..."
Check_Version=`wget --no-check-certificate -q $Github_Release -O - | egrep -o 'R[0-9]+.[0-9]+.[0-9]+.[0-9]+.bin' | awk 'NR==1'`
if [ "$Check_Version" == "" ]; then
	echo -e "\n...未获取到任何信息,请稍后重试!"
	exit
fi
GET_Version=`wget --no-check-certificate -q $Github_Release -O - | egrep -o 'R[0-9]+.[0-9]+.[0-9]+.[0-9]+' | awk 'NR==1'`
if [ "$GET_Version" == "" ]; then
	echo -e "\n...云端固件信息获取失败!"
	exit
fi
echo -e "\n当前固件版本:$CURRENT_VERSION"
echo -e "云端固件版本:$GET_Version\n"
if [ $CURRENT_VERSION == $GET_Version ];then
	read -p "已是最新版本,是否强制更新固件?[Y/N]:" Choose
	case $Choose in
	Y)
		echo -e "\n开始强制更新固件...\n"
	;;
	N)
		exit
	;;
	*)
		echo -e "\n选择错误,请重试!"
		exit
	esac
fi
Firmware_Info=AutoBuild-d-team_newifi-d2-Lede-$GET_Version
Firmware=${Firmware_Info}.bin
Firmware_Detail=${Firmware_Info}.detail
echo "云端固件名称:$Firmware"
echo -e "\n正在下载云端固件..."
wget --no-check-certificate -q $Github_Download/$Firmware -O $Firmware
if [ ! "$?" == 0 ]; then
	echo "...下载失败,请重试!"
	exit
fi
echo "...下载成功!"
echo "固件大小:$(du -h $Firmware | awk '{print $1}')"
echo -e "\n正在下载固件详细信息..."
wget --no-check-certificate -q $Github_Download/$Firmware_Detail -O $Firmware_Detail
if [ ! "$?" == 0 ]; then
	echo "...下载失败,请重试!"
	exit
fi
echo "...下载成功!"
GET_MD5=`awk -F'[ :]' '/MD5/ {print $2;exit}' $Firmware_Detail`
CURRENT_MD5=`md5sum $Firmware | cut -d ' ' -f1`
echo -e "\n当前文件MD5:$CURRENT_MD5"
echo -e "云端文件MD5:$GET_MD5\n"
if [ "$GET_MD5" == "" ] || [ "$CURRENT_MD5" == "" ];then
	echo "MD5获取失败!"
	exit
fi
if [ ! "$GET_MD5" == "$CURRENT_MD5" ];then
	echo "MD5对比失败,请重新下载固件!"
	exit
fi
echo "MD5对比通过,准备升级固件..."
sleep 3
echo -e "\n开始升级固件,请耐心等待...\n"
sysupgrade $Firmware
