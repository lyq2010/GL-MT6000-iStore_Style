<div align="center">

# 🛡️ GL-MT6000 · 干净版 iStore + Argon

**把 GL.iNet 路由器变成 iStoreOS 风格 —— 却不留任何隐私后患**

一行命令 · 官方来源 · 零云端组件

**简体中文** · [English](README.en.md)

<br/>

![Platform](https://img.shields.io/badge/Platform-GL.iNet%20MT6000-2D7FF9?style=for-the-badge&logo=openwrt&logoColor=white)
![Arch](https://img.shields.io/badge/Arch-aarch64-3DDC84?style=for-the-badge)
![Firmware](https://img.shields.io/badge/OpenWrt%2024.x-opkg-00B5E2?style=for-the-badge&logo=openwrt&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-POSIX%20sh-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)

![Privacy](https://img.shields.io/badge/隐私-零云端组件-FF4088?style=flat-square)
![Source](https://img.shields.io/badge/来源-全部官方-blueviolet?style=flat-square)
![Theme](https://img.shields.io/badge/Argon-v2.3.2-7C4DFF?style=flat-square)
![Repeatable](https://img.shields.io/badge/固件升级后-可一键恢复-orange?style=flat-square)
[![License](https://img.shields.io/github/license/lyq2010/GL-MT6000-iStore_Style?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/lyq2010/GL-MT6000-iStore_Style?style=flat-square&logo=github)](https://github.com/lyq2010/GL-MT6000-iStore_Style/stargazers)
[![Last Commit](https://img.shields.io/github/last-commit/lyq2010/GL-MT6000-iStore_Style?style=flat-square)](https://github.com/lyq2010/GL-MT6000-iStore_Style/commits/main)

</div>

---

> 效果等同主流的「一键 iStoreOS 风格化」（iStore 商店 + 风格首页 + 紫色 Argon 主题），
> 但**去掉了那些悄悄改防火墙、装远程访问、劫持 DNS 的副作用**，所有组件均来自**官方源**。

---

## ✨ 核心特性

- 🧩 **iStore 应用商店** + iStoreOS 风格首页（`:8080`）
- 🎨 **紫色 Argon 主题** —— 来自官方 `jerrykuku` 仓库，非第三方无签名包
- 🔒 **隐私优先** —— 不改防火墙、不装云端穿透、不劫持 DNS、不写品牌字段
- 📡 **来源透明** —— iStore 走 `linkease`，主题走 `jerrykuku`，应用走官方源
- ♻️ **可重复执行** —— 固件升级清空后，再跑一遍即可一键恢复
- 🪶 **纯本地服务** —— 装的应用没有任何会主动向外建隧道的云端组件

---

## 🎯 适用环境

| 项目 | 要求 |
|------|------|
| 机型 | GL.iNet **GL-MT6000**（Flint 2）等 **aarch64** 机型 |
| 固件 | GL.iNet 官方 **OpenWrt 24**（**opkg** 体系） |
| 权限 | SSH root 访问 |
| 网络 | 路由器本机能访问 GitHub（国内可能需走代理，见下文） |

---

## 📦 它会安装什么

| 组件 | 来源 | 版本策略 |
|------|------|----------|
| iStore 应用商店（`luci-app-store`） | 官方 `istore.linkease.com` | 🔄 取仓库当前最新 |
| iStore 风格首页（`luci-app-quickstart` + 中文包） | 官方 iStore 源 | 🔄 取最新 |
| SFTP 底层服务（`openssh-sftp-server`，本地服务） | 官方 OpenWrt 源 | 🔄 取最新 |
| Argon 主题 + 配置插件 + 中文包 | 官方 `github.com/jerrykuku` | 📌 固定 v2.3.2（见下） |
| 时区 | — | 设为 `Asia/Shanghai`（可自行删） |
| LuCI 主题 / 语言 | — | 切到 Argon + 中文（仅当主题装好时） |

---

## 🚀 快速开始

SSH 登录路由器后，一行拉取并执行：

```sh
curl -fsSL https://raw.githubusercontent.com/lyq2010/GL-MT6000-iStore_Style/main/glinet-istore-argon-clean.sh -o /tmp/clean.sh && sh /tmp/clean.sh
```

跑完后**退出并重新登录 LuCI**（建议 `Ctrl + F5` 强刷）即可看到 Argon 主题。

🏠 iStore 风格首页：`http://<你的路由器IP>:8080`

> 💡 **国内访问 GitHub**：路由器本机若无法直连 GitHub，请让本机流量走你的代理，或在能访问 GitHub 的电脑上下载 Argon 的 ipk，再用 LuCI「系统 → 软件包 → 上传安装」。脚本在下载失败时会自动打印对应链接与提示。
>
> 本脚本**特意不内置第三方 ghproxy 镜像** —— 那等于让镜像方有机会篡改未签名的 ipk，与「换可信源」的初衷相悖。

---

## 🔁 固件升级后如何恢复

固件升级（尤其是不保留配置的全新刷写）会**清空 overlay**，iStore、Argon、各应用都会消失 —— 本脚本正是为此设计：**升级后再跑一遍即可一键恢复**。

- iStore 与各应用 → 跟随新固件的源装到对应**最新版**
- Argon → 装回 **v2.3.2**（opkg 下最新可用版）
- SFTP 底层包 `openssh-sftp-server` → 显式装回

> ⚠️ 即便升级时选了「保留配置」，`/etc/config/*` 大多会留下，但**通过 opkg 安装的软件包通常不保留**。建议升级后先确认防火墙等关键配置仍正确，再跑一遍本脚本补齐应用。

---

## 🎨 关于 Argon 版本（为什么固定 v2.3.2）

OpenWrt 自 **25.12** 起把包管理器从 `opkg` 换成了 `apk`。jerrykuku 官方随之调整：

> **自 v2.4.3 起，Argon 只发布 `.apk`，不再提供 `_all.ipk`。**

你的 GL 官方 OpenWrt 24 仍是 **opkg** 体系，因此：

- ✅ `v2.3.2` 是最后一个带 `_all.ipk` 的版本，也就是 **opkg 下能装的最新 Argon**
- ❌ 更新的 v2.4.3+ 是 `.apk`，opkg 装不了

所以脚本固定 v2.3.2 **不是图省事，而是上游已无更新的 ipk 可取**。等将来 GL 固件升级到 apk 体系（OpenWrt 25.12+），再另行更新。

---

## ♻️ 从常见一键脚本回滚

<details>
<summary>👉 如果你之前跑过常见的「一键 iStoreOS 风格化」脚本，点此展开清理命令</summary>

<br/>

本脚本**只负责把组件换成干净来源，并不会撤销这类脚本已做过的改动**。要清干净，按需手动执行（防火墙那条先判断主路由 / 旁路由）：

```sh
# 1) WAN 防火墙：撤回 ACCEPT（先确认 @zone[1] 是 wan）
uci show firewall.@zone[1]
#   主路由(WAN直连光猫) => 改回 REJECT：
uci set firewall.@zone[1].input='REJECT'
uci commit firewall && /etc/init.d/firewall restart
#   旁路由(挂在可信主路由后) => 不要直接 REJECT，按需单独放行来源。

# 2) 卸载 ddnsto
opkg remove app-meta-ddnsto luci-app-ddnsto ddnsto 2>/dev/null

# 3) 删除 time.android.com 的 DNS 劫持（自动定位序号）
idx=$(uci show dhcp | sed -n "s/^dhcp\.@domain\[\([0-9]*\)\]\.name='time\.android\.com'.*/\1/p" | head -1)
[ -n "$idx" ] && uci delete dhcp.@domain[$idx] && uci commit dhcp && /etc/init.d/dnsmasq restart

# 4) 还原品牌字段（uci + 文件）
uci set system.@system[0].description='OpenWrt'
uci -q delete system.@system[0].notes
uci commit system
. /etc/openwrt_release
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='OpenWrt ${DISTRIB_RELEASE}'/" /etc/openwrt_release

# 5) 删除一键脚本的全局启动器
rm -f /usr/bin/g
```

> 🌐 **远程访问说明**：WAN `input='REJECT'` 只挡「直连路由器本机」的新入站连接，**不影响**端口转发（DNAT 到内网主机）、frp 等出站隧道、以及反代经 LAN 回源访问 LuCI。若你是用 DDNS + 端口转发到 NAS 上的反代（如 Lucky），不受影响。

</details>

---

## ⚠️ 注意事项

| | 说明 |
|---|---|
| 🧪 **beta 固件** | GL 官方 OpenWrt 24 仍是 beta（kernel 6.6），不在同类一键脚本的官方支持范围。iStore 与 Argon 实测可用；个别应用偶发依赖错误时，按提示重试一次通常即可。 |
| 🧬 **架构** | 仅适配 aarch64（MT6000 / MT3000 / MT2500）。iStore 官方源只支持 x86_64 / arm64。 |
| 🌍 **GitHub 访问** | 国内路由器本机直连 GitHub 常失败，按「快速开始」里的提示走代理或手动上传。 |

---

## 🙏 致谢与来源

| 项目 | 链接 |
|------|------|
| 🛒 iStore | [linkease/istore](https://github.com/linkease/istore)（官方 `istore.linkease.com`） |
| 🎨 Argon 主题 | [jerrykuku/luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon) · [luci-app-argon-config](https://github.com/jerrykuku/luci-app-argon-config) |

---

## 📄 免责声明

脚本以 **root** 权限在你的路由器上运行并安装软件，使用前建议先**备份配置**（LuCI → 系统 → 备份/升级）。请自行评估并对操作结果负责。

---

## 📜 License

本项目以 [MIT](LICENSE) 协议开源 © 2026 lyq2010。


<div align="center">
<br/>
<sub>Made for a cleaner, privacy-respecting OpenWrt 🐧</sub>
</div>
