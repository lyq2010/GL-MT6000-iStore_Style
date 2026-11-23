#!/bin/sh
set -u
umask 077

fail() { printf '错误：%s\n' "$*" >&2; exit 1; }
step() { printf '\n==> %s\n' "$*"; }

[ "$#" -eq 0 ] || fail '此脚本不接受参数。'
[ "$(id -u)" = 0 ] || fail '请通过 SSH 以 root 身份运行。'
[ -s /rom/etc/glversion ] || fail '未找到 GL.iNet 原厂固件标记。'
case "$(cat /rom/etc/glversion)" in
    4.*-op25) ;;
    *) fail '需要 GL.iNet 官方 OP25 固件。' ;;
esac
[ -r /tmp/sysinfo/board_name ] || fail '无法读取设备型号。'
case "$(cat /tmp/sysinfo/board_name)" in
    glinet,gl-mt6000|glinet,mt6000) ;;
    *) fail '此脚本仅用于 GL.iNet GL-MT6000。' ;;
esac
release=$(sed -n "s/^DISTRIB_RELEASE='\([^']*\)'$/\1/p" /rom/etc/openwrt_release) || fail '无法读取原厂 OpenWrt 版本。'
case "$release" in
    25.12|25.12.*|25.12-*) ;;
    *) fail "不是 OpenWrt 25.12（检测到：${release:-未知}）；OP24 请用原脚本。" ;;
esac
command -v apk >/dev/null 2>&1 || fail '未找到原生 APK 包管理器。'
apk_version=$(APK_CONFIG=/dev/null apk --version) || fail '无法读取 APK 版本。'
case "$apk_version" in
    'apk-tools 3.'*) ;;
    *) fail '需要原生 apk-tools 3.x。' ;;
esac
[ -s /etc/apk/arch ] && [ ! -L /etc/apk/arch ] || fail '未找到原生 APK 架构列表。'
IFS= read -r arch < /etc/apk/arch || fail '无法读取原生 APK 架构。'
[ "$arch" = aarch64_cortex-a53 ] || fail "不支持的 APK 主架构：$arch。"
command -v uci >/dev/null 2>&1 || fail '找不到 uci。'
command -v sha256sum >/dev/null 2>&1 || fail '找不到 sha256sum。'
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    fail '需要固件自带 wget 或 curl 下载 Outline。'
fi

check_uci() {
    uci -q get 'system.@system[0]' >/dev/null || fail '未找到标准系统配置，请先完成固件首次启动。'
    if [ "$1" = ready ]; then
        uci -q get luci.main >/dev/null || fail '未找到标准 LuCI 配置，停止设置主题。'
    fi
    for config in luci system outline uhttpd; do
        [ -f "/etc/config/$config" ] || continue
        pending=$(uci -q changes "$config") || fail "无法检查 $config 的待提交配置。"
        [ -z "$pending" ] || fail "$config 有待提交改动，请先保存或撤销。"
    done
}
check_uci first

work=$(mktemp -d /tmp/glinet-istore-op25.XXXXXX) || fail '无法创建临时工作目录。'
cleanup() {
    status=$?
    rm -rf "$work"
    return "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

# Read the original firmware's feed/key files. Do not use overlay custom feeds
# or inherit global APK options (which can disable trust checks).
mkdir "$work/native-keys" "$work/istore-keys" "$work/native-cache" "$work/istore-cache" "$work/uci" ||
    fail '无法创建临时目录。'
native_repos="$work/native.list"
: > "$native_repos" || fail '无法写入临时软件源文件。'
[ ! -f /rom/etc/apk/repositories ] ||
    { cat /rom/etc/apk/repositories && printf '\n'; } >> "$native_repos" ||
    fail '无法读取原厂软件源。'
for dir in /rom/etc/apk/repositories.d /rom/lib/apk/repositories.d; do
    for feed in "$dir"/*.list; do
        [ -f "$feed" ] || continue
        if [ "$dir" = /rom/lib/apk/repositories.d ] &&
            [ -f "/rom/etc/apk/repositories.d/${feed##*/}" ]; then
            continue
        fi
        { cat "$feed" && printf '\n'; } >> "$native_repos" || fail '无法读取原厂软件源。'
    done
done
[ -s "$native_repos" ] || fail '未找到原厂 APK 软件源。'
for dir in /rom/lib/apk/keys /rom/etc/apk/keys; do
    for key in "$dir"/*; do
        [ -f "$key" ] || continue
        cp "$key" "$work/native-keys/" || fail '无法复制原厂 APK 公钥。'
    done
done
set -- "$work/native-keys/"*
[ -f "$1" ] || fail '未找到原厂 APK 公钥。'
cp "$@" "$work/istore-keys/" || fail '无法准备 iStore 校验目录。'
# iStore's official APK public key, pinned from:
# https://github.com/istoreos/istore/blob/a97ace34f2da358a015b094d326bba2697697f2e/luci/luci-app-store/src/root-apk/etc/apk/keys/istore.pem
cat > "$work/istore-keys/istore.pem" <<'KEY' || fail '无法写入 iStore 临时公钥。'
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEybK5eaXsrK06Thc1dbA3FC45Tlp8
8X5Z831vU6JggiV6tJiwI/B05IsdklTaZE8SYh0XCHcnXSjzRMLtarBisg==
-----END PUBLIC KEY-----
KEY

native_apk() {
    APK_CONFIG=/dev/null apk --repositories-file "$native_repos" \
        --keys-dir "$work/native-keys" --cache-dir "$work/native-cache" "$@"
}
istore_apk() {
    # These are the direct ADB indexes in the official iStore native APK feeds.
    # Do not call is-opkg update: keep bootstrap key/repository options transaction-local.
    base=https://istore.istoreos.com/repo-apk
    APK_CONFIG=/dev/null apk --repositories-file "$native_repos" \
        --keys-dir "$work/istore-keys" --cache-dir "$work/istore-cache" \
        --repository "$base/aarch64_generic/nas/packages.adb" \
        --repository "$base/all/nas_luci/packages.adb" \
        --repository "$base/all/store/packages.adb" \
        --repository "$base/all/meta/packages.adb" \
        --repository "$base/all/compat/packages.adb" "$@"
}
offline_apk() {
    APK_CONFIG=/dev/null apk --network=no --cache=no --repositories-file /dev/null "$@"
}

native_packages() {
    native_apk "$@" openssh-sftp-server luci-mod-admin-full luci-i18n-base-zh-cn \
        luci-app-firewall luci-i18n-firewall-zh-cn luci-app-package-manager luci-i18n-package-manager-zh-cn \
        luci-proto-ppp luci-proto-ipv6 rpcd-mod-rrdns luci-theme-bootstrap \
        rpcd-mod-ucode ucode-mod-fs ucode-mod-uci uclient-fetch jsonfilter
}

outline_pkg=luci-theme-outline
outline_version=1.5.0-r20261120
outline_file="$outline_pkg-$outline_version.apk"
outline_url="https://github.com/tickcount/luci-theme-outline/releases/download/v1.5.0/$outline_file"
outline_sha=018bc0ff1c220adf44cfa2dc20ca51e7ab49aa582b4d520e581e156750befe57
outline_needed=1
if offline_apk info -e "$outline_pkg>$outline_version" >/dev/null 2>&1; then
    outline_needed=0
    step '保留已经安装的较新 Outline，不降级'
elif [ -e /etc/outline ] || [ -L /etc/outline ]; then
    fail '检测到旧版 Outline 数据 /etc/outline。新主题安装钩子会删除此目录；请先备份并移走，再重试。'
fi

step '检查原厂及 iStore APK 软件源和依赖'
native_apk update || fail '原厂 APK 软件源更新失败；不会继续安装。'
native_packages add --simulate || fail '原厂软件源无法解析 LuCI、SFTP 或 Outline 依赖。'
set -- luci-lib-taskd luci-lib-xterm taskd luci-app-store
# QuickStart 暂停安装；保留 iStore 商店。
# set -- "$@" luci-app-quickstart luci-i18n-quickstart-zh-cn
[ -s /usr/lib/lua/luci/cbi.lua ] || set -- "$@" luci-compat
istore_apk update || fail 'iStore APK 软件源更新或签名校验失败。'

if [ "$outline_needed" -eq 1 ]; then
    step '下载并校验官方 Outline APK'
    if command -v curl >/dev/null 2>&1; then
        curl -fLsS --proto '=https' --proto-redir '=https' --connect-timeout 20 --max-time 120 -o "$work/$outline_file" "$outline_url" ||
            fail "下载 Outline 失败：$outline_url"
    else
        wget -T 30 -O "$work/$outline_file" "$outline_url" || fail "下载 Outline 失败：$outline_url"
    fi
    printf '%s  %s\n' "$outline_sha" "$work/$outline_file" | sha256sum -c - >/dev/null ||
        fail 'Outline APK 的 SHA-256 与官方发行记录不符。'
fi

istore_apk add --simulate "$@" || fail 'iStore 依赖预检失败；不会强行安装。'

step '补齐标准 LuCI，并安装 SFTP 与 iStore'
native_packages add || fail '安装原厂 LuCI 或 SFTP 组件失败。'
istore_apk add "$@" || fail '安装 iStore 失败。'
for pkg in "$@" openssh-sftp-server luci-mod-admin-full luci-mod-system luci-mod-status luci-mod-network \
    luci-i18n-base-zh-cn luci-app-firewall luci-i18n-firewall-zh-cn luci-app-package-manager luci-i18n-package-manager-zh-cn \
    luci-proto-ppp luci-proto-ipv6 rpcd-mod-rrdns luci-theme-bootstrap; do
    offline_apk info -e "$pkg" >/dev/null 2>&1 || fail "未确认 $pkg 已安装。"
done

if [ "$outline_needed" -eq 1 ]; then
    step '离线安装已校验的 Outline APK'
    check_uci ready
    # Preseed the upstream install hook's auto-update choice only when unset.
    # A pinned install must not add a cron job; preserve explicit choices.
    if [ -z "$(uci -q get outline.updates.auto)" ]; then
        [ ! -L /etc/config/outline ] || fail 'Outline 配置是符号链接，停止。'
        if [ ! -f /etc/config/outline ]; then
            [ ! -e /etc/config/outline ] && : > /etc/config/outline || fail '无法创建 Outline 配置。'
        fi
        if ! uci -q get outline.updates >/dev/null; then
            uci -t "$work/uci" set 'outline.updates=updates' || fail '无法准备 Outline 更新设置。'
        fi
        uci -t "$work/uci" set 'outline.updates.auto=0' || fail '无法关闭 Outline 默认自动更新。'
        uci -t "$work/uci" commit outline || fail '无法提交 Outline 更新设置。'
        [ "$(uci -q get outline.updates.auto)" = 0 ] || fail '未确认 Outline 默认自动更新已关闭。'
    fi
    # Only the pinned, SHA-256-verified local APK can use this offline exception.
    offline_apk add --allow-untrusted "$work/$outline_file" || fail '安装 Outline 失败，停止后续设置。'
    outline_installed="$outline_pkg=$outline_version"
else
    outline_installed="$outline_pkg>$outline_version"
fi
offline_apk info -e "$outline_installed" >/dev/null 2>&1 && [ -d /www/luci-static/outline ] ||
    fail '未确认 Outline 主题已正确安装。'

step '应用 LuCI 主题、中文与时区'
check_uci ready
uci -t "$work/uci" set 'luci.themes.Outline=/luci-static/outline' || fail '注册 Outline 主题失败。'
uci -t "$work/uci" set 'luci.main.mediaurlbase=/luci-static/outline' || fail '设置 LuCI 主题失败。'
uci -t "$work/uci" set 'luci.main.lang=zh_cn' || fail '设置 LuCI 语言失败。'
uci -t "$work/uci" set 'system.@system[0].zonename=Asia/Shanghai' || fail '设置时区名称失败。'
uci -t "$work/uci" set 'system.@system[0].timezone=CST-8' || fail '设置时区失败。'
uci -t "$work/uci" commit luci || fail '提交 LuCI 配置失败。'
uci -t "$work/uci" commit system || fail '提交时区配置失败。'
[ "$(uci -q get luci.themes.Outline)" = /luci-static/outline ] &&
    [ "$(uci -q get luci.main.mediaurlbase)" = /luci-static/outline ] &&
    [ "$(uci -q get luci.main.lang)" = zh_cn ] &&
    [ "$(uci -q get 'system.@system[0].zonename')" = Asia/Shanghai ] &&
    [ "$(uci -q get 'system.@system[0].timezone')" = CST-8 ] ||
    fail '未确认 LuCI 或时区配置已提交。'
/etc/init.d/rpcd reload || fail 'LuCI 设置已保存，但 RPC 服务重载失败。'
/etc/init.d/system reload || fail '时区已保存，但系统服务重载失败。'
printf '\n安装完成。退出并重新登录 LuCI 查看 Outline，并从 LuCI 菜单打开 iStore。\n'
