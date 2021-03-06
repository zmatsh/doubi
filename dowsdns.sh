#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: DowsDNS
#	Version: 1.0.0
#	Author: Toyo
#	Blog: https://doub.io/dowsdns-jc3/
#=================================================

sh_ver="1.0.0"
file="/usr/local/dowsDNS"
dowsdns_conf="/usr/local/dowsDNS/conf/config.json"
dowsdns_data="/usr/local/dowsDNS/conf/data.json"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${file} ]] && echo -e "${Error} DowsDNS 没有安装，请检查 !" && exit 1
}
check_pid(){
	PID=`ps -ef| grep "bin/dns.py"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
Download_dowsdns(){
	cd "/usr/local"
	wget -N --no-check-certificate https://github.com/dowsnature/dowsDNS/archive/master.zip
	[[ ! -e "master.zip" ]] && echo -e "${Error} DowsDNS 下载失败 !" && exit 1
	unzip master.zip && rm -rf master.zip
	[[ ! -e "dowsDNS-master" ]] && echo -e "${Error} DowsDNS 解压失败 !" && exit 1
	mv dowsDNS-master dowsDNS
	[[ ! -e "dowsDNS" ]] && echo -e "${Error} DowsDNS 文件夹重命名失败 !" && rm -rf dowsDNS-master && exit 1
}
Service_dowsdns(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/dowsdns_centos -O /etc/init.d/dowsdns; then
			echo -e "${Error} DowsDNS 服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/dowsdns
		chkconfig --add dowsdns
		chkconfig dowsdns on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/dowsdns_debian -O /etc/init.d/dowsdns; then
			echo -e "${Error} DowsDNS 服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/dowsdns
		update-rc.d -f dowsdns defaults
	fi
	echo -e "${Info} DowsDNS 服务管理脚本下载完成 !"
}
Installation_dependency(){
	python_status=$(python --help)
	if [[ ${release} == "centos" ]]; then
		yum update
		if [[ -z ${python_status} ]]; then
			yum install -y python unzip
		else
			yum install -y unzip
		fi
	else
		apt-get update
		if [[ -z ${python_status} ]]; then
			apt-get install -y python unzip
		else
			apt-get install -y unzip
		fi
	fi
}
Write_config(){
	cat > ${dowsdns_conf}<<-EOF
{
	"Remote_dns_server":"${dd_remote_dns_server}",
	"Remote_dns_port":${dd_remote_dns_port},
	"Rpz_json_path":"./data/rpz.json",
	"Local_dns_server":"${dd_local_dns_server}",
	"Local_dns_port":${dd_local_dns_port},
	"sni_proxy_on":true,
	"sni_proxy_ip":"${dd_sni_proxy_ip}"
}
EOF
}
Read_config(){
	[[ ! -e ${dowsdns_conf} ]] && echo -e "${Error} DowsDNS 配置文件不存在 !" && exit 1
	remote_dns_server=`cat ${dowsdns_conf}|grep "Remote_dns_server"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/'`
	remote_dns_port=`cat ${dowsdns_conf}|grep "Remote_dns_port"|sed -r 's/.*:(.+),.*/\1/'`
	local_dns_server=`cat ${dowsdns_conf}|grep "Local_dns_server"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/'`
	local_dns_port=`cat ${dowsdns_conf}|grep "Local_dns_port"|sed -r 's/.*:(.+),.*/\1/'`
	sni_proxy_ip=`cat ${dowsdns_conf}|grep "sni_proxy_ip"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/'`
}
Set_remote_dns_server(){
	echo "请输入 DowsDNS 远程(上游)DNS解析服务器IP"
	stty erase '^H' && read -p "(默认: 114.114.114.114):" dd_remote_dns_server
	[[ -z "${dd_remote_dns_server}" ]] && dd_remote_dns_server="114.114.114.114"
	echo
}
Set_remote_dns_port(){
	while true
		do
		echo -e "请输入 DowsDNS 远程(上游)DNS解析服务器端口 [1-65535]"
		stty erase '^H' && read -p "(默认: 53):" dd_remote_dns_port
		[[ -z "$dd_remote_dns_port" ]] && dd_remote_dns_port="53"
		expr ${dd_remote_dns_port} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${dd_remote_dns_port} -ge 1 ]] && [[ ${dd_remote_dns_port} -le 65535 ]]; then
				echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
		done
}
Set_remote_dns(){
	echo -e "请选择并输入 DowsDNS 的远程(上游)DNS解析服务器
 说明：即一些DowsDNS没有指定的域名都由上游DNS解析，比如百度啥的。
 
 ${Green_font_prefix}1.${Font_color_suffix} 114.114.114.114 53
 ${Green_font_prefix}2.${Font_color_suffix} 8.8.8.8 53
 ${Green_font_prefix}3.${Font_color_suffix} 208.67.222.222 53
 ${Green_font_prefix}4.${Font_color_suffix} 208.67.222.222 5353
 ${Green_font_prefix}5.${Font_color_suffix} 自定义输入" && echo
	stty erase '^H' && read -p "(默认: 1. 114.114.114.114 53):" dd_remote_dns
	[[ -z "${dd_remote_dns}" ]] && dd_remote_dns="1"
	if [[ ${dd_remote_dns} == "1" ]]; then
		dd_remote_dns_server="114.114.114.114"
		dd_remote_dns_port="53"
	elif [[ ${dd_remote_dns} == "2" ]]; then
		dd_remote_dns_server="8.8.8.8"
		dd_remote_dns_port="53"
	elif [[ ${dd_remote_dns} == "3" ]]; then
		dd_remote_dns_server="208.67.222.222"
		dd_remote_dns_port="53"
	elif [[ ${dd_remote_dns} == "4" ]]; then
		dd_remote_dns_server="208.67.222.222"
		dd_remote_dns_port="5353"
	elif [[ ${dd_remote_dns} == "5" ]]; then
		echo
		Set_remote_dns_server
		Set_remote_dns_port
	else
		dd_remote_dns_server="114.114.114.114"
		dd_remote_dns_port="53"
	fi
	echo && echo "	================================================"
	echo -e "	远程(上游)DNS解析服务器 IP :\t ${Red_background_prefix} ${dd_remote_dns_server} ${Font_color_suffix}
	远程(上游)DNS解析服务器 端口 :\t ${Red_background_prefix} ${dd_remote_dns_port} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_local_dns_server(){
	echo -e "请选择并输入 DowsDNS 的本地监听方式
 ${Green_font_prefix}1.${Font_color_suffix} 127.0.0.1 (只允许本地和局域网设备访问)
 ${Green_font_prefix}2.${Font_color_suffix} 0.0.0.0 (允许外网访问)" && echo
	stty erase '^H' && read -p "(默认: 2. 0.0.0.0):" dd_local_dns_server
	[[ -z "${dd_local_dns_server}" ]] && dd_local_dns_server="2"
	if [[ ${dd_local_dns_server} == "1" ]]; then
		dd_local_dns_server="127.0.0.1"
	elif [[ ${dd_local_dns_server} == "2" ]]; then
		dd_local_dns_server="0.0.0.0"
	else
		dd_local_dns_server="0.0.0.0"
	fi
	echo && echo "	================================================"
	echo -e "	本地监听方式: ${Red_background_prefix} ${dd_local_dns_server} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_local_dns_port(){
	while true
		do
		echo -e "请输入 DowsDNS 监听端口 [1-65535]
 注意：大部分设备是不支持设置 非53端口的DNS服务器的，所以非必须请直接回车默认使用 53端口。" && echo
		stty erase '^H' && read -p "(默认: 53):" dd_local_dns_port
		[[ -z "$dd_local_dns_port" ]] && dd_local_dns_port="53"
		expr ${dd_local_dns_port} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${dd_local_dns_port} -ge 1 ]] && [[ ${dd_local_dns_port} -le 65535 ]]; then
				echo && echo "	================================================"
				echo -e "	监听端口 : ${Red_background_prefix} ${dd_local_dns_port} ${Font_color_suffix}"
				echo "	================================================" && echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
		done
}
Set_sni_proxy_ip(){
	ddd_sni_proxy_ip=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/dowsnature/dowsDNS/master/conf/config.json"|grep "sni_proxy_ip"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/')
	[[ -z ${ddd_sni_proxy_ip} ]] && ddd_sni_proxy_ip="219.76.4.3"
	echo "请输入 DowsDNS SNI代理 IP（如果没有就直接回车）"
	stty erase '^H' && read -p "(默认: ${ddd_sni_proxy_ip}):" dd_sni_proxy_ip
	[[ -z "${dd_sni_proxy_ip}" ]] && dd_sni_proxy_ip="${ddd_sni_proxy_ip}"
	echo && echo "	================================================"
	echo -e "	SNI代理 IP : ${Red_background_prefix} ${dd_sni_proxy_ip} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_conf(){
	Set_remote_dns
	Set_local_dns_server
	Set_local_dns_port
	Set_sni_proxy_ip
}
Set_dowsdns(){
	check_installed_status
	Set_conf
	Read_config
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Restart_dowsdns
}
Install_dowsdns(){
	[[ -e ${file} ]] && echo -e "${Error} 检测到 DowsDNS 已安装 !" && exit 1
	check_sys
	echo -e "${Info} 开始设置 用户配置..."
	Set_conf
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始检测最新版本..."
	check_new_ver
	echo -e "${Info} 开始下载/安装..."
	Download_dowsdns
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_dowsdns
	echo -e "${Info} 开始写入 配置文件..."
	Write_config
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_dowsdns
}
Start_dowsdns(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} DowsDNS 正在运行，请检查 !" && exit 1
	/etc/init.d/dowsdns start
}
Stop_dowsdns(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} DowsDNS 没有运行，请检查 !" && exit 1
	/etc/init.d/dowsdns stop
}
Restart_dowsdns(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/dowsdns stop
	/etc/init.d/dowsdns start
}
Update_dowsdns(){
	check_installed_status
	check_sys
	cd ${file}
	python run.py update
}
Uninstall_dowsdns(){
	check_installed_status
	echo "确定要卸载 DowsDNS ? (y/N)"
	echo
	stty erase '^H' && read -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config
		Del_iptables
		rm -rf ${file} && rm -rf /etc/init.d/dowsdns
		if [[ ${release} = "centos" ]]; then
			chkconfig --del dowsdns
		else
			update-rc.d -f dowsdns remove
		fi
		echo && echo "DowsDNS 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_dowsdns(){
	check_installed_status
	Read_config
	ip=`wget -qO- -t1 -T2 members.3322.org/dyndns/getip`
	[[ -z ${ip} ]] && ip="VPS_IP"
	clear && echo "————————————————" && echo
	echo -e " 请在你的设备中设置DNS服务器为：
 IP : ${Green_font_prefix}${ip}${Font_color_suffix} ,端口 : ${Green_font_prefix}${local_dns_port}${Font_color_suffix}
 
 注意：如果设备中没有 DNS端口设置选项，那么就只能使用默认的 53 端口"
	echo && echo "————————————————"
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${dd_local_dns_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${local_dns_port} -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	elif [[ ${release} == "debian" ]]; then
		iptables-save > /etc/iptables.up.rules
		cat > /etc/network/if-pre-up.d/iptables<<-EOF
#!/bin/bash
/sbin/iptables-restore < /etc/iptables.up.rules
EOF
		chmod +x /etc/network/if-pre-up.d/iptables
	elif [[ ${release} == "ubuntu" ]]; then
		iptables-save > /etc/iptables.up.rules
		echo -e "\npre-up iptables-restore < /etc/iptables.up.rules
post-down iptables-save > /etc/iptables.up.rules" >> /etc/network/interfaces
		chmod +x /etc/network/interfaces
	fi
}
Update_Shell(){
	echo -e "当前版本为 [ ${sh_ver} ]，开始检测最新版本..."
	sh_new_ver=$(wget --no-check-certificate -qO- raw.githubusercontent.com/ToyoDAdoubi/doubi/master/dowsdns.sh|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 检测最新版本失败 !" && exit 0
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "发现新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		stty erase '^H' && read -p "(默认: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/dowsdns.sh && chmod +x dowsdns.sh
			echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !"
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo -e "当前已是最新版本[ ${sh_new_ver} ] !"
	fi
}
echo && echo -e "  DowsDNS 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/dowsdns-jc3 --
  
 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装 DowsDNS
 ${Green_font_prefix}2.${Font_color_suffix} 升级 DowsDNS
 ${Green_font_prefix}3.${Font_color_suffix} 卸载 DowsDNS
————————————
 ${Green_font_prefix}4.${Font_color_suffix} 启动 DowsDNS
 ${Green_font_prefix}5.${Font_color_suffix} 停止 DowsDNS
 ${Green_font_prefix}6.${Font_color_suffix} 重启 DowsDNS
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 设置 DowsDNS 配置
 ${Green_font_prefix}8.${Font_color_suffix} 查看 DowsDNS 信息
————————————" && echo
if [[ -e ${file} ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
stty erase '^H' && read -p " 请输入数字 [0-8]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_dowsdns
	;;
	2)
	Update_dowsdns
	;;
	3)
	Uninstall_dowsdns
	;;
	4)
	Start_dowsdns
	;;
	5)
	Stop_dowsdns
	;;
	6)
	Restart_dowsdns
	;;
	7)
	Set_dowsdns
	;;
	8)
	View_dowsdns
	;;
	*)
	echo "请输入正确数字 [0-8]"
	;;
esac