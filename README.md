# GL-MT6000 · iStore + LuCI 主题

**简体中文** · [English](README.en.md)

为运行 GL.iNet 原厂固件的 **GL-MT6000（Flint 2）** 安装 [iStore](https://github.com/linkease/istore) 商店、iStore 风格首页和 LuCI 主题。

## 一键安装

按已安装的固件版本选一条命令，用 root 登录路由器 SSH 后执行。路由器需能访问 GitHub。脚本**不刷固件**。

### OpenWrt 25.12（APK）：Outline

```sh
curl -fsSL https://raw.githubusercontent.com/lyq2010/GL-MT6000-iStore_Style/main/glinet-istore-argon-clean-op25.sh -o /tmp/clean-op25.sh && sh /tmp/clean-op25.sh
```

装好后重新打开 LuCI：默认使用 **[Outline 1.5.0](https://github.com/tickcount/luci-theme-outline/releases/tag/v1.5.0)**（首次安装关闭主题自动更新），提供简体中文和完整的标准「状态、系统、网络」菜单，以及防火墙、软件包管理、iStore 商店和首页。跑过旧版 OP25 脚本也可直接重跑；已有的 Argon 会保留。

### OpenWrt 24（opkg）：Argon

```sh
curl -fsSL https://raw.githubusercontent.com/lyq2010/GL-MT6000-iStore_Style/main/glinet-istore-argon-clean.sh -o /tmp/clean.sh && sh /tmp/clean.sh
```

装好后重新打开 LuCI 使用 **[Argon 2.4.7](https://github.com/jerrykuku/luci-theme-argon/releases/tag/v2.4.7)**。iStore 风格首页：`http://<路由器IP>:8080`。

## 注意事项

- 两版都安装 SFTP 支持，并将系统时区设为北京时间。

- 两版都不改网络、DNS 或防火墙规则，不安装 ddnsto，也不撤销其他脚本已做的改动。
- OP25 不替换现有软件源，也不隐藏 iStore 首页的「软件源错误」提示。

[MIT 许可证](LICENSE)
