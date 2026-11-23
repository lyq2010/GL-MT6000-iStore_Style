<div align="center">

# 🛡️ GL-MT6000 · Clean iStore + LuCI Themes

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
![Theme](https://img.shields.io/badge/Theme-Outline%20(OP25)%20%7C%20Argon%20(OP24)-7C4DFF?style=flat-square)
![Repeatable](https://img.shields.io/badge/after%20firmware%20upgrade-one--shot%20restore-orange?style=flat-square)
[![License](https://img.shields.io/github/license/lyq2010/GL-MT6000-iStore_Style?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/lyq2010/GL-MT6000-iStore_Style?style=flat-square&logo=github)](https://github.com/lyq2010/GL-MT6000-iStore_Style/stargazers)
[![Last Commit](https://img.shields.io/github/last-commit/lyq2010/GL-MT6000-iStore_Style?style=flat-square)](https://github.com/lyq2010/GL-MT6000-iStore_Style/commits/main)

</div>

---

> Same result as the popular "one-click iStoreOS styling" (iStore store + styled homepage + LuCI theme),
> but **without the side effects that silently rewrite your firewall, install remote access, or hijack DNS** — every component comes from an **official source**.

---

## ✨ Key Features

- 🧩 **iStore app store** + iStoreOS-style homepage (OP24: `:8080`; OP25: LuCI menu)
- 🎨 **Outline on OP25, Argon on OP24.** OP25 restores the standard LuCI administration pages and verifies the upstream theme APK against its release SHA-256.
- 🔒 **Privacy first** — no firewall changes, no cloud tunneling, no DNS hijacking, no branding fields written
- 📡 **Transparent sources** — iStore and apps from their official feeds, themes from the Outline or Argon upstream project
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
(f=$(mktemp /tmp/glinet-op25.XXXXXX) && trap 'rm -f "$f"' EXIT &&
  curl -fsSL https://raw.githubusercontent.com/lyq2010/GL-MT6000-iStore_Style/main/glinet-istore-argon-clean-op25.sh -o "$f" &&
  sh "$f")
```

**Use the same command for a fresh install or an existing OP25 installation.** There is no need to remove iStore or QuickStart. An existing Argon installation and its settings stay in place; you can switch back under System → System → Language and Style. For OP24, use the original script below.

- **Restores the LuCI administration pages.** Installs `luci-mod-admin-full` (Status, System, and Network), PPPoE / IPv6 support in LuCI, the firewall and package manager views, and Simplified Chinese translations from the GL.iNet firmware feed. The package manager and iStore are separate. Also installs the native OpenSSH SFTP backend without starting a standalone server. Bootstrap is installed as a fallback theme.
- **Uses [Outline v1.5.0](https://github.com/tickcount/luci-theme-outline/releases/tag/v1.5.0).** The pinned `1.5.0-r20261120` APK is checked against the upstream release SHA-256 and installed offline, without weakening global signature checks. An already installed newer version is not downgraded. The default unattended updater is disabled if unset; an existing preference is preserved. The upstream theme may set the `uhttpd` root index and reload the service, but does not change its ports or TLS settings. LuCI is set to Simplified Chinese and the timezone to `Asia/Shanghai`.
- **Preserves existing repository settings.** The installer temporarily uses the original feed files and public keys from the read-only `/rom` filesystem, plus official iStore indexes. The live overlay files such as `/etc/apk/repositories.d/distfeeds.list` (including any CERNET mirror configuration) are neither used for this install nor replaced. The iStore package itself installs its own public key and `compat.list`.
- **QuickStart architecture and dependencies.** Adds iStore's required `aarch64_generic` to `/etc/apk/arch` only if missing, preserving the primary `aarch64_cortex-a53` architecture. If a check fails before iStore installation starts, the script attempts to undo the append. Once installation starts, it can leave partially installed packages and does not roll them back. QuickStart still needs its declared storage tools. The installer does not change network or DNS settings or firewall rules, and does not install ddnsto or other cloud tunneling components.
- **“Detecting” is not proof that WAN is offline.** This QuickStart version checks for `packages.adb.asc` at the feed in the current overlay. On the checked GL.iNet 25.12.6 feed, that URL returned 404 while the actual `packages.adb` index was available. The separately checked CERNET mirror configuration returned 404 for a real `packages.adb` index; a normal `apk update` can still fail if you retain that configuration. That is a mirror index issue, not the QuickStart false alarm or a PPPoE failure. If internet access and APK indexes work, don't change WAN, DNS, or repositories just to clear the indicator. The installer does not hide it.
- The verification baseline is the official **4.11.1-op25 Beta 1, OpenWrt 25.12.6** image. **This revision has not been tested on physical hardware.** If a feed, signature, or dependency check fails, do not force the install or switch to the OP24 script.

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

## 🎨 Argon on OP24

Argon currently publishes both `.ipk` and `.apk` packages. Your GL official OpenWrt 24 firmware still uses `opkg`, so the script installs these two IPKs from the same release:

- `luci-theme-argon_2.4.7_all.ipk`
- `luci-app-argon-config_2.4.7_all.ipk`

Keeping the theme and configuration plugin on the same version avoids feature differences caused by pairing a new theme with an old configuration plugin.

The current GL/OpenWrt/iStore OP24 feeds do not contain `luci-theme-argon` or `luci-app-argon-config`, and jerrykuku does not provide a `Packages.gz` feed that opkg can consume directly. Argon therefore cannot track the repository version in the same way as QuickStart or SFTP. The script pins a verified version so a GitHub Release layout or filename change cannot suddenly break installation; Release assets and OP24 compatibility are checked before the pinned version is updated.

> ℹ️ The original OP24 script does not install the Argon Config Simplified Chinese translation. The Argon configuration page may therefore appear in English on OP24; theme and configuration functionality are unaffected, and the script does not mix apk packages into an opkg system.

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
| 🎨 Outline (OP25) | [tickcount/luci-theme-outline](https://github.com/tickcount/luci-theme-outline) |
| 🎨 Argon (OP24) | [jerrykuku/luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon) · [luci-app-argon-config](https://github.com/jerrykuku/luci-app-argon-config) |

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
