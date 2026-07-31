# 🇨🇳 Arch Linux 图形化安装向导 v2.0

> **⚠️ 警告：本工具涉及磁盘分区和系统安装操作，请谨慎使用！**
> 
> 请在 **Arch Linux Live CD** 环境中运行本向导。

---

## 🎯 功能特性

### 硬件全面检测

| 检测项 | 说明 |
|---|---|
| 🖥️ **CPU** | 型号、核心数、线程数 |
| 🎮 **显卡** | NVIDIA / AMD / Intel 自动识别 |
| 🔊 **声卡** | ALSA 设备检测 |
| 🌐 **有线网卡** | 接口检测 |
| 📡 **无线网卡** | Broadcom / Realtek 等识别 |
| 📶 **蓝牙** | USB 蓝牙设备检测 |
| 👆 **触摸板** | 笔记本触摸板检测 |
| 💻 **设备类型** | 自动判断台式机/笔记本 |
| 💾 **内存** | 容量检测 |

### 驱动全面覆盖

| 驱动类型 | 自动安装包 |
|---|---|
| **NVIDIA** | `nvidia` `nvidia-utils` `nvidia-settings` `nvidia-prime` |
| **AMD** | `mesa` `vulkan-radeon` `xf86-video-amdgpu` `libva-mesa-driver` |
| **Intel** | `mesa` `vulkan-intel` `xf86-video-intel` `intel-media-driver` |
| **声卡** | `alsa-utils` `pipewire` `wireplumber` `pavucontrol` |
| **无线** | `wireless_tools` `wpa_supplicant` `iwd` `linux-firmware` `broadcom-wl-dkms` `rtl88xxau-aircrack-dkms` |
| **蓝牙** | `bluez` `bluez-utils` |
| **触摸板** | `xf86-input-libinput` `xf86-input-synaptics` |
| **笔记本** | `tlp` `tlp-rdw` `acpi_call` |
| **打印机** | `cups` `cups-pdf` `hplip` `system-config-printer` |
| **摄像头** | `v4l-utils` `cheese` |
| **Wine** | `wine` `wine-mono` `wine-gecko` `winetricks` `lutris` `gamemode` `lib32-gamemode` |

### 系统级优化

| 优化项 | 说明 |
|---|---|
| **zram** | 内存压缩，提升性能 |
| **swap** | 自动配置 swap 分区 |
| **fstab** | `noatime` 挂载优化 |
| **防火墙** | `firewalld` + SSH/Samba 规则 |
| **镜像源** | 清华/中科大/阿里/腾讯 |
| **multilib** | 32位支持（Wine 必需） |
| **GRUB** | EFI 引导 + os-prober |
| **reflector** | 自动镜像排序 |

### 安全机制

| 机制 | 说明 |
|---|---|
| 🔍 **双系统检测** | 扫描 EFI/NTFS/ext，发现即停 |
| 🔊 **蜂鸣器警报** | 发现双系统响 3 声 |
| 🔒 **密码确认** | 必须输入两次，不一致拒绝 |
| 💾 **格式化确认** | 二次确认 + 配置摘要 |
| 📋 **脚本预览** | 生成后不直接执行，先审查 |

---

## 📦 使用方式

### 在 Arch Live CD 中运行

```bash
# 1. 启动 Arch ISO，进入 Live 环境
# 2. 连接网络
# 3. 安装依赖
pacman -S python tk git

# 4. 克隆并运行
git clone https://github.com/PAleimiao/Arch-Install-Wizard.git
cd Arch-Install-Wizard
python arch-install-wizard.py
```

---

## 🚀 自动安装模式

**默认配置：**

- 桌面环境：**GNOME Wayland**
- 系统语言：**英文** `en_US.UTF-8`
- 默认密码：`arch`（用户名: `user`）
- 分区方案：自动（EFI 512M + Swap 8G + Root 剩余）
- 镜像源：中国镜像
- **显卡驱动**：自动检测安装
- **声卡驱动**：ALSA + PipeWire
- **网卡驱动**：有线 + 无线 + 固件
- **蓝牙驱动**：自动检测安装
- **触摸板驱动**：自动检测安装
- **Wine**：自动安装 + 配置
- **打印机**：CUPS + HPLIP
- **摄像头**：V4L
- **笔记本电源**：TLP（如为笔记本）
- **系统优化**：zram + swap + fstab + 防火墙
- 预装软件：Firefox、Edge、QQ、微信、星火商店、LibreOffice、VLC、网易云音乐、VS Code
- 装完：**自动更新 + 重启**

---

## ⚙️ 手动安装模式

**可自定义项：**

- 磁盘分区（自动/手动，支持 `512M` `8G` `100G` 格式）
- 文件系统（ext4 / btrfs / xfs）
- 用户名/密码/主机名
- 时区/语言
- 桌面环境（Hyprland / GNOME / KDE / XFCE）
- **显卡驱动**（自动/NVIDIA/AMD/Intel/不装）
- **声卡/无线/蓝牙/触摸板/打印机/摄像头**（自选）
- **Wine**（自选）
- **笔记本电源管理**（自选）
- 额外软件包
- 网络管理器/镜像源

---

## 🛡️ 双系统检测机制

向导会扫描：
- EFI 分区中的 Windows/Ubuntu/Debian/Fedora/openSUSE/Manjaro/Arch 引导
- NTFS 分区（Windows）
- 多个 ext 分区（其他 Linux）

**若检测到：**
1. 蜂鸣器响 **3 声** (``)
2. 显示检测到的系统列表
3. 必须输入 `"I KNOW"`（全大写）才能继续
4. 建议手动分区避免破坏其他系统

---

## 📝 注意事项

1. **本向导生成脚本后不直接执行**，需用户审查后手动运行
2. 建议在虚拟机中先行测试
3. 安装前请备份重要数据
4. 需要网络连接以下载软件包
5. AUR 软件需要安装 `yay`
6. Wine 需要启用 `multilib` 仓库（脚本自动处理）
7. NVIDIA 显卡会额外配置 `mkinitcpio` hook

---

## 🙏 致谢

- [Arch Linux](https://archlinux.org/)
- [Arch Wiki](https://wiki.archlinux.org/)

---

## 📄 协议

GPL-3.0 License

Made with 💜 by PAleimiao
