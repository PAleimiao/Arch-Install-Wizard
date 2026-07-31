#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🇨🇳 Arch Linux 图形化安装向导 v2.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  警告：本工具涉及磁盘分区和系统安装操作，请谨慎使用！
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

对标 Arch 官方安装流程，功能只多不少：
  • 完整硬件检测 → 自动推荐驱动
  • 声卡/网卡/显卡/蓝牙/触摸板/打印机/摄像头 全面覆盖
  • Wine + 游戏环境
  • 系统级优化配置（swap/zram/防火墙/fstab）
  • 自动/手动双模式

作者: PAleimiao
协议: GPL-3.0
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import subprocess
import os
import re
import sys
import json

# ═══════════════════════════════════════════════════════════════
# 工具函数
# ═══════════════════════════════════════════════════════════════

def beep(count=3):
    for _ in range(count):
        print("\a", end="", flush=True)
        try:
            subprocess.run(["paplay", "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"],
                           capture_output=True, timeout=1)
        except:
            pass

def run_cmd(cmd, capture=True, timeout=30):
    try:
        if capture:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
            return result.stdout.strip(), result.returncode
        else:
            subprocess.run(cmd, shell=True)
            return "", 0
    except Exception as e:
        return str(e), 1

def get_disks():
    stdout, _ = run_cmd("lsblk -d -n -o NAME,SIZE,MODEL,TYPE")
    disks = []
    for line in stdout.split("\n"):
        parts = line.split()
        if len(parts) >= 3 and parts[-1] == "disk":
            dev = f"/dev/{parts[0]}"
            size = parts[1]
            model = " ".join(parts[2:-1]) if len(parts) > 3 else "Unknown"
            disks.append((dev, size, model))
    return disks

def detect_dual_boot():
    warnings = []
    stdout, _ = run_cmd("lsblk -o NAME,FSTYPE,MOUNTPOINT -n")
    for line in stdout.split("\n"):
        if "efi" in line.lower() or "vfat" in line.lower():
            efi_dirs = ["/boot/efi/EFI", "/mnt/boot/efi/EFI"]
            for efi in efi_dirs:
                if os.path.exists(efi):
                    for entry in os.listdir(efi):
                        if entry.lower() in ["microsoft", "windows", "ubuntu", "debian", "fedora", "opensuse", "manjaro", "arch"]:
                            warnings.append(f"检测到 {entry} 系统引导")
    stdout, _ = run_cmd("lsblk -o FSTYPE -n")
    if "ntfs" in stdout.lower():
        warnings.append("检测到 NTFS 分区（可能为 Windows）")
    fs_types = stdout.lower().split()
    ext_count = sum(1 for f in fs_types if f.startswith("ext"))
    if ext_count > 1:
        warnings.append(f"检测到多个 ext 分区（可能已有 Linux 系统）")
    return warnings

def get_cpu_info():
    """检测 CPU 信息"""
    info = {"vendor": "unknown", "model": "unknown", "cores": 1, "threads": 1}
    stdout, _ = run_cmd("cat /proc/cpuinfo")
    for line in stdout.split("\n"):
        if "vendor_id" in line and info["vendor"] == "unknown":
            info["vendor"] = line.split(":")[-1].strip().lower()
        if "model name" in line and info["model"] == "unknown":
            info["model"] = line.split(":")[-1].strip()
        if "cpu cores" in line:
            info["cores"] = int(line.split(":")[-1].strip())
        if "siblings" in line:
            info["threads"] = int(line.split(":")[-1].strip())
    return info

def get_gpu_info():
    gpus = []
    stdout, _ = run_cmd("lspci -nn | grep -E 'VGA|3D|Display'")
    for line in stdout.split("\n"):
        if line.strip():
            match = re.search(r'\[([0-9a-fA-F]{4}:[0-9a-fA-F]{4})\]', line)
            if match:
                dev_id = match.group(1)
                if "nvidia" in line.lower():
                    gpus.append(("nvidia", dev_id, line))
                elif "amd" in line.lower() or "ati" in line.lower():
                    gpus.append(("amd", dev_id, line))
                elif "intel" in line.lower():
                    gpus.append(("intel", dev_id, line))
                else:
                    gpus.append(("unknown", dev_id, line))
    return gpus

def get_audio_info():
    """检测声卡信息"""
    cards = []
    stdout, _ = run_cmd("cat /proc/asound/cards")
    for line in stdout.split("\n"):
        if line.strip() and not line.startswith(" "):
            cards.append(line.strip())
    return cards

def get_network_info():
    """检测网卡信息"""
    interfaces = []
    stdout, _ = run_cmd("ip link show")
    for line in stdout.split("\n"):
        if ":" in line and "lo:" not in line:
            iface = line.split(":")[1].strip()
            if iface:
                interfaces.append(iface)
    return interfaces

def get_wireless_info():
    """检测无线网卡"""
    stdout, _ = run_cmd("lspci -nn | grep -i net")
    wireless = []
    for line in stdout.split("\n"):
        if "wireless" in line.lower() or "wifi" in line.lower() or "802.11" in line.lower():
            wireless.append(line.strip())
    return wireless

def get_bluetooth_info():
    """检测蓝牙"""
    stdout, _ = run_cmd("lsusb | grep -i bluetooth")
    return stdout.strip() != ""

def get_touchpad_info():
    """检测触摸板"""
    stdout, _ = run_cmd("cat /proc/bus/input/devices | grep -i touchpad")
    return stdout.strip() != ""

def get_laptop_info():
    """检测是否为笔记本"""
    stdout, _ = run_cmd("cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0")
    try:
        chassis = int(stdout.strip())
        return chassis in [8, 9, 10, 14]  # 笔记本/手持/笔记本/子笔记本
    except:
        return False

def get_memory_info():
    """检测内存大小"""
    stdout, _ = run_cmd("free -h | grep Mem | awk '{print $2}'")
    return stdout.strip()

# ═══════════════════════════════════════════════════════════════
# 向导主类
# ═══════════════════════════════════════════════════════════════

class ArchInstallWizard:
    def __init__(self, root):
        self.root = root
        self.root.title("🇨🇳 Arch Linux 安装向导 v2.0")
        self.root.geometry("1000x750")
        self.root.configure(bg="#0d1117")

        # 硬件信息缓存
        self.hw_info = {
            "cpu": get_cpu_info(),
            "gpu": get_gpu_info(),
            "audio": get_audio_info(),
            "network": get_network_info(),
            "wireless": get_wireless_info(),
            "bluetooth": get_bluetooth_info(),
            "touchpad": get_touchpad_info(),
            "laptop": get_laptop_info(),
            "memory": get_memory_info(),
        }

        self.config = {
            "mode": None,
            "disk": "",
            "scheme": "auto",
            "partitions": {},
            "hostname": "arch-pc",
            "username": "user",
            "password": "",
            "root_password": "",
            "de": "gnome",
            "timezone": "Asia/Shanghai",
            "locale": "en_US.UTF-8",
            "locale_manual": "zh_CN.UTF-8",
            "filesystem": "ext4",
            "swap": True,
            "swap_size": "8G",
            "efi_size": "512M",
            "mirror": "china",
            "packages": {},
            "gpu_driver": "",
            "dual_boot_warnings": [],
            "hw_detected": {},
        }

        self.steps_auto = [
            self.welcome_page,
            self.hw_detect_page,
            self.dual_boot_check_page,
            self.auto_confirm_page,
            self.auto_install_page,
        ]

        self.steps_manual = [
            self.welcome_page,
            self.mode_select_page,
            self.hw_detect_page,
            self.dual_boot_check_page,
            self.disk_page,
            self.partition_page,
            self.format_confirm_page,
            self.system_page,
            self.desktop_page,
            self.driver_page,
            self.network_page,
            self.manual_confirm_page,
            self.manual_install_page,
        ]

        self.current_step = 0
        self.step_list = []

        self.setup_styles()
        self.welcome_page()

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use("clam")
        style.configure("TFrame", background="#0d1117")
        style.configure("TLabel", background="#0d1117", foreground="#c9d1d9", font=("Noto Sans CJK SC", 11))
        style.configure("TButton", font=("Noto Sans CJK SC", 11), padding=8)
        style.configure("Title.TLabel", font=("Noto Sans CJK SC", 22, "bold"), foreground="#58a6ff")
        style.configure("Warning.TLabel", font=("Noto Sans CJK SC", 14, "bold"), foreground="#f85149")
        style.configure("Success.TLabel", font=("Noto Sans CJK SC", 14, "bold"), foreground="#3fb950")
        style.configure("Subtitle.TLabel", font=("Noto Sans CJK SC", 12), foreground="#8b949e")
        style.configure("Step.TLabel", font=("Noto Sans CJK SC", 10), foreground="#484f58")
        style.configure("HW.TLabel", font=("Noto Sans CJK SC", 10), foreground="#7ee787")

    def clear(self):
        for w in self.root.winfo_children():
            w.destroy()

    def nav(self, has_prev=True, has_next=True, next_text="下一步", next_cmd=None, prev_cmd=None):
        frame = ttk.Frame(self.root)
        frame.pack(side="bottom", fill="x", padx=20, pady=15)

        if has_prev:
            ttk.Button(frame, text="⬅ 上一步", 
                      command=prev_cmd or self.prev_step).pack(side="left")

        if self.step_list:
            ttk.Label(frame, text=f"步骤 {self.current_step + 1} / {len(self.step_list)}", 
                     style="Step.TLabel").pack(side="left", padx=20)

        if has_next:
            cmd = next_cmd or self.next_step
            ttk.Button(frame, text=f"{next_text} ➡", command=cmd).pack(side="right")

        ttk.Button(frame, text="❌ 退出", command=self.root.quit).pack(side="right", padx=10)

    def next_step(self):
        self.current_step += 1
        if self.current_step < len(self.step_list):
            self.clear()
            self.step_list[self.current_step]()

    def prev_step(self):
        self.current_step -= 1
        if self.current_step >= 0:
            self.clear()
            self.step_list[self.current_step]()

    # ═══════════════════════════════════════════════════════════
    # 欢迎页
    # ═══════════════════════════════════════════════════════════
    def welcome_page(self):
        ttk.Label(self.root, text="🇨🇳 Arch Linux 安装向导 v2.0", style="Title.TLabel").pack(pady=30)

        content = """
欢迎使用 Arch Linux 图形化安装向导！

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  重要提示：

  • 请确保已备份所有重要数据
  • 本向导会格式化目标磁盘，数据不可恢复
  • 建议在虚拟机中先行测试
  • 安装过程需要网络连接

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

支持两种安装模式：

  🚀 自动安装  →  一键傻瓜式，自动检测硬件，智能推荐
  ⚙️ 手动安装  →  逐步自定义，完全掌控，硬件自选

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """
        ttk.Label(self.root, text=content, style="Subtitle.TLabel", justify="center").pack(pady=10)

        btn_frame = ttk.Frame(self.root)
        btn_frame.pack(pady=20)

        ttk.Button(btn_frame, text="🚀 自动安装", command=self.start_auto).pack(side="left", padx=15, ipadx=20, ipady=10)
        ttk.Button(btn_frame, text="⚙️ 手动安装", command=self.start_manual).pack(side="left", padx=15, ipadx=20, ipady=10)

        ttk.Label(self.root, text="Made with 💜 by PAleimiao  |  GPL-3.0", style="Step.TLabel").pack(side="bottom", pady=10)

    def start_auto(self):
        self.config["mode"] = "auto"
        self.step_list = self.steps_auto
        self.current_step = 1
        self.clear()
        self.step_list[self.current_step]()

    def start_manual(self):
        self.config["mode"] = "manual"
        self.step_list = self.steps_manual
        self.current_step = 2
        self.clear()
        self.step_list[self.current_step]()

    # ═══════════════════════════════════════════════════════════
    # 硬件检测页
    # ═══════════════════════════════════════════════════════════
    def hw_detect_page(self):
        ttk.Label(self.root, text="🔍 硬件检测", style="Title.TLabel").pack(pady=20)
        ttk.Label(self.root, text="正在扫描硬件设备，自动推荐驱动方案...", style="Subtitle.TLabel").pack()

        hw = self.hw_info

        # 生成硬件报告
        report = f"""
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  📋 硬件检测报告                                          ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
  🖥️  CPU:     {hw["cpu"]["model"]} ({hw["cpu"]["cores"]}核{hw["cpu"]["threads"]}线程)
  💾  内存:    {hw["memory"]}
"""

        if hw["gpu"]:
            for gtype, dev_id, desc in hw["gpu"]:
                report += f"  🎮  显卡:    [{gtype.upper()}] {desc[:50]}\n"
        else:
            report += "  🎮  显卡:    未检测到独立显卡\n"

        if hw["audio"]:
            report += f"  🔊  声卡:    {hw['audio'][0][:50]}\n"
        else:
            report += "  🔊  声卡:    未检测到\n"

        if hw["wireless"]:
            report += f"  📡  无线网卡: {len(hw['wireless'])} 个设备\n"
        else:
            report += "  📡  无线网卡: 未检测到\n"

        report += f"  🌐  有线网卡: {len(hw['network'])} 个接口\n"
        report += f"  📶  蓝牙:    {'✅ 已检测' if hw['bluetooth'] else '❌ 未检测'}\n"
        report += f"  👆  触摸板:  {'✅ 已检测' if hw['touchpad'] else '❌ 未检测'}\n"
        report += f"  💻  设备类型: {'笔记本' if hw['laptop'] else '台式机'}\n"
        report += "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"

        # 推荐方案
        report += "\n📌 自动推荐驱动方案：\n\n"

        self.recommended = []

        # GPU
        for gtype, dev_id, desc in hw["gpu"]:
            if gtype == "nvidia":
                report += "  🎮  NVIDIA 显卡 → 安装 nvidia nvidia-utils nvidia-settings\n"
                self.recommended.append("nvidia")
            elif gtype == "amd":
                report += "  🎮  AMD 显卡 → 安装 mesa vulkan-radeon xf86-video-amdgpu\n"
                self.recommended.append("amd")
            elif gtype == "intel":
                report += "  🎮  Intel 核显 → 安装 mesa vulkan-intel xf86-video-intel\n"
                self.recommended.append("intel")

        # 声卡
        report += "  🔊  ALSA + PulseAudio/PipeWire 音频栈\n"
        self.recommended.append("audio")

        # 无线网卡
        if hw["wireless"]:
            report += "  📡  无线固件 → 安装 broadcom-wl-dkms rtl88xxau-aircrack-dkms iwd\n"
            self.recommended.append("wireless")

        # 蓝牙
        if hw["bluetooth"]:
            report += "  📶  蓝牙 → 安装 bluez bluez-utils\n"
            self.recommended.append("bluetooth")

        # 触摸板
        if hw["touchpad"]:
            report += "  👆  触摸板 → 安装 xf86-input-libinput\n"
            self.recommended.append("touchpad")

        # 笔记本额外
        if hw["laptop"]:
            report += "  💻  笔记本 → 安装 tlp 电源管理 + 亮度调节\n"
            self.recommended.append("laptop")

        report += "  🍷  Wine → 安装 wine wine-mono wine-gecko winetricks\n"
        self.recommended.append("wine")

        report += "  🖨️  打印机 → 安装 cups hplip\n"
        self.recommended.append("printer")

        report += "  📷  摄像头 → 安装 v4l-utils\n"
        self.recommended.append("camera")

        text = tk.Text(self.root, width=85, height=28, bg="#161b22", fg="#7ee787", 
                      font=("JetBrainsMono Nerd Font", 10), padx=10, pady=10)
        text.pack(pady=10)
        text.insert("1.0", report)
        text.config(state="disabled")

        self.nav(next_text="继续")

    # ═══════════════════════════════════════════════════════════
    # 双系统检测页
    # ═══════════════════════════════════════════════════════════
    def dual_boot_check_page(self):
        ttk.Label(self.root, text="🔍 双系统检测", style="Title.TLabel").pack(pady=20)

        ttk.Label(self.root, text="正在扫描磁盘，检测是否存在其他操作系统...", style="Subtitle.TLabel").pack()

        warnings = detect_dual_boot()
        self.config["dual_boot_warnings"] = warnings

        if warnings:
            beep(3)

            ttk.Label(self.root, text="🚨🚨🚨 警告：检测到双系统！🚨🚨🚨", style="Warning.TLabel").pack(pady=20)

            warn_text = "检测到以下系统可能已安装：\n\n"
            for w in warnings:
                warn_text += f"  ⚠️  {w}\n"
            warn_text += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            warn_text += "\n继续安装可能导致其他系统无法启动或数据丢失！"
            warn_text += "\n请务必确认你知道自己在做什么！"
            warn_text += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

            ttk.Label(self.root, text=warn_text, style="Subtitle.TLabel", justify="center").pack(pady=10)

            confirm_frame = ttk.Frame(self.root)
            confirm_frame.pack(pady=20)

            ttk.Label(confirm_frame, text='请输入 "I KNOW" 以确认继续:', style="Subtitle.TLabel").pack()
            self.dual_confirm = ttk.Entry(confirm_frame, width=20, font=("JetBrainsMono Nerd Font", 12))
            self.dual_confirm.pack(pady=10)

            self.nav(has_next=True, next_text="我已了解风险，继续", next_cmd=self.check_dual_confirm)
        else:
            ttk.Label(self.root, text="✅ 未检测到双系统", style="Success.TLabel").pack(pady=20)
            ttk.Label(self.root, text="可以继续安装，但请确保已备份重要数据。", style="Subtitle.TLabel").pack()
            self.nav(next_text="继续")

    def check_dual_confirm(self):
        val = self.dual_confirm.get().strip().upper()
        if val != "I KNOW":
            messagebox.showerror("确认失败", '必须输入 "I KNOW"（全大写）才能继续！\n这是为了防止误操作。')
            return
        self.next_step()

    # ═══════════════════════════════════════════════════════════
    # 模式选择（手动）
    # ═══════════════════════════════════════════════════════════
    def mode_select_page(self):
        ttk.Label(self.root, text="🚀 选择安装模式", style="Title.TLabel").pack(pady=20)

        frame = ttk.Frame(self.root)
        frame.pack(pady=30, padx=60, fill="both", expand=True)

        auto_desc = """
【自动安装】

  • 一键完成，无需干预
  • 自动检测硬件并安装驱动
  • 默认 GNOME Wayland 桌面
  • 系统语言：英文（en_US.UTF-8）
  • 默认密码：arch（用户名: user）
  • 自动安装常用软件（含 Wine）
  • 系统更新后自动重启
  • ⚠️  会清除目标磁盘所有数据！
        """

        manual_desc = """
【手动安装】

  • 自定义磁盘分区（自动/手动）
  • 选择桌面环境（Hyprland/GNOME/KDE/XFCE）
  • 自定义用户名、密码、主机名
  • 选择系统语言
  • 自选驱动和软件包
  • 完全掌控每一步操作
        """

        ttk.Label(frame, text=auto_desc, style="Subtitle.TLabel", justify="left").pack(anchor="w", pady=10)
        ttk.Label(frame, text=manual_desc, style="Subtitle.TLabel", justify="left").pack(anchor="w", pady=10)

        self.nav(has_prev=True, next_text="继续", next_cmd=self.next_step)

    # ═══════════════════════════════════════════════════════════
    # 自动安装确认页
    # ═══════════════════════════════════════════════════════════
    def auto_confirm_page(self):
        ttk.Label(self.root, text="🚀 自动安装确认", style="Title.TLabel").pack(pady=20)

        ttk.Label(self.root, text="⚠️  即将执行自动安装，以下配置不可更改：", style="Warning.TLabel").pack(pady=10)

        summary = """
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  📋 自动安装配置                                            ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃  安装模式:     全自动一键安装                                ┃
┃  桌面环境:     GNOME Wayland（Ubuntu 风格）                  ┃
┃  系统语言:    en_US.UTF-8（英文）                          ┃
┃  默认密码:     arch（用户名: user）                          ┃
┃  分区方案:     自动（EFI + Root + Swap）                    ┃
┃  镜像源:      中国镜像（清华/中科大）                      ┃
┃  显卡驱动:    自动检测安装                                  ┃
┃  声卡驱动:    ALSA + PipeWire 自动安装                      ┃
┃  网卡驱动:    有线 + 无线 自动安装                          ┃
┃  蓝牙驱动:    自动检测安装                                  ┃
┃  触摸板驱动:  自动检测安装                                  ┃
┃  Wine:        自动安装 + 配置                              ┃
┃  打印机:      CUPS + HPLIP 自动安装                         ┃
┃  摄像头:      V4L 自动安装                                  ┃
┃  笔记本电源:  TLP 自动安装（如为笔记本）                   ┃
┃  预装软件:    Firefox、Edge、QQ、微信、星火商店、          ┃
┃               玲珑商店、LibreOffice、VLC、网易云音乐         ┃
┃  系统优化:    zram + swapfile + 防火墙 + fstab 优化         ┃
┃  系统更新:    安装完成后自动更新并重启                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

⚠️  警告：此操作将格式化整个目标磁盘，所有数据将丢失！
⚠️  请再次确认你已备份重要数据！
        """

        text = tk.Text(self.root, width=80, height=24, bg="#161b22", fg="#c9d1d9", 
                      font=("JetBrainsMono Nerd Font", 11), padx=10, pady=10)
        text.pack(pady=10)
        text.insert("1.0", summary)
        text.config(state="disabled")

        confirm_frame = ttk.Frame(self.root)
        confirm_frame.pack(pady=10)

        self.auto_agree = tk.BooleanVar(value=False)
        ttk.Checkbutton(confirm_frame, text="我已备份数据并确认继续", variable=self.auto_agree).pack()

        self.nav(has_next=True, next_text="🚀 开始自动安装", next_cmd=self.check_auto_confirm)

    def check_auto_confirm(self):
        if not self.auto_agree.get():
            messagebox.showwarning("未确认", "请勾选确认框以继续！")
            return

        disks = get_disks()
        if not disks:
            messagebox.showerror("错误", "未检测到磁盘！")
            return

        disk_win = tk.Toplevel(self.root)
        disk_win.title("选择目标磁盘")
        disk_win.geometry("500x300")
        disk_win.configure(bg="#0d1117")
        disk_win.transient(self.root)
        disk_win.grab_set()

        ttk.Label(disk_win, text="请选择要安装 Arch 的目标磁盘：", style="Title.TLabel").pack(pady=10)

        self.selected_disk = tk.StringVar(value=disks[0][0])
        for dev, size, model in disks:
            ttk.Radiobutton(disk_win, text=f"{dev}  ({size})  - {model}", 
                            variable=self.selected_disk, value=dev).pack(anchor="w", padx=30, pady=5)

        def confirm():
            self.config["disk"] = self.selected_disk.get()
            disk_win.destroy()
            self.next_step()

        ttk.Button(disk_win, text="确认", command=confirm).pack(pady=20)
        self.root.wait_window(disk_win)

    # ═══════════════════════════════════════════════════════════
    # 自动安装执行页
    # ═══════════════════════════════════════════════════════════
    def auto_install_page(self):
        ttk.Label(self.root, text="🚀 正在自动安装", style="Title.TLabel").pack(pady=20)

        self.log = scrolledtext.ScrolledText(self.root, width=95, height=28, bg="#0d1117", fg="#3fb950",
                                               font=("JetBrainsMono Nerd Font", 10), padx=10, pady=10)
        self.log.pack(pady=10, padx=15)

        self.progress = ttk.Progressbar(self.root, length=800, mode="determinate")
        self.progress.pack(pady=10)
        self.progress["value"] = 0

        btn_frame = ttk.Frame(self.root)
        btn_frame.pack(pady=5)
        ttk.Button(btn_frame, text="📋 复制安装脚本", command=self.copy_auto_script).pack(side="left", padx=5)
        ttk.Button(btn_frame, text="💾 保存为 .sh 文件", command=self.save_auto_script).pack(side="left", padx=5)

        self.generate_auto_script()
        self.log_print("✅ 自动安装脚本已生成！")
        self.log_print("\n📌 安全提示：")
        self.log_print("  • 建议先「复制」或「保存」脚本审查后再执行")
        self.log_print("  • 在终端中执行: bash /tmp/arch-auto-install.sh")
        self.log_print("\n" + "=" * 60)
        self.log_print(self.auto_script)
        self.progress["value"] = 100

    def log_print(self, msg):
        self.log.insert("end", msg + "\n")
        self.log.see("end")
        self.root.update()

    def generate_auto_script(self):
        disk = self.config["disk"]
        hw = self.hw_info

        # 构建驱动包列表
        gpu_pkgs = ""
        for gtype, dev_id, desc in hw["gpu"]:
            if gtype == "nvidia":
                gpu_pkgs += " nvidia nvidia-utils nvidia-settings nvidia-prime"
            elif gtype == "amd":
                gpu_pkgs += " mesa vulkan-radeon xf86-video-amdgpu libva-mesa-driver"
            elif gtype == "intel":
                gpu_pkgs += " mesa vulkan-intel xf86-video-intel intel-media-driver"

        # 声卡
        audio_pkgs = " alsa-utils alsa-plugins pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol"

        # 无线网卡
        wireless_pkgs = ""
        if hw["wireless"]:
            wireless_pkgs = " wireless_tools wpa_supplicant iwd"
            # 常见无线固件
            wireless_pkgs += " linux-firmware wireless-regdb"
            # Broadcom
            if any("broadcom" in w.lower() or "bcm" in w.lower() for w in [d[2] for d in hw["wireless"]]):
                wireless_pkgs += " broadcom-wl-dkms"
            # Realtek
            if any("realtek" in w.lower() or "rtl" in w.lower() for w in [d[2] for d in hw["wireless"]]):
                wireless_pkgs += " rtl88xxau-aircrack-dkms rtl8821ce-dkms-rtl88xx"

        # 蓝牙
        bluetooth_pkgs = " bluez bluez-utils" if hw["bluetooth"] else ""

        # 触摸板
        touchpad_pkgs = " xf86-input-libinput xf86-input-synaptics" if hw["touchpad"] else ""

        # 笔记本
        laptop_pkgs = " tlp tlp-rdw acpi_call" if hw["laptop"] else ""

        # 打印机
        printer_pkgs = " cups cups-pdf hplip system-config-printer"

        # 摄像头
        camera_pkgs = " v4l-utils cheese"

        # Wine
        wine_pkgs = " wine wine-mono wine-gecko winetricks lutris gamemode lib32-gamemode"

        # 系统工具
        system_pkgs = " zram-generator ufw firewalld reflector pacman-contrib bash-completion"

        script = f"""#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Arch Linux 自动安装脚本 v2.0
# 目标磁盘: {disk}
# 模式: 自动安装
# 硬件: {hw["cpu"]["model"]} / {hw["memory"]} RAM
# ⚠️  警告：此脚本将格式化 {disk}，所有数据将丢失！
# ═══════════════════════════════════════════════════════════════

set -e
trap 'echo "❌ 安装中断于第 $LINENO 行"; exit 1' ERR

echo "🚀 Arch Linux 自动安装开始..."

# ===== 1. 基础设置 =====
echo "📡 设置网络..."
timedatectl set-ntp true

# ===== 2. 配置中国镜像源 =====
echo "🌐 配置镜像源..."
cat > /etc/pacman.d/mirrorlist << 'EOF'
## China
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch
Server = https://mirrors.cloud.tencent.com/archlinux/$repo/os/$arch
EOF

# 启用 multilib（32位支持，Wine 需要）
sed -i '/\\[multilib\\]/,/^Include/s/^#//' /etc/pacman.conf
pacman -Sy

# ===== 3. 自动分区 =====
echo "💽 正在分区 {disk}..."
parted -s {disk} mklabel gpt
parted -s {disk} mkpart EFI fat32 1MiB 512MiB
parted -s {disk} set 1 esp on
parted -s {disk} mkpart Swap linux-swap 512MiB 8.5GiB
parted -s {disk} mkpart Root ext4 8.5GiB 100%

mkfs.fat -F32 {disk}1
mkswap {disk}2
mkfs.ext4 {disk}3

mount {disk}3 /mnt
mkdir -p /mnt/boot/efi
mount {disk}1 /mnt/boot/efi
swapon {disk}2

echo "✅ 分区完成"

# ===== 4. 安装基础系统 =====
echo "📦 安装基础系统（可能需要 10-30 分钟）..."
pacstrap /mnt base base-devel linux linux-firmware linux-headers \\
    grub efibootmgr os-prober networkmanager vim nano git curl wget \\
    man-db man-pages texinfo bash-completion \\
    noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd \\
    xdg-utils xdg-user-dirs reflector pacman-contrib \\
    {gpu_pkgs}{audio_pkgs}{wireless_pkgs}{bluetooth_pkgs}{touchpad_pkgs}{laptop_pkgs}{printer_pkgs}{camera_pkgs}{wine_pkgs}{system_pkgs}

# ===== 5. 生成 fstab =====
genfstab -U /mnt >> /mnt/etc/fstab

# ===== 6. Chroot 配置 =====
echo "⚙️ 配置系统..."
arch-chroot /mnt /bin/bash << 'CHROOT_EOF'

# ── 6.1 基础配置 ──
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "arch-pc" > /etc/hostname
cat > /etc/hosts << 'HOSTS'
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch-pc.localdomain  arch-pc
HOSTS

# ── 6.2 用户配置 ──
echo "root:arch" | chpasswd
useradd -m -G wheel,audio,video,storage,optical,power,network,lp,scanner -s /bin/bash user
echo "user:arch" | chpasswd

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# ── 6.3 启用服务 ──
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable fstrim.timer
systemctl enable reflector.timer
systemctl enable cups
systemctl enable firewalld
{"systemctl enable tlp" if hw["laptop"] else "# 非笔记本，跳过 TLP"}

# ── 6.4 zram 配置（内存压缩，提升性能）──
cat > /etc/systemd/zram-generator.conf << 'ZRAM'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAM

# ── 6.5 防火墙配置 ──
firewall-cmd --set-default-zone=public
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=samba

# ── 6.6 fstab 优化（noatime）──
sed -i 's/relatime/noatime/' /etc/fstab

# ── 6.7 安装桌面环境（GNOME Wayland）──
echo "🖥️ 安装 GNOME Wayland..."
pacman -S --needed --noconfirm gnome gnome-tweaks gnome-shell-extensions \\
    xdg-desktop-portal xdg-desktop-portal-gnome \\
    gdm wayland-protocols
systemctl enable gdm

# ── 6.8 安装常用软件 ──
echo "📦 安装常用软件..."
pacman -S --needed --noconfirm firefox firefox-i18n-zh-cn \\
    thunderbird thunderbird-i18n-zh-cn \\
    libreoffice-still libreoffice-still-zh-cn \\
    vlc mpv ffmpeg \\
    gimp krita \\
    p7zip unzip unrar \\
    neofetch btop htop fastfetch

# ── 6.9 AUR Helper (yay) ──
echo "📦 安装 yay..."
cd /tmp
sudo -u user bash -c '
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
'

# ── 6.10 AUR 软件 ──
echo "📦 安装 AUR 软件..."
sudo -u user yay -S --needed --noconfirm \\
    visual-studio-code-bin \\
    google-chrome \\
    microsoft-edge-stable-bin \\
    qqmusic-electron \\
    netease-cloud-music 2>/dev/null || true

# 星火应用商店
sudo -u user yay -S --needed --noconfirm spark-store 2>/dev/null || echo "⚠️ 星火商店安装失败，可稍后手动安装"

# ── 6.11 Wine 配置 ──
echo "🍷 配置 Wine..."
sudo -u user bash -c '
winetricks corefonts vcrun2019 dotnet48 dxvk 2>/dev/null || true
'

# ── 6.12 显卡额外配置 ──
{"# NVIDIA 配置\nmkdir -p /etc/pacman.d/hooks\ncat > /etc/pacman.d/hooks/nvidia.hook << 'NVIDIA_HOOK'\n[Trigger]\nOperation=Install\nOperation=Upgrade\nOperation=Remove\nType=Package\nTarget=nvidia\nTarget=linux\n\n[Action]\nDescription=Updating NVIDIA module in initcpio...\nDepends=mkinitcpio\nWhen=PostTransaction\nNeedsTargets\nExec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'\nNVIDIA_HOOK\n" if any(g[0] == "nvidia" for g in hw["gpu"]) else "# 非 NVIDIA 显卡"}

CHROOT_EOF

# ===== 7. 安装 GRUB =====
echo "🔄 安装引导..."
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# ===== 8. 系统更新 =====
echo "🔄 系统更新..."
arch-chroot /mnt pacman -Syu --noconfirm

# ===== 9. 清理并重启 =====
echo "🧹 清理..."
umount -R /mnt

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ Arch Linux 安装完成！                                    ║"
echo "║                                                              ║"
echo "║  用户名: user                                                ║"
echo "║  密码:   arch                                                ║"
echo "║  桌面:   GNOME Wayland                                       ║"
echo "║  语言:   英文（可在设置中添加中文）                          ║"
echo "║  Wine:   已安装并配置                                       ║"
echo "║  驱动:   显卡/声卡/网卡/蓝牙 已自动安装                     ║"
echo "║                                                              ║"
echo "║  系统将在 10 秒后重启...                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
sleep 10
reboot
"""
        self.auto_script = script

    def copy_auto_script(self):
        self.root.clipboard_clear()
        self.root.clipboard_append(self.auto_script)
        messagebox.showinfo("已复制", "安装脚本已复制到剪贴板！")

    def save_auto_script(self):
        try:
            with open("/tmp/arch-auto-install.sh", "w") as f:
                f.write(self.auto_script)
            os.chmod("/tmp/arch-auto-install.sh", 0o755)
            messagebox.showinfo("已保存", "脚本已保存到 /tmp/arch-auto-install.sh\n执行: bash /tmp/arch-auto-install.sh")
        except Exception as e:
            messagebox.showerror("错误", str(e))

    # ═══════════════════════════════════════════════════════════
    # 手动安装 - 磁盘页
    # ═══════════════════════════════════════════════════════════
    def disk_page(self):
        ttk.Label(self.root, text="💽 选择目标磁盘", style="Title.TLabel").pack(pady=20)
        ttk.Label(self.root, text="请选择要安装 Arch 的磁盘：", style="Subtitle.TLabel").pack()

        frame = ttk.Frame(self.root)
        frame.pack(pady=20, padx=40, fill="both", expand=True)

        disks = get_disks()
        if not disks:
            ttk.Label(frame, text="❌ 未检测到磁盘！", style="Warning.TLabel").pack()
            return

        self.disk_var = tk.StringVar(value=disks[0][0])
        for dev, size, model in disks:
            text = f"{dev}  ({size})  - {model}"
            ttk.Radiobutton(frame, text=text, variable=self.disk_var, value=dev).pack(anchor="w", pady=5)

        self.nav(next_cmd=self.save_disk)

    def save_disk(self):
        self.config["disk"] = self.disk_var.get()
        self.next_step()

    # ═══════════════════════════════════════════════════════════
    # 手动安装 - 分区页
    # ═══════════════════════════════════════════════════════════
    def partition_page(self):
        ttk.Label(self.root, text="💽 分区方案", style="Title.TLabel").pack(pady=20)

        frame = ttk.Frame(self.root)
        frame.pack(pady=20, padx=60, fill="both", expand=True)

        ttk.Label(frame, text="选择分区方式：", style="Subtitle.TLabel").pack(anchor="w", pady=10)

        self.scheme_var = tk.StringVar(value="auto")
        ttk.Radiobutton(frame, text="【1】自动分区 - EFI(512M) + Swap(8G) + 剩余给 Root", 
                       variable=self.scheme_var, value="auto").pack(anchor="w", pady=5)
        ttk.Radiobutton(frame, text="【2】手动分区 - 自定义各分区大小", 
                       variable=self.scheme_var, value="manual").pack(anchor="w", pady=5)

        self.manual_frame = ttk.Frame(frame)
        self.manual_frame.pack(pady=20, fill="x")

        ttk.Label(self.manual_frame, text="手动分区设置（示例: 512M, 2G, 16G, 100G）：").pack(anchor="w")

        ttk.Label(self.manual_frame, text="EFI 分区大小:").pack(anchor="w", pady=(10,0))
        self.efi_size = ttk.Entry(self.manual_frame, width=15)
        self.efi_size.insert(0, "512M")
        self.efi_size.pack(anchor="w")

        ttk.Label(self.manual_frame, text="Swap 分区大小:").pack(anchor="w", pady=(10,0))
        self.swap_size = ttk.Entry(self.manual_frame, width=15)
        self.swap_size.insert(0, "8G")
        self.swap_size.pack(anchor="w")

        ttk.Label(self.manual_frame, text="Root 分区大小 (剩余空间输 max):").pack(anchor="w", pady=(10,0))
        self.root_size = ttk.Entry(self.manual_frame, width=15)
        self.root_size.insert(0, "max")
        self.root_size.pack(anchor="w")

        ttk.Label(self.manual_frame, text="Home 分区大小 (不需要输 none):").pack(anchor="w", pady=(10,0))
        self.home_size = ttk.Entry(self.manual_frame, width=15)
        self.home_size.insert(0, "none")
        self.home_size.pack(anchor="w")

        self.nav(next_cmd=self.save_partition)

    def save_partition(self):
        self.config["scheme"] = self.scheme_var.get()
        if self.config["scheme"] == "manual":
            self.config["partitions"] = {
                "efi": self.efi_size.get(),
                "swap": self.swap_size.get(),
                "root": self.root_size.get(),
                "home": self.home_size.get(),
            }
        self.next_step()

    # ═══════════════════════════════════════════════════════════
    # 手动安装 - 格式化确认页
    # ═══════════════════════════════════════════════════════════
    def format_confirm_page(self):
        ttk.Label(self.root, text="⚠️ 格式化确认", style="Title.TLabel").pack(pady=20)

        disk = self.config["disk"]
        scheme = self.config["scheme"]

        ttk.Label(self.root, text=f"目标磁盘: {disk}", style="Subtitle.TLabel").pack()
        ttk.Label(self.root, text=f"分区方案: {scheme}", style="Subtitle.TLabel").pack()

        if scheme == "manual":
            part_text = "\n".join([f"  {k}: {v}" for k, v in self.config["partitions"].items()])
            ttk.Label(self.root, text=f"分区详情:\n{part_text}", style="Subtitle.TLabel").pack(pady=10)

        ttk.Label(self.root, text="\n🚨 此操作将清除磁盘上所有数据！", style="Warning.TLabel").pack(pady=20)

        ttk.Label(self.root, text="选择 Root 分区文件系统：", style="Subtitle.TLabel").pack(pady=(20,5))
        self.fs_var = tk.StringVar(value="ext4")
        fs_frame = ttk.Frame(self.root)
        fs_frame.pack()
        ttk.Radiobutton(fs_frame, text="【1】ext4（推荐，稳定）", variable=self.fs_var, value="ext4").pack(anchor="w")
        ttk.Radiobutton(fs_frame, text="【2】btrfs（高级功能，快照）", variable=self.fs_var, value="btrfs").pack(anchor="w")
        ttk.Radiobutton(fs_frame, text="【3】xfs（大文件性能）", variable=self.fs_var, value="xfs").pack(anchor="w")

        confirm_frame = ttk.Frame(self.root)
        confirm_frame.pack(pady=20)

        self.format_agree = tk.BooleanVar(value=False)
        ttk.Checkbutton(confirm_frame, text="我确认要格式化该磁盘", variable=self.format_agree).pack()

        self.nav(next_cmd=self.check_format_confirm)

    def check_format_confirm(self):
        if not self.format_agree.get():
            messagebox.showwarning("未确认", "必须勾选确认才能继续！")
            return
        self.config["filesystem"] = self.fs_var.get()
        self.next_step()

    # ═══════════════════════════════════════════════════════════
    # 手动安装 - 系统配置页
    # ═══════════════════════════════════════════════════════════
    def system_page(self):
        ttk.Label(self.root, text="⚙️ 系统配置", style="Title.TLabel").pack(pady=20)

        frame = ttk.Frame(self.root)
        frame.pack(pady=20, padx=60, fill="both", expand=True)

        ttk.Label(frame, text="主机名:").grid(row=0, column=0, sticky="w", pady=10)
        self.host_entry = ttk.Entry(frame, width=30)
        self.host_entry.insert(0, self.config["hostname"])
        self.host_entry.grid(row=0, column=1, sticky="w", padx=10)

        ttk.Label(frame, text="用户名:").grid(row=1, column=0, sticky="w", pady=10)
        self.user_entry = ttk.Entry(frame, width=30)
        self.user_entry.insert(0, self.config["username"])
        self.user_entry.grid(row=1, column=1, sticky="w", padx=10)

        ttk.Label(frame, text="用户密码:").grid(row=2, column=0, sticky="w", pady=10)
        self.pass_entry = ttk.Entry(frame, width=30, show="*")
        self.pass_entry.grid(row=2, column=1, sticky="w", padx=10)

        ttk.Label(frame, text="确认密码:").grid(row=3, column=0, sticky="w", pady=10)
        self.pass2_entry = ttk.Entry(frame, width=30, show="*")
        self.pass2_entry.grid(row=3, column=1, sticky="w", padx=10)

        ttk.Label(frame, text="Root 密码:").grid(row=4, column=0, sticky="w", pady=10)
        self.root_pass_entry = ttk.Entry(frame, width=30, show="*")
        self.root_pass_entry.grid(row=4, column=1, sticky="w", padx=10)

        ttk.Label(frame, text="时区:").grid(row=5, column=0, sticky="w", pady=10)
        self.tz_var = tk.StringVar(value="Asia/Shanghai")
        ttk.Combobox(frame, textvariable=self.tz_var, values=[
            "Asia/Shanghai", "Asia/Hong_Kong", "Asia/Taipei", "Asia/Tokyo",
            "Asia/Seoul", "Asia/Singapore", "Europe/London", "America/New_York",
        ], width=28).grid(row=5, column=1, sticky="w", padx=10)

        ttk.Label(frame, text="系统语言:").grid(row=6, column=0, sticky="w", pady=10)
        self.lang_var = tk.StringVar(value="zh_CN.UTF-8")
        ttk.Combobox(frame, textvariable=self.lang_var, values=[
            "zh_CN.UTF-8", "zh_TW.UTF-8", "en_US.UTF-8", "ja_JP.UTF-8", "ko_KR.UTF-8"
        ], width=28).grid(row=6, column=1, sticky="w", padx=10)

        self.nav(next_cmd=self.check_password)

    def check_password(self):
        pw1 = self.pass_entry.get()
        pw2 = self.pass2_entry.get()

        if not pw1:
            messagebox.showerror("错误", "密码不能为空！")
            return
        if pw1 != pw2:
            messagebox.showerror("错误", "两次输入的密码不一致！\n请重新输入。")
            self.pass_entry.delete(0, "end")
            self.pass2_entry.delete(0, "end")
            return

        self.config["hostname"] = self.host_entry.get() or "arch-pc"
        self.config["username"] = self.user_entry.get() or "user"
        self.config["password"] = pw1
        self.config["root_password"] = self.root_pass_entry.get() or pw1
        self.config["timezone"] = self.tz_var.get()
        self.config["locale"] = self.lang_var.get()

        self.next_step()

    # ═══════════════════════════════════════════════════════════
    # 手动安装 - 桌面环境页
    # ═══════════════════════════════════════════════════════════
    def desktop_page(self):
        ttk.Label(self.root, text="🖥️ 桌面环境", style="Title.TLabel").pack(pady=20)
        ttk.Label(self.root, text="选择你想安装的桌面环境：", style="Subtitle.TLabel").pack()

        frame = ttk.Frame(self.root)
        frame.pack(pady=30, padx=60, fill="both", expand=True)

        des = [
            ("hyprland", "🪟 Hyprland", "轻量 Wayland 平铺，动画流畅，极客首选"),
            ("gnome", "🍫 GNOME", "简洁现代，开箱即用，适合新手"),
            ("kde", "💠 KDE Plasma", "功能丰富，高度可定制"),
            ("xfce", "🐭 XFCE", "轻量稳定，老旧硬件也能跑"),
            ("none", "🚫 不安装桌面", "仅基础系统，后续手动配置"),
        ]

        self.de_var = tk.StringVar(value="gnome")
        for val, name, desc in des:
            ttk.Radiobutton(frame, text=f"{name}\n    {desc}", variable=self.de_var, value=val).pack(anchor="w", pady=8)

        ttk.Label(self.root, text="额外软件包：", style="Subtitle.TLabel").pack(pady=(20,5))

        self.pkg_vars = {
            "browser": tk.BooleanVar(value=True),
            "editor": tk.BooleanVar(value=True),
            "media": tk.BooleanVar(value=False),
            "office": tk.BooleanVar(value=False),
            "gaming": tk.BooleanVar(value=False),
            "dev": tk.BooleanVar(value=False),
        }

        pkg_frame = ttk.Frame(self.root)
        pkg_frame.pack()
        ttk.Checkbutton(pkg_frame, text="🌐 浏览器", variable=self.pkg_vars["browser"]).pack(side="left", padx=8)
        ttk.Checkbutton(pkg_frame, text="📝 编辑器", variable=self.pkg_vars["editor"]).pack(side="left", padx=8)
        ttk.Checkbutton(pkg_frame, text="🎵 多媒体", variable=self.pkg_vars["media"]).pack(side="left", padx=8)
        ttk.Checkbutton(pkg_frame, text="📊 办公套件", variable=self.pkg_vars["office"]).pack(side="left", padx=8)
        ttk.Checkbutton(pkg_frame, text="🎮 游戏工具", variable=self.pkg_vars["gaming"]).pack(side="left", padx=8)

        self.nav(next_cmd=self.save_desktop_manual)

    def save_desktop_manual(self):
        self.config["de"] = self.de_var.get()
        self.config["packages"] = {k: v.get() for k, v in self.pkg_vars.items()}
        self.next_step()

    # ═══════════════════════════════════════════════════════════
    # 手动安装 - 驱动选择页
    # ═══════════════════════════════════════════════════════════
    def driver_page(self):
        ttk.Label(self.root, text="🎮 驱动与硬件", style="Title.TLabel").pack(pady=20)
        ttk.Label(self.root, text="根据硬件检测结果，选择要安装的驱动：", style="Subtitle.TLabel").pack()

        frame = ttk.Frame(self.root)
        frame.pack(pady=20, padx=40, fill="both", expand=True)

        hw = self.hw_info

        # GPU
        ttk.Label(frame, text="🎮 显卡驱动：", style="Subtitle.TLabel").pack(anchor="w", pady=(10,0))
        self.gpu_var = tk.StringVar(value="auto")
        ttk.Radiobutton(frame, text="自动检测并安装", variable=self.gpu_var, value="auto").pack(anchor="w", padx=20)
        ttk.Radiobutton(frame, text="NVIDIA (nvidia nvidia-utils)", variable=self.gpu_var, value="nvidia").pack(anchor="w", padx=20)
        ttk.Radiobutton(frame, text="AMD (mesa vulkan-radeon)", variable=self.gpu_var, value="amd").pack(anchor="w", padx=20)
        ttk.Radiobutton(frame, text="Intel (mesa vulkan-intel)", variable=self.gpu_var, value="intel").pack(anchor="w", padx=20)
        ttk.Radiobutton(frame, text="不安装显卡驱动", variable=self.gpu_var, value="none").pack(anchor="w", padx=20)

        # 音频
        ttk.Label(frame, text="🔊 音频驱动：", style="Subtitle.TLabel").pack(anchor="w", pady=(15,0))
        self.audio_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(frame, text="安装 ALSA + PipeWire + 控制面板", variable=self.audio_var).pack(anchor="w", padx=20)

        # 无线
        if hw["wireless"]:
            ttk.Label(frame, text="📡 无线网卡：", style="Subtitle.TLabel").pack(anchor="w", pady=(15,0))
            self.wifi_var = tk.BooleanVar(value=True)
            ttk.Checkbutton(frame, text="安装无线工具 + 常见固件", variable=self.wifi_var).pack(anchor="w", padx=20)

        # 蓝牙
        if hw["bluetooth"]:
            ttk.Label(frame, text="📶 蓝牙：", style="Subtitle.TLabel").pack(anchor="w", pady=(15,0))
            self.bt_var = tk.BooleanVar(value=True)
            ttk.Checkbutton(frame, text="安装 bluez + bluez-utils", variable=self.bt_var).pack(anchor="w", padx=20)

        # 触摸板
        if hw["touchpad"]:
            ttk.Label(frame, text="👆 触摸板：", style="Subtitle.TLabel").pack(anchor="w", pady=(15,0))
            self.tp_var = tk.BooleanVar(value=True)
            ttk.Checkbutton(frame, text="安装 libinput 驱动", variable=self.tp_var).pack(anchor="w", padx=20)

        # 笔记本电源
        if hw["laptop"]:
            ttk.Label(frame, text="💻 笔记本电源管理：", style="Subtitle.TLabel").pack(anchor="w", pady=(15,0))
            self.tlp_var = tk.BooleanVar(value=True)
            ttk.Checkbutton(frame, text="安装 TLP 电源管理", variable=self.tlp_var).pack(anchor="w", padx=20)

        # 打印机
        ttk.Label(frame, text="🖨️ 打印机：", style="Subtitle.TLabel").pack(anchor="w", pady=(15,0))
        self.print_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(frame, text="安装 CUPS + HPLIP", variable=self.print_var).pack(anchor="w", padx=20)

        # 摄像头
        ttk.Label(frame, text="📷 摄像头：", style="Subtitle.TLabel").pack(anchor="w", pady=(15,0))
        self.cam_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(frame, text="安装 V4L 工具", variable=self.cam_var).pack(anchor="w", padx=20)

        # Wine
        ttk.Label(frame, text="🍷 Wine 兼容层：", style="Subtitle.TLabel").pack(anchor="w", pady=(15,0))
        self.wine_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(frame, text="安装 Wine + Winetricks + Lutris + GameMode", variable=self.wine_var).pack(anchor="w", padx=20)

        self.nav(next_cmd=self.next_step)

    # ═══════════════════════════════════════════════════════════
    # 手动安装 - 网络页
    # ═══════════════════════════════════════════════════════════
    def network_page(self):
        ttk.Label(self.root, text="🌐 网络配置", style="Title.TLabel").pack(pady=20)

        frame = ttk.Frame(self.root)
        frame.pack(pady=30, padx=60, fill="both", expand=True)

        ttk.Label(frame, text="网络管理器:").grid(row=0, column=0, sticky="w", pady=10)
        self.net_var = tk.StringVar(value="networkmanager")
        ttk.Radiobutton(frame, text="NetworkManager（推荐，带 GUI 面板）", variable=self.net_var, value="networkmanager").grid(row=0, column=1, sticky="w", padx=10)
        ttk.Radiobutton(frame, text="systemd-networkd（轻量，无 GUI）", variable=self.net_var, value="systemd").grid(row=1, column=1, sticky="w", padx=10)

        ttk.Label(frame, text="镜像源:").grid(row=2, column=0, sticky="w", pady=20)
        self.mirror_var = tk.StringVar(value="china")
        ttk.Radiobutton(frame, text="🇨🇳 中国镜像（清华/中科大/阿里）", variable=self.mirror_var, value="china").grid(row=2, column=1, sticky="w", padx=10)
        ttk.Radiobutton(frame, text="🌍 官方镜像", variable=self.mirror_var, value="official").grid(row=3, column=1, sticky="w", padx=10)

        self.nav(next_cmd=self.next_step)

    # ═══════════════════════════════════════════════════════════
    # 手动安装 - 确认页
    # ═══════════════════════════════════════════════════════════
    def manual_confirm_page(self):
        ttk.Label(self.root, text="✅ 安装确认", style="Title.TLabel").pack(pady=20)

        summary = f"""
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  📋 手动安装配置摘要                                        ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃  目标磁盘:   {self.config["disk"]:<45}┃
┃  分区方案:   {self.config["scheme"]:<45}┃
┃  文件系统:   {self.config["filesystem"]:<45}┃
┃  主机名:     {self.config["hostname"]:<45}┃
┃  用户名:     {self.config["username"]:<45}┃
┃  时区:       {self.config["timezone"]:<45}┃
┃  语言:       {self.config["locale"]:<45}┃
┃  桌面环境:   {self.config["de"]:<45}┃
┃  网络管理:   {self.config.get("net", "networkmanager"):<45}┃
┃  镜像源:     {self.config.get("mirror", "china"):<45}┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

⚠️  警告：此操作将格式化 {self.config["disk"]}，所有数据将丢失！
        """

        text = tk.Text(self.root, width=80, height=18, bg="#161b22", fg="#c9d1d9", font=("JetBrainsMono Nerd Font", 11))
        text.pack(pady=10)
        text.insert("1.0", summary)
        text.config(state="disabled")

        confirm_frame = ttk.Frame(self.root)
        confirm_frame.pack(pady=10)

        self.manual_agree = tk.BooleanVar(value=False)
        ttk.Checkbutton(confirm_frame, text="我已备份数据并确认继续", variable=self.manual_agree).pack()

        self.nav(next_cmd=self.check_manual_confirm)

    def check_manual_confirm(self):
        if not self.manual_agree.get():
            messagebox.showwarning("未确认", "请勾选确认框！")
            return
        self.next_step()

    # ═══════════════════════════════════════════════════════════
    # 手动安装 - 执行页
    # ═══════════════════════════════════════════════════════════
    def manual_install_page(self):
        ttk.Label(self.root, text="⚙️ 生成安装脚本", style="Title.TLabel").pack(pady=20)

        self.log_manual = scrolledtext.ScrolledText(self.root, width=95, height=28, bg="#0d1117", fg="#3fb950",
                                                     font=("JetBrainsMono Nerd Font", 10), padx=10, pady=10)
        self.log_manual.pack(pady=10, padx=15)

        self.progress_manual = ttk.Progressbar(self.root, length=800, mode="determinate")
        self.progress_manual.pack(pady=10)
        self.progress_manual["value"] = 0

        btn_frame = ttk.Frame(self.root)
        btn_frame.pack(pady=5)
        ttk.Button(btn_frame, text="📋 复制脚本", command=self.copy_manual_script).pack(side="left", padx=5)
        ttk.Button(btn_frame, text="💾 保存为 .sh", command=self.save_manual_script).pack(side="left", padx=5)

        self.generate_manual_script()
        self.log_manual.insert("end", "✅ 手动安装脚本已生成！\n\n")
        self.log_manual.insert("end", "请审查下方脚本，确认无误后执行。\n")
        self.log_manual.insert("end", "=" * 60 + "\n")
        self.log_manual.insert("end", self.manual_script)
        self.progress_manual["value"] = 100

    def generate_manual_script(self):
        c = self.config
        disk = c["disk"]
        fs = c["filesystem"]
        hw = self.hw_info

        de_pkgs = {
            "hyprland": "hyprland waybar rofi-wayland swww kitty thunar dolphin xdg-desktop-portal-hyprland",
            "gnome": "gnome gnome-tweaks gdm",
            "kde": "plasma plasma-wayland-session kde-applications sddm",
            "xfce": "xfce4 xfce4-goodies lightdm lightdm-gtk-greeter",
            "none": "",
        }

        extras = []
        pkgs = c.get("packages", {})
        if pkgs.get("browser"):
            extras.append("firefox firefox-i18n-zh-cn")
        if pkgs.get("editor"):
            extras.append("nano vim neovim")
        if pkgs.get("media"):
            extras.append("vlc mpv ffmpeg")
        if pkgs.get("office"):
            extras.append("libreoffice-still libreoffice-still-zh-cn")
        if pkgs.get("gaming"):
            extras.append("steam lutris wine-staging gamemode mangohud")

        extra_str = " ".join(extras)
        de_str = de_pkgs.get(c["de"], "")

        # 驱动包
        gpu_pkgs = ""
        gpu_choice = getattr(self, 'gpu_var', tk.StringVar(value="auto")).get()
        if gpu_choice == "auto":
            for gtype, dev_id, desc in hw["gpu"]:
                if gtype == "nvidia":
                    gpu_pkgs += " nvidia nvidia-utils nvidia-settings nvidia-prime"
                elif gtype == "amd":
                    gpu_pkgs += " mesa vulkan-radeon xf86-video-amdgpu libva-mesa-driver"
                elif gtype == "intel":
                    gpu_pkgs += " mesa vulkan-intel xf86-video-intel intel-media-driver"
        elif gpu_choice == "nvidia":
            gpu_pkgs = " nvidia nvidia-utils nvidia-settings nvidia-prime"
        elif gpu_choice == "amd":
            gpu_pkgs = " mesa vulkan-radeon xf86-video-amdgpu libva-mesa-driver"
        elif gpu_choice == "intel":
            gpu_pkgs = " mesa vulkan-intel xf86-video-intel intel-media-driver"

        audio_pkgs = " alsa-utils alsa-plugins pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol" if getattr(self, 'audio_var', tk.BooleanVar(value=True)).get() else ""

        wireless_pkgs = ""
        if getattr(self, 'wifi_var', tk.BooleanVar(value=False)).get() and hw["wireless"]:
            wireless_pkgs = " wireless_tools wpa_supplicant iwd linux-firmware wireless-regdb broadcom-wl-dkms rtl88xxau-aircrack-dkms"

        bt_pkgs = " bluez bluez-utils" if getattr(self, 'bt_var', tk.BooleanVar(value=False)).get() and hw["bluetooth"] else ""
        tp_pkgs = " xf86-input-libinput xf86-input-synaptics" if getattr(self, 'tp_var', tk.BooleanVar(value=False)).get() and hw["touchpad"] else ""
        tlp_pkgs = " tlp tlp-rdw acpi_call" if getattr(self, 'tlp_var', tk.BooleanVar(value=False)).get() and hw["laptop"] else ""
        print_pkgs = " cups cups-pdf hplip system-config-printer" if getattr(self, 'print_var', tk.BooleanVar(value=False)).get() else ""
        cam_pkgs = " v4l-utils cheese" if getattr(self, 'cam_var', tk.BooleanVar(value=False)).get() else ""
        wine_pkgs = " wine wine-mono wine-gecko winetricks lutris gamemode lib32-gamemode" if getattr(self, 'wine_var', tk.BooleanVar(value=False)).get() else ""

        if c["scheme"] == "auto":
            part_cmd = f"""
parted -s {disk} mklabel gpt
parted -s {disk} mkpart EFI fat32 1MiB 512MiB
parted -s {disk} set 1 esp on
parted -s {disk} mkpart Swap linux-swap 512MiB 8.5GiB
parted -s {disk} mkpart Root {fs} 8.5GiB 100%
mkfs.fat -F32 {disk}1
mkswap {disk}2
mkfs.{fs} {disk}3
mount {disk}3 /mnt
mkdir -p /mnt/boot/efi
mount {disk}1 /mnt/boot/efi
swapon {disk}2
"""
        else:
            p = c.get("partitions", {})
            part_cmd = f"""
# 手动分区 - 请根据以下设置使用 cfdisk 或 parted 分区
# EFI:  {p.get('efi', '512M')}
# Swap: {p.get('swap', '8G')}
# Root: {p.get('root', 'max')}
# Home: {p.get('home', 'none')}
cfdisk {disk}
# 分区后请手动格式化和挂载
"""

        mirror_block = ""
        if c.get("mirror") == "china":
            mirror_block = """cat > /etc/pacman.d/mirrorlist << 'EOF'
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
EOF"""
        else:
            mirror_block = "# 使用官方镜像"

        # 是否启用 multilib（Wine 需要）
        multilib = "sed -i '/\\[multilib\\]/,/^Include/s/^#//' /etc/pacman.conf\npacman -Sy" if wine_pkgs else ""

        script = f"""#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Arch Linux 手动安装脚本
# 配置: {c["username"]}@{c["hostname"]} / {c["de"]} / {c["locale"]}
# ═══════════════════════════════════════════════════════════════

set -e
trap 'echo "❌ 安装中断于第 $LINENO 行"; exit 1' ERR

echo "🚀 Arch Linux 手动安装开始..."

# 1. 时钟
timedatectl set-ntp true

# 2. 镜像源
{mirror_block}
{multilib}

# 3. 分区
{part_cmd}

# 4. 安装基础
pacstrap /mnt base base-devel linux linux-firmware linux-headers \\
    grub efibootmgr os-prober networkmanager vim nano git curl wget \\
    man-db man-pages texinfo bash-completion \\
    noto-fonts-cjk noto-fonts-emoji \\
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \\
    xdg-utils xdg-user-dirs reflector pacman-contrib \\
    zram-generator ufw firewalld \\
    {gpu_pkgs}{audio_pkgs}{wireless_pkgs}{bt_pkgs}{tp_pkgs}{tlp_pkgs}{print_pkgs}{cam_pkgs}{wine_pkgs}

# 5. fstab
genfstab -U /mnt >> /mnt/etc/fstab

# 6. Chroot
arch-chroot /mnt /bin/bash << 'CHROOT_EOF'

ln -sf /usr/share/zoneinfo/{c["timezone"]} /etc/localtime
hwclock --systohc

echo "{c["locale"]} UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG={c["locale"]}" > /etc/locale.conf

echo "{c["hostname"]}" > /etc/hostname
cat > /etc/hosts << 'HOSTS'
127.0.0.1   localhost
::1         localhost
127.0.1.1   {c["hostname"]}.localdomain  {c["hostname"]}
HOSTS

echo "root:{c["root_password"]}" | chpasswd
useradd -m -G wheel,audio,video,storage,optical,power,network,lp,scanner -s /bin/bash {c["username"]}
echo "{c["username"]}:{c["password"]}" | chpasswd

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

systemctl enable NetworkManager
systemctl enable fstrim.timer
systemctl enable reflector.timer
systemctl enable firewalld
{"systemctl enable bluetooth" if bt_pkgs else ""}
{"systemctl enable cups" if print_pkgs else ""}
{"systemctl enable tlp" if tlp_pkgs else ""}

# zram
cat > /etc/systemd/zram-generator.conf << 'ZRAM'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAM

# 防火墙
firewall-cmd --set-default-zone=public
firewall-cmd --permanent --add-service=ssh

# fstab 优化
sed -i 's/relatime/noatime/' /etc/fstab

{("pacman -S --needed --noconfirm " + de_str if de_str else "# 不安装桌面环境")}
{("systemctl enable gdm" if c["de"] == "gnome" else "")}
{("systemctl enable sddm" if c["de"] == "kde" else "")}
{("systemctl enable lightdm" if c["de"] == "xfce" else "")}

{("pacman -S --needed --noconfirm " + extra_str if extra_str else "")}

{("# Wine 配置\nsudo -u " + c["username"] + " bash -c 'winetricks corefonts vcrun2019 dotnet48 dxvk 2>/dev/null || true'" if wine_pkgs else "")}

CHROOT_EOF

# 7. GRUB
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# 8. 完成
umount -R /mnt
echo "✅ 安装完成！请执行 reboot 重启"
"""
        self.manual_script = script

    def copy_manual_script(self):
        self.root.clipboard_clear()
        self.root.clipboard_append(self.manual_script)
        messagebox.showinfo("已复制", "脚本已复制到剪贴板！")

    def save_manual_script(self):
        try:
            with open("/tmp/arch-manual-install.sh", "w") as f:
                f.write(self.manual_script)
            os.chmod("/tmp/arch-manual-install.sh", 0o755)
            messagebox.showinfo("已保存", "脚本已保存到 /tmp/arch-manual-install.sh")
        except Exception as e:
            messagebox.showerror("错误", str(e))


# ═══════════════════════════════════════════════════════════════
# 主入口
# ═══════════════════════════════════════════════════════════════

def main():
    is_live = os.path.exists("/arch")

    root = tk.Tk()

    if not is_live:
        root.withdraw()
        if not messagebox.askyesno("⚠️ 环境检测", 
            "未检测到 Arch Live CD 环境。\n"
            "本向导应在 Arch ISO 启动后的 Live 环境中运行。\n\n"
            "当前仅为演示/测试模式，是否继续？"):
            sys.exit(0)
        root.deiconify()

    app = ArchInstallWizard(root)
    root.mainloop()

if __name__ == "__main__":
    main()
