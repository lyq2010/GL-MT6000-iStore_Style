# GL-MT6000 · iStore + LuCI Themes

[简体中文](README.md) · **English**

Install the [iStore](https://github.com/linkease/istore) app store, an iStore-style dashboard, and a LuCI theme on a **GL-MT6000 (Flint 2)** running stock GL.iNet firmware.

## One-command install

Pick the command for your installed firmware and run it as root over SSH. The router must be able to reach GitHub. These scripts **do not flash firmware**.

### OpenWrt 25.12 (APK): Outline

```sh
curl -fsSL https://raw.githubusercontent.com/lyq2010/GL-MT6000-iStore_Style/main/glinet-istore-argon-clean-op25.sh -o /tmp/clean-op25.sh && sh /tmp/clean-op25.sh
```

Reopen LuCI for **[Outline 1.5.0](https://github.com/tickcount/luci-theme-outline/releases/tag/v1.5.0)** (theme auto-updates off on a fresh install), Simplified Chinese, the standard Status, System, and Network menus, firewall and package management, and the iStore app store and dashboard. You can rerun this over the previous OP25 installer; it keeps any existing Argon installation.

### OpenWrt 24 (opkg): Argon

```sh
curl -fsSL https://raw.githubusercontent.com/lyq2010/GL-MT6000-iStore_Style/main/glinet-istore-argon-clean.sh -o /tmp/clean.sh && sh /tmp/clean.sh
```

Reopen LuCI for **[Argon 2.4.7](https://github.com/jerrykuku/luci-theme-argon/releases/tag/v2.4.7)**. Open the iStore-style dashboard at `http://<router-IP>:8080`.

## Notes

- Both scripts install SFTP support and set the router time zone to Asia/Shanghai.

- Neither script changes network, DNS, or firewall rules, installs ddnsto, or undoes changes made by other scripts.
- The OP25 script leaves existing package sources alone and does not hide iStore's package-source warning.

[MIT License](LICENSE)
