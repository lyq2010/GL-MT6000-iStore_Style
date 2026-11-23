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
    fail '需要固件自带 wget 或 curl 下载 Argon。'
fi

check_uci() {
    uci -q get 'system.@system[0]' >/dev/null || fail '未找到标准系统配置，请先完成固件首次启动。'
    if [ "$1" = ready ]; then
        uci -q get luci.main >/dev/null || fail '未找到标准 LuCI 配置，停止设置主题。'
    fi
    for config in luci system; do
        [ "$config" != luci ] || [ -f /etc/config/luci ] || continue
        pending=$(uci -q changes "$config") || fail "无法检查 $config 的待提交配置。"
        [ -z "$pending" ] || fail "$config 有待提交改动，请先保存或撤销。"
    done
}
check_uci first

work=$(mktemp -d /tmp/glinet-istore-op25.XXXXXX) || fail '无法创建临时工作目录。'
arch_added=0
istore_started=0
cleanup() {
    status=$?
    if [ "$arch_added" -eq 1 ] && [ "$istore_started" -eq 0 ]; then
        if cmp -s "$work/arch.expected" /etc/apk/arch; then
            cat "$work/arch.original" > /etc/apk/arch ||
                printf '%s\n' '警告：恢复 APK 架构列表失败，请手动检查 /etc/apk/arch。' >&2
        else
            printf '%s\n' '警告：APK 架构列表已被其他进程改动，未覆盖其更改。' >&2
        fi
    elif [ "$status" -ne 0 ] && [ "$istore_started" -eq 1 ]; then
        printf '%s\n' '部分软件包可能已安装，保留 APK 兼容架构；请检查上面的错误后再重试。' >&2
    fi
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

if offline_apk info -e luci-theme-argon-master >/dev/null 2>&1; then
    fail '已安装冲突主题 luci-theme-argon-master。请先备份并手动移除该主题，不会自动覆盖。'
fi
for pkg in luci-theme-argon luci-app-argon-config; do
    if offline_apk info -e "$pkg>2.4.8-r2" >/dev/null 2>&1; then
        fail "已安装 $pkg 的较新版本，本脚本不会降级。"
    fi
done

step '检查原厂及 iStore APK 软件源和依赖'
native_apk update || fail '原厂 APK 软件源更新失败；不会继续安装。'
native_apk add --simulate jsonfilter openssh-sftp-server luci-i18n-base-zh-cn || fail '原厂软件源无法解析 SFTP、LuCI 中文包或 Argon 依赖。'
set -- luci-lib-taskd luci-lib-xterm taskd luci-app-store luci-app-quickstart luci-i18n-quickstart-zh-cn
[ -s /usr/lib/lua/luci/cbi.lua ] || set -- "$@" luci-compat
istore_apk update || fail 'iStore APK 软件源更新或签名校验失败。'

step '下载并校验官方 Argon APK'
argon_base=https://github.com/jerrykuku/luci-theme-argon/releases/download/v2.4.8
theme=luci-theme-argon-2.4.8-r2.apk
theme_config=luci-app-argon-config-2.4.8-r2.apk
theme_lang=luci-i18n-argon-config-zh-cn-26.281.11209.9bafffa.apk
download() {
    if command -v curl >/dev/null 2>&1; then
        curl -fLsS --proto '=https' --proto-redir '=https' --connect-timeout 20 --max-time 120 -o "$2" "$1"
    else
        wget -T 30 -O "$2" "$1"
    fi
}
fetch_argon() {
    download "$argon_base/$1" "$work/$1" || fail "下载 $1 失败：$argon_base/$1"
    printf '%s  %s\n' "$2" "$work/$1" | sha256sum -c - >/dev/null ||
        fail "$1 的 SHA-256 与官方发行记录不符。"
}
fetch_argon "$theme" fc93eaf211c34435ad44347c66f51a6158ed3f7c009b1b17943635ae15e87f69
fetch_argon "$theme_config" eca59b62ed78b1aa2228d9d3e86b9a05467ba9f519d71ba2519dc626bcc54843
fetch_argon "$theme_lang" 4dbbf226d858390aa7245b5560069293ed9fe44080b5f38c02e77b213dc15e9f

step '检查 QuickStart 兼容架构与 iStore 依赖'
# The official aarch64_cortex-a53/archlist.conf declares aarch64_generic.
# The signed QuickStart backend is aarch64_generic; APK add uses /etc/apk/arch.
if ! grep -Fxq aarch64_generic /etc/apk/arch; then
    cp /etc/apk/arch "$work/arch.original" || fail '无法备份 APK 架构列表。'
    { cat "$work/arch.original" && printf '\naarch64_generic\n'; } > "$work/arch.expected" ||
        fail '无法准备 APK 兼容架构列表。'
    cmp -s "$work/arch.original" /etc/apk/arch || fail 'APK 架构列表被其他进程改动。'
    # Preserve the existing contents and the primary architecture.
    printf '\naarch64_generic\n' >> /etc/apk/arch || fail '无法添加 APK 兼容架构。'
    arch_added=1
fi
istore_apk add --simulate "$@" || fail 'iStore / QuickStart 依赖预检失败；不会强行安装。'

step '安装原厂依赖、SFTP、iStore 与 QuickStart'
native_apk add jsonfilter openssh-sftp-server luci-i18n-base-zh-cn || fail '安装 SFTP、LuCI 中文包或 Argon 依赖失败。'
istore_started=1
istore_apk add "$@" || fail '安装 iStore 或 QuickStart 失败。'
for pkg in "$@" quickstart openssh-sftp-server luci-i18n-base-zh-cn; do
    offline_apk info -e "$pkg" >/dev/null 2>&1 || fail "未确认 $pkg 已安装。"
done

step '离线安装已校验的 Argon APK'
# Both package trust bypass and local file paths are limited to this transaction.
offline_apk add --allow-untrusted "$work/$theme" "$work/$theme_config" "$work/$theme_lang" ||
    fail 'Argon 安装失败，停止后续 LuCI 与时区配置。'
offline_apk info -e 'luci-theme-argon=2.4.8-r2' 'luci-app-argon-config=2.4.8-r2' \
    luci-i18n-argon-config-zh-cn >/dev/null 2>&1 && [ -d /www/luci-static/argon ] ||
    fail '未确认 Argon 主题及配置已正确安装。'

step '应用 LuCI 主题、中文与时区'
check_uci ready
uci -t "$work/uci" set 'luci.main.mediaurlbase=/luci-static/argon' || fail '设置 LuCI 主题失败。'
uci -t "$work/uci" set 'luci.main.lang=zh_cn' || fail '设置 LuCI 语言失败。'
uci -t "$work/uci" set 'system.@system[0].zonename=Asia/Shanghai' || fail '设置时区名称失败。'
uci -t "$work/uci" set 'system.@system[0].timezone=CST-8' || fail '设置时区失败。'
uci -t "$work/uci" commit luci || fail '提交 LuCI 配置失败。'
uci -t "$work/uci" commit system || fail '提交时区配置失败。'
[ "$(uci -q get luci.main.mediaurlbase)" = /luci-static/argon ] &&
    [ "$(uci -q get luci.main.lang)" = zh_cn ] &&
    [ "$(uci -q get 'system.@system[0].zonename')" = Asia/Shanghai ] &&
    [ "$(uci -q get 'system.@system[0].timezone')" = CST-8 ] ||
    fail '未确认 LuCI 或时区配置已提交。'
/etc/init.d/system reload || fail '时区已保存，但系统服务重载失败。'
printf '\n安装完成。退出并重新登录 LuCI 查看 Argon，并从 LuCI 菜单打开 iStore / QuickStart。\n'
