<div align="center">

# 🛡️ GL-MT6000 · Clean iStore + Argon

**Turn your GL.iNet router into an iStoreOS-style UI — without any privacy aftermath**

One command · Official sources · Zero cloud components

[简体中文](README.md) · **English**

<br/>

![Platform](https://img.shields.io/badge/Platform-GL.iNet%20MT6000-2D7FF9?style=for-the-badge&logo=openwrt&logoColor=white)
![Arch](https://img.shields.io/badge/Arch-aarch64-3DDC84?style=for-the-badge)
![Firmware](https://img.shields.io/badge/OpenWrt-24%20opkg%20%7C%2025%20APK-00B5E2?style=for-the-badge&logo=openwrt&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-POSIX%20sh-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)

![Privacy](https://img.shields.io/badge/Privacy-zero%20cloud%20components-FF4088?style=flat-square)
![Source](https://img.shields.io/badge/Sources-all%20official-blueviolet?style=flat-square)
![Theme](https://img.shields.io/badge/Argon-2.4.7%20%7C%202.4.8--r2-7C4DFF?style=flat-square)
![Repeatable](https://img.shields.io/badge/after%20firmware%20upgrade-one--shot%20restore-orange?style=flat-square)
[![License](https://img.shields.io/github/license/lyq2010/GL-MT6000-iStore_Style?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/lyq2010/GL-MT6000-iStore_Style?style=flat-square&logo=github)](https://github.com/lyq2010/GL-MT6000-iStore_Style/stargazers)
[![Last Commit](https://img.shields.io/github/last-commit/lyq2010/GL-MT6000-iStore_Style?style=flat-square)](https://github.com/lyq2010/GL-MT6000-iStore_Style/commits/main)

</div>

---

> Same result as the popular "one-click iStoreOS styling" (iStore store + styled homepage + purple Argon theme),
> but **without the side effects that silently rewrite your firewall, install remote access, or hijack DNS** — every component comes from an **official source**.

---

## ✨ Key Features

- 🧩 **iStore app store** + iStoreOS-style homepage (OP24: `:8080`; OP25: LuCI menu)
- 🎨 **Purple Argon theme** — from the official `jerrykuku` repo, OP25 checks the release SHA-256 before installation
- 🔒 **Privacy first** — no firewall changes, no cloud tunneling, no DNS hijacking, no branding fields written
- 📡 **Transparent sources** — iStore from the official `iStoreOS` feed, theme from `jerrykuku`, apps from official sources
- ♻️ **Repeatable** — after a firmware upgrade, verify the version and rerun the matching script
- 🪶 **Local-only services** — none of the installed apps open outbound tunnels on their own

---

## 🎯 Target Environment

| Item | Requirement |
|------|------|
| OP25 / APK | GL.iNet **GL-MT6000** (Flint 2), official **OpenWrt 25.12**, and **apk-tools 3.x**; use the new script below |
| OP24 / opkg | Official GL.iNet **OpenWrt 24**; keep using the original script |
| Access | SSH root access |
| Network | The router itself can reach GitHub (a proxy may be needed in mainland China, see below) |

---

## 🚀 OP25 / APK One-Click Install

This script installs apps; **it does not flash firmware**. Back up your configuration and confirm that the GL-MT6000 is already running **GL.iNet's official OP25 firmware** and has completed its first boot. Then run as root over SSH:

```sh
f="$(mktemp /tmp/glinet-op25.XXXXXX)" && { curl -fsSL https://raw.githubusercontent.com/lyq2010/GL-MT6000-iStore_Style/main/glinet-istore-argon-clean-op25.sh -o "$f" && sh "$f"; rc=$?; rm -f "$f"; (exit "$rc"); }
```

- Installs official iStore, QuickStart and the QuickStart / LuCI Chinese translations, plus the native OpenSSH SFTP backend, which does not start a standalone server. Installs the pinned [Argon 2.4.8-r2](https://github.com/jerrykuku/luci-theme-argon/releases/tag/v2.4.8) theme, config plugin and Simplified Chinese APK. This release fixes the OpenWrt 25.12 ucode compatibility issue. The official theme package may set the default theme in its install hook. The script does not overwrite a conflicting theme or downgrade a newer release.
- QuickStart requires the `aarch64_generic` backend. The script **appends** that architecture to `/etc/apk/arch` if needed, as specified in iStore's official architecture list. It preserves the primary `aarch64_cortex-a53` architecture. If a check fails before iStore installation starts, it attempts to undo the append. Once installation starts, partial installs are possible, so it keeps the architecture and does not roll back packages.
- Does not replace the system repositories or disable signature checks globally. The script uses an official iStore key in a temporary directory for verification; the official iStore package itself installs its own public key and `compat.list`. Only after all three Argon files match the release SHA-256 digests does the script allow their one-time offline install.
- Does not change network, firewall, or DNS settings, or install ddnsto/cloud tunneling. QuickStart still needs the storage tools declared in its package dependencies. After signing back into LuCI, use its menu to open iStore / QuickStart. The script sets LuCI to Simplified Chinese and Argon, and the timezone to `Asia/Shanghai`.
- The official **4.11.1-op25 Beta 1, OpenWrt 25.12.6** image and the iStore / QuickStart and Argon dependency plans were checked offline. **Installation on physical hardware has not been tested.** If a repository, signature or dependency check fails, stop rather than forcing an install or retrying with the OP24 script.

---

## 📦 What the Original OP24 / opkg Script Installs

| Component | Source | Version policy |
|------|------|----------|
| iStore app store (`luci-app-store`) | Official `istore.istoreos.com` | 🔄 latest in the repo |
| iStore-style homepage (`luci-app-quickstart` + zh-cn pack) | Official iStore source | 🔄 latest |
| SFTP backend (`openssh-sftp-server`, local service) | Official OpenWrt source | 🔄 latest |
| Argon theme + config plugin | Official `github.com/jerrykuku` | 📌 both pinned to v2.4.7 (see below) |
| Timezone | — | set to `Asia/Shanghai` (remove if unwanted) |
| LuCI theme / language | — | switched to Argon + Chinese (only when the theme installed OK) |

---

## 🚀 OP24 / opkg Quick Start

After logging into the router via SSH, fetch and run in one line:

```sh
curl -fsSL https://raw.githubusercontent.com/lyq2010/GL-MT6000-iStore_Style/main/glinet-istore-argon-clean.sh -o /tmp/clean.sh && sh /tmp/clean.sh
```

When it finishes, **log out and back into LuCI** (a hard refresh with `Ctrl + F5` is recommended) and you'll see the Argon theme.

🏠 iStore-style homepage: `http://<your-router-IP>:8080`

> 💡 **Accessing GitHub from mainland China**: if the router itself can't reach GitHub directly, route its traffic through your proxy, or download the Argon ipk on a computer that can reach GitHub and install it via LuCI → System → Software → Upload. The script prints the relevant links and hints if a download fails.
>
> This script **deliberately does not bundle a third-party ghproxy mirror** — that would give the mirror operator a chance to tamper with the unsigned ipk, which defeats the whole point of "switching to a trusted source".

---

## 🔁 Restoring After a Firmware Upgrade

After upgrading, check the firmware version and your network and firewall settings. If you moved to OP25, reinstall apps with the APK script above. Do not restore the entire OP24 overlay, opkg repositories, or package database to OP25. If staying on OP24, you can reinstall as follows:

- iStore and apps → installed to their **latest** versions from the new firmware's sources
- Argon → reinstalled at the script's pinned **v2.4.7**
- SFTP backend `openssh-sftp-server` → explicitly reinstalled

> ⚠️ Even if you choose "keep settings" during the upgrade, `/etc/config/*` mostly survives, but **packages installed via opkg usually do not**. After upgrading, verify your firewall and other critical config first, then run this script to restore the apps.

---

## 🎨 About the Argon Version

Argon currently publishes both `.ipk` and `.apk` packages. Your GL official OpenWrt 24 firmware still uses `opkg`, so the script installs these two IPKs from the same release:

- `luci-theme-argon_2.4.7_all.ipk`
- `luci-app-argon-config_2.4.7_all.ipk`

Keeping the theme and configuration plugin on the same version avoids feature differences caused by pairing a new theme with an old configuration plugin.

The current GL/OpenWrt/iStore OP24 feeds do not contain `luci-theme-argon` or `luci-app-argon-config`, and jerrykuku does not provide a `Packages.gz` feed that opkg can consume directly. Argon therefore cannot track the repository version in the same way as QuickStart or SFTP. The script pins a verified version so a GitHub Release layout or filename change cannot suddenly break installation; Release assets and OP24 compatibility are checked before the pinned version is updated.

> ℹ️ Upstream currently provides no `.ipk` for the Argon Config Simplified Chinese translation. The Argon configuration page may therefore appear in English on OP24; theme and configuration functionality are unaffected, and the script does not mix apk packages into an opkg system.

---

## ♻️ Rolling Back From a Common One-Click Script

<details>
<summary>👉 If you previously ran a common "one-click iStoreOS styling" script, expand for cleanup commands</summary>

<br/>

This section is for **OP24 / opkg** only and is not an OP25 migration step. The installer does not undo changes made by other one-click scripts. To clean up, run the following as needed (for the firewall line, first determine main-router vs. bypass-router):

```sh
# 1) WAN firewall: revert ACCEPT (first confirm @zone[1] is wan)
uci show firewall.@zone[1]
#   Main router (WAN directly to the modem) => set back to REJECT:
uci set firewall.@zone[1].input='REJECT'
uci commit firewall && /etc/init.d/firewall restart
#   Bypass router (behind a trusted main router) => do NOT blindly REJECT; allow specific sources as needed.

# 2) Remove ddnsto
opkg remove app-meta-ddnsto luci-app-ddnsto ddnsto 2>/dev/null

# 3) Remove the time.android.com DNS hijack (auto-locate the index)
idx=$(uci show dhcp | sed -n "s/^dhcp\.@domain\[\([0-9]*\)\]\.name='time\.android\.com'.*/\1/p" | head -1)
[ -n "$idx" ] && uci delete dhcp.@domain[$idx] && uci commit dhcp && /etc/init.d/dnsmasq restart

# 4) Restore branding fields (uci + files)
uci set system.@system[0].description='OpenWrt'
uci -q delete system.@system[0].notes
uci commit system
. /etc/openwrt_release
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='OpenWrt ${DISTRIB_RELEASE}'/" /etc/openwrt_release

# 5) Remove the script's global launcher
rm -f /usr/bin/g
```

> 🌐 **Note on remote access**: WAN `input='REJECT'` only blocks new inbound connections that target the router itself. It does **not** affect port forwarding (DNAT to internal hosts), outbound tunnels like frp, or reverse proxies reaching LuCI from the LAN side. If you use DDNS + port forwarding to a reverse proxy on a NAS (e.g. Lucky), you're unaffected.

</details>

---

## ⚠️ Caveats

| | Details |
|---|---|
| 🧪 **beta firmware** | GL official OpenWrt 24 is still beta (kernel 6.6) and outside the official support scope of such one-click scripts. iStore and Argon work in practice; if an occasional app throws a dependency error, retrying once per the prompt usually fixes it. |
| 🧬 **architecture** | aarch64 only (MT6000 / MT3000 / MT2500). The official iStore source supports only x86_64 / arm64. |
| 🌍 **GitHub access** | Routers in mainland China often fail to reach GitHub directly; use a proxy or upload manually per the "Quick Start" hints. |

---

## 🙏 Credits & Sources

| Project | Link |
|------|------|
| 🛒 iStore | [linkease/istore](https://github.com/linkease/istore) (official `istore.istoreos.com`) |
| 🎨 Argon theme | [jerrykuku/luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon) · [luci-app-argon-config](https://github.com/jerrykuku/luci-app-argon-config) |

---

## 📄 Disclaimer

The script runs as **root** on your router and installs software. **Back up your config** first (LuCI → System → Backup/Flash Firmware). Evaluate it yourself and take responsibility for the outcome.

---

## 📜 License

Released under the [MIT](LICENSE) License © 2026 lyq2010.


<div align="center">
<br/>
<sub>Made for a cleaner, privacy-respecting OpenWrt 🐧</sub>
</div>
