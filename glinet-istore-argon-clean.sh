#!/bin/sh
set -u

red()    { printf '\033[31m\033[01m%s\033[0m\n' "$1"; }
green()  { printf '\033[32m\033[01m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m\033[01m%s\033[0m\n' "$1"; }

green "==> [1/5] 检查 curl"
if ! command -v curl >/dev/null 2>&1; then
	opkg update && opkg install curl || { red "curl 安装失败，请检查网络/软件源"; exit 1; }
fi

green "==> [2/5] 安装 iStore（官方 istore.istoreos.com）"
ISTORE_REPO="https://istore.istoreos.com/repo/all/store"
FCURL="curl -fsSL --connect-timeout 20"

IPK=$($FCURL "$ISTORE_REPO/Packages.gz" | zcat | \
      grep -m1 '^Filename: luci-app-store.*\.ipk$' | \
      sed -n 's/^Filename: \(.*\)$/\1/p')
[ -n "$IPK" ] || { red "无法获取 iStore 包列表，检查网络是否能访问 istore.istoreos.com"; exit 1; }

$FCURL "$ISTORE_REPO/$IPK" | tar -xzO ./data.tar.gz | tar -xzO ./bin/is-opkg >/tmp/is-opkg
[ -s /tmp/is-opkg ] || { red "iStore 核心(is-opkg)下载失败"; exit 1; }
chmod 755 /tmp/is-opkg

/tmp/is-opkg update
/tmp/is-opkg install --force-reinstall luci-lib-taskd luci-lib-xterm
/tmp/is-opkg install --force-reinstall luci-app-store || { red "iStore 安装失败"; exit 1; }
[ -s /etc/init.d/tasks ]            || /tmp/is-opkg install --force-reinstall taskd
[ -s /usr/lib/lua/luci/cbi.lua ]    || /tmp/is-opkg install luci-compat >/dev/null 2>&1
green "    iStore 安装完成"

ISOPKG=/tmp/is-opkg
[ -x /bin/is-opkg ] && ISOPKG=/bin/is-opkg
$ISOPKG update

green "==> [3/5] 安装 iStore 风格应用（官方 iStore 源，全部为本地服务）"
$ISOPKG install luci-app-quickstart luci-i18n-quickstart-zh-cn --force-depends
opkg update
opkg install openssh-sftp-server
yellow "    已跳过 ddnsto / 磁盘管理(app-meta-diskman) / iStore 的 SFTP 壳子(app-meta-sftp) 等组件"

green "==> [4/5] 安装 Argon 主题（官方 jerrykuku 仓库）"

if opkg list-installed 2>/dev/null | grep -q '^luci-theme-argon-master '; then
	yellow "    检测到冲突主题包 luci-theme-argon-master，先卸载以腾出文件占用"
	opkg remove luci-theme-argon-master 2>/dev/null
fi

ARGON_VERSION="2.4.7"
ARGON_BASE="https://github.com/jerrykuku/luci-theme-argon/releases/download/v$ARGON_VERSION"
ARGON_URL="$ARGON_BASE/luci-theme-argon_${ARGON_VERSION}_all.ipk"
ARGONCFG_URL="$ARGON_BASE/luci-app-argon-config_${ARGON_VERSION}_all.ipk"

ARGON_OK=0
if $FCURL -o /tmp/luci-theme-argon.ipk "$ARGON_URL" && \
   $FCURL -o /tmp/luci-app-argon-config.ipk "$ARGONCFG_URL"; then
	if opkg install /tmp/luci-theme-argon.ipk /tmp/luci-app-argon-config.ipk; then
		ARGON_OK=1
	elif opkg install --force-overwrite /tmp/luci-theme-argon.ipk /tmp/luci-app-argon-config.ipk; then
		ARGON_OK=1
	fi
else
	red "    GitHub 下载失败（国内常见）。两种处理方式："
	yellow "      1) 让路由器本机流量走你的代理后重跑本脚本；"
	yellow "      2) 在电脑上复制以下直链下载，再通过 LuCI 上传安装："
	yellow "         $ARGON_URL"
	yellow "         $ARGONCFG_URL"
fi

if [ "$ARGON_OK" = "1" ] && opkg list-installed 2>/dev/null | grep -q '^luci-theme-argon '; then
	green "    Argon 主题安装成功：$(opkg list-installed | grep '^luci-theme-argon ')"
else
	red "    Argon 主题安装失败！请查看上方 opkg 报错。"
	yellow "    多为仍有其它包占用 argon 主题文件，可手动排查："
	yellow "      opkg list-installed | grep argon"
	yellow "      opkg remove <冲突包名> && opkg install /tmp/luci-theme-argon.ipk"
fi

green "==> [5/5] 应用主题与时区"
if opkg list-installed 2>/dev/null | grep -q '^luci-theme-argon '; then
	uci set luci.main.mediaurlbase='/luci-static/argon'
else
	yellow "    未检测到 argon 主题，跳过主题切换（保持当前主题）"
fi
uci set luci.main.lang='zh_cn'
uci commit luci
uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
uci commit system
/etc/init.d/system reload >/dev/null 2>&1

green "================ 全部完成 ================"
yellow "本脚本相对常见一键脚本的区别（即未做的事）："
yellow "  - 未改 WAN 防火墙（保持你原本的 input 策略）"
yellow "  - 未安装 ddnsto 等云端远程访问组件"
yellow "  - 未劫持 time.android.com 的 DNS"
yellow "  - 主题来自官方 jerrykuku，iStore 来自官方 iStoreOS"
green "请退出并重新登录 LuCI 查看 Argon 主题。"
green "iStore 风格首页： http://<你的路由器IP>:8080"
