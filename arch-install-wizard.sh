#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Arch Linux 安装向导 (Bash + Dialog 版)
# 无需 Python，Arch Live CD 直接运行
# 作者: PAleimiao
# 协议: GPL-3.0
# ═══════════════════════════════════════════════════════════════

set -e

# ── 颜色定义 ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── 全局配置 ──
declare -A CFG
CFG[mode]=""
CFG[disk]=""
CFG[scheme]="auto"
CFG[hostname]="arch-pc"
CFG[username]="user"
CFG[password]=""
CFG[root_password]=""
CFG[de]="gnome"
CFG[timezone]="Asia/Shanghai"
CFG[locale]="en_US.UTF-8"
CFG[filesystem]="ext4"
CFG[swap_size]="8G"
CFG[efi_size]="512M"
CFG[mirror]="china"
CFG[gpu]="auto"
CFG[install_audio]="yes"
CFG[install_wifi]="yes"
CFG[install_bt]="yes"
CFG[install_touchpad]="yes"
CFG[install_tlp]="yes"
CFG[install_printer]="no"
CFG[install_camera]="no"
CFG[install_wine]="yes"
CFG[pkg_browser]="yes"
CFG[pkg_editor]="yes"
CFG[pkg_media]="no"
CFG[pkg_office]="no"
CFG[pkg_gaming]="no"

# ── 工具函数 ──

beep() {
    local count=${1:-3}
    for ((i=0; i<count; i++)); do
        printf '\a'
        sleep 0.3
    done
}

msg_box() {
    dialog --title "$1" --msgbox "$2" 15 60
}

yes_no() {
    dialog --title "$1" --yesno "$2" 10 60
    return $?
}

input_box() {
    dialog --title "$1" --inputbox "$2" 10 60 "$3" 2>&1 >/dev/tty
}

password_box() {
    dialog --title "$1" --passwordbox "$2" 10 60 2>&1 >/dev/tty
}

menu_box() {
    local title="$1"
    local text="$2"
    shift 2
    dialog --title "$title" --menu "$text" 20 70 15 "$@" 2>&1 >/dev/tty
}

checklist_box() {
    local title="$1"
    local text="$2"
    shift 2
    dialog --title "$title" --checklist "$text" 20 70 15 "$@" 2>&1 >/dev/tty
}

# ── 硬件检测 ──

detect_cpu() {
    local vendor=$(grep -m1 "vendor_id" /proc/cpuinfo | cut -d: -f2 | xargs)
    local model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)
    local cores=$(grep -m1 "cpu cores" /proc/cpuinfo | cut -d: -f2 | xargs)
    echo "CPU: ${model} (${cores}核)"
}

detect_gpu() {
    local gpus=$(lspci -nn | grep -E "VGA|3D|Display" || true)
    local gpu_list=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if echo "$line" | grep -qi "nvidia"; then
            gpu_list="${gpu_list}NVIDIA "
        elif echo "$line" | grep -qi "amd\|ati"; then
            gpu_list="${gpu_list}AMD "
        elif echo "$line" | grep -qi "intel"; then
            gpu_list="${gpu_list}Intel "
        fi
    done <<< "$gpus"
    echo "$gpu_list"
}

detect_audio() {
    if [[ -f /proc/asound/cards ]]; then
        head -1 /proc/asound/cards | sed 's/^[0-9]* \[//' | sed 's/\]:/:/'
    else
        echo "未检测到"
    fi
}

detect_wireless() {
    local wifi=$(lspci -nn | grep -i "network\|wireless\|wifi" | wc -l)
    if [[ $wifi -gt 0 ]]; then
        echo "已检测 ($wifi 个设备)"
    else
        echo "未检测"
    fi
}

detect_bluetooth() {
    if lsusb 2>/dev/null | grep -qi "bluetooth"; then
        echo "已检测"
    else
        echo "未检测"
    fi
}

detect_touchpad() {
    if [[ -f /proc/bus/input/devices ]] && grep -qi "touchpad" /proc/bus/input/devices; then
        echo "已检测"
    else
        echo "未检测"
    fi
}

detect_laptop() {
    local chassis=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)
    if [[ "$chassis" =~ ^(8|9|10|14)$ ]]; then
        echo "是"
    else
        echo "否"
    fi
}

detect_memory() {
    free -h | awk '/Mem/{print $2}'
}

get_disks() {
    lsblk -d -n -o NAME,SIZE,MODEL,TYPE | awk '$4=="disk" {print "/dev/"$1, $2, $3}'
}

detect_dual_boot() {
    local warnings=""
    # 检查 EFI 中的其他系统
    if [[ -d /sys/firmware/efi/efivars ]]; then
        if [[ -d /boot/efi/EFI ]]; then
            for dir in /boot/efi/EFI/*/; do
                local name=$(basename "$dir" | tr '[:upper:]' '[:lower:]')
                case "$name" in
                    microsoft|windows|ubuntu|debian|fedora|opensuse|manjaro)
                        warnings="${warnings}检测到 $name 系统引导\\n"
                        ;;
                esac
            done
        fi
    fi
    # 检查 NTFS
    if lsblk -o FSTYPE -n | grep -qi "ntfs"; then
        warnings="${warnings}检测到 NTFS 分区 (可能为 Windows)\\n"
    fi
    echo -e "$warnings"
}

# ── 页面函数 ──

page_welcome() {
    dialog --title "Arch Linux 安装向导" --msgbox "
    Arch Linux 图形化安装向导
    ==========================

    欢迎使用 Arch Linux 安装向导！

    重要提示：
    - 请确保已备份所有重要数据
    - 本向导会格式化目标磁盘
    - 建议在虚拟机中先行测试

    支持两种安装模式：
    [AUTO] 自动安装 -> 一键傻瓜式
    [CFG]  手动安装 -> 逐步自定义
" 20 60

    local choice=$(menu_box "选择安装模式" "请选择安装模式:" \
        "auto" "[AUTO] 自动安装 - 一键完成，默认配置" \
        "manual" "[CFG] 手动安装 - 逐步自定义" 2>&1 >/dev/tty)

    CFG[mode]="$choice"
}

page_hw_detect() {
    local cpu=$(detect_cpu)
    local gpu=$(detect_gpu)
    local audio=$(detect_audio)
    local wifi=$(detect_wireless)
    local bt=$(detect_bluetooth)
    local tp=$(detect_touchpad)
    local laptop=$(detect_laptop)
    local mem=$(detect_memory)

    dialog --title "硬件检测" --msgbox "
    硬件检测报告
    ============

    CPU:     $cpu
    内存:    $mem
    显卡:    $gpu
    声卡:    $audio
    无线:    $wifi
    蓝牙:    $bt
    触摸板:  $tp
    笔记本:  $laptop

    向导将根据检测结果推荐驱动方案。
" 18 65
}

page_dual_boot_check() {
    local warnings=$(detect_dual_boot)

    if [[ -n "$warnings" ]]; then
        beep 3
        dialog --title "[!!!] 双系统检测警告" --msgbox "
    [!!!] 警告：检测到双系统！

    $warnings

    继续安装可能导致其他系统无法启动！
    请务必确认你知道自己在做什么！

    下一步需要输入确认信息。
" 20 65

        local confirm=$(input_box "确认" "请输入 I KNOW 以确认继续:" "")
        if [[ "$confirm" != "I KNOW" ]]; then
            dialog --title "错误" --msgbox "确认失败！必须输入 I KNOW（全大写）才能继续。" 8 50
            exit 1
        fi
    else
        dialog --title "[OK] 双系统检测" --msgbox "未检测到双系统，可以继续安装。" 8 50
    fi
}

page_disk_select() {
    local disks=()
    while IFS=' ' read -r dev size model; do
        disks+=("$dev" "$size - $model")
    done <<< "$(get_disks)"

    if [[ ${#disks[@]} -eq 0 ]]; then
        dialog --title "错误" --msgbox "未检测到磁盘！" 8 40
        exit 1
    fi

    CFG[disk]=$(menu_box "选择磁盘" "请选择要安装 Arch 的目标磁盘:" "${disks[@]}")
}

page_partition() {
    local choice=$(menu_box "分区方案" "选择分区方式:" \
        "auto" "自动分区 - EFI(512M) + Swap(8G) + Root(剩余)" \
        "manual" "手动分区 - 使用 cfdisk 自行划分" 2>&1 >/dev/tty)

    CFG[scheme]="$choice"

    if [[ "$choice" == "manual" ]]; then
        CFG[efi_size]=$(input_box "EFI 分区" "EFI 分区大小 (如 512M):" "512M")
        CFG[swap_size]=$(input_box "Swap 分区" "Swap 分区大小 (如 8G):" "8G")
        local root_size=$(input_box "Root 分区" "Root 分区大小 (输 max 表示剩余全部):" "max")
        local home_size=$(input_box "Home 分区" "Home 分区大小 (不需要输 none):" "none")
    fi
}

page_format_confirm() {
    dialog --title "[!] 格式化确认" --yesno "
    即将格式化磁盘: ${CFG[disk]}
    分区方案: ${CFG[scheme]}

    [!] 警告：此操作将清除磁盘上所有数据！
    [!] 所有数据将不可恢复！

    是否确认继续？
" 15 60

    if [[ $? -ne 0 ]]; then
        dialog --title "已取消" --msgbox "安装已取消。" 8 40
        exit 0
    fi

    local fs=$(menu_box "文件系统" "选择 Root 分区文件系统:" \
        "ext4" "ext4 - 推荐，稳定可靠" \
        "btrfs" "btrfs - 高级功能，支持快照" \
        "xfs" "xfs - 大文件性能优秀" 2>&1 >/dev/tty)
    CFG[filesystem]="$fs"
}

page_system_config() {
    CFG[hostname]=$(input_box "主机名" "设置主机名:" "${CFG[hostname]}")
    CFG[username]=$(input_box "用户名" "设置用户名:" "${CFG[username]}")

    while true; do
        local pw1=$(password_box "用户密码" "设置用户密码:")
        local pw2=$(password_box "确认密码" "再次输入用户密码:")

        if [[ "$pw1" != "$pw2" ]]; then
            dialog --title "错误" --msgbox "两次输入的密码不一致！请重新输入。" 8 50
        elif [[ -z "$pw1" ]]; then
            dialog --title "错误" --msgbox "密码不能为空！" 8 40
        else
            CFG[password]="$pw1"
            break
        fi
    done

    local root_pw=$(password_box "Root 密码" "设置 Root 密码 (留空则与用户密码相同):")
    if [[ -z "$root_pw" ]]; then
        CFG[root_password]="${CFG[password]}"
    else
        CFG[root_password]="$root_pw"
    fi

    CFG[timezone]=$(menu_box "时区" "选择时区:" \
        "Asia/Shanghai" "上海 (中国)" \
        "Asia/Hong_Kong" "香港" \
        "Asia/Taipei" "台北" \
        "Asia/Tokyo" "东京" \
        "Europe/London" "伦敦" \
        "America/New_York" "纽约" 2>&1 >/dev/tty)

    CFG[locale]=$(menu_box "系统语言" "选择系统语言:" \
        "zh_CN.UTF-8" "简体中文" \
        "zh_TW.UTF-8" "繁体中文" \
        "en_US.UTF-8" "英文" \
        "ja_JP.UTF-8" "日文" \
        "ko_KR.UTF-8" "韩文" 2>&1 >/dev/tty)
}

page_desktop() {
    CFG[de]=$(menu_box "桌面环境" "选择桌面环境:" \
        "gnome" "GNOME - 简洁现代，适合新手" \
        "kde" "KDE Plasma - 功能丰富，高度定制" \
        "xfce" "XFCE - 轻量稳定" \
        "hyprland" "Hyprland - Wayland 平铺，极客首选" \
        "none" "不安装桌面 - 仅基础系统" 2>&1 >/dev/tty)

    local pkgs=$(checklist_box "额外软件" "选择要安装的额外软件:" \
        "browser" "浏览器 (Firefox)" on \
        "editor" "编辑器 (Vim/Nano)" on \
        "media" "多媒体 (VLC/MPV)" off \
        "office" "办公套件 (LibreOffice)" off \
        "gaming" "游戏工具 (Steam/Lutris)" off 2>&1 >/dev/tty)

    [[ "$pkgs" == *"browser"* ]] && CFG[pkg_browser]="yes" || CFG[pkg_browser]="no"
    [[ "$pkgs" == *"editor"* ]] && CFG[pkg_editor]="yes" || CFG[pkg_editor]="no"
    [[ "$pkgs" == *"media"* ]] && CFG[pkg_media]="yes" || CFG[pkg_media]="no"
    [[ "$pkgs" == *"office"* ]] && CFG[pkg_office]="yes" || CFG[pkg_office]="no"
    [[ "$pkgs" == *"gaming"* ]] && CFG[pkg_gaming]="yes" || CFG[pkg_gaming]="no"
}

page_driver() {
    local gpu=$(detect_gpu)

    local drivers=$(checklist_box "驱动选择" "根据硬件检测，选择要安装的驱动:" \
        "gpu" "显卡驱动 ($gpu)" on \
        "audio" "声卡驱动 (ALSA/PipeWire)" on \
        "wifi" "无线网卡驱动" on \
        "bt" "蓝牙驱动" on \
        "touchpad" "触摸板驱动" on \
        "tlp" "笔记本电源管理 (TLP)" on \
        "printer" "打印机驱动 (CUPS)" off \
        "camera" "摄像头驱动 (V4L)" off \
        "wine" "Wine 兼容层 + Lutris" on 2>&1 >/dev/tty)

    [[ "$drivers" == *"audio"* ]] && CFG[install_audio]="yes" || CFG[install_audio]="no"
    [[ "$drivers" == *"wifi"* ]] && CFG[install_wifi]="yes" || CFG[install_wifi]="no"
    [[ "$drivers" == *"bt"* ]] && CFG[install_bt]="yes" || CFG[install_bt]="no"
    [[ "$drivers" == *"touchpad"* ]] && CFG[install_touchpad]="yes" || CFG[install_touchpad]="no"
    [[ "$drivers" == *"tlp"* ]] && CFG[install_tlp]="yes" || CFG[install_tlp]="no"
    [[ "$drivers" == *"printer"* ]] && CFG[install_printer]="yes" || CFG[install_printer]="no"
    [[ "$drivers" == *"camera"* ]] && CFG[install_camera]="yes" || CFG[install_camera]="no"
    [[ "$drivers" == *"wine"* ]] && CFG[install_wine]="yes" || CFG[install_wine]="no"
}

page_network() {
    CFG[mirror]=$(menu_box "镜像源" "选择软件源:" \
        "china" "中国镜像 (清华/中科大/阿里)" \
        "official" "官方镜像" 2>&1 >/dev/tty)
}

page_confirm() {
    local summary="
    安装配置摘要
    ============

    目标磁盘:   ${CFG[disk]}
    分区方案:   ${CFG[scheme]}
    文件系统:   ${CFG[filesystem]}
    主机名:     ${CFG[hostname]}
    用户名:     ${CFG[username]}
    时区:       ${CFG[timezone]}
    语言:       ${CFG[locale]}
    桌面环境:   ${CFG[de]}
    镜像源:     ${CFG[mirror]}

    [!] 警告：此操作将格式化 ${CFG[disk]}！
"

    dialog --title "安装确认" --yesno "$summary" 20 60
    if [[ $? -ne 0 ]]; then
        dialog --title "已取消" --msgbox "安装已取消。" 8 40
        exit 0
    fi
}

# ── 脚本生成 ──

generate_script() {
    local disk="${CFG[disk]}"
    local fs="${CFG[filesystem]}"

    # 构建包列表
    local gpu_pkgs=""
    local gpu=$(detect_gpu)
    if [[ "$gpu" == *"NVIDIA"* ]]; then
        gpu_pkgs="nvidia nvidia-utils nvidia-settings nvidia-prime"
    elif [[ "$gpu" == *"AMD"* ]]; then
        gpu_pkgs="mesa vulkan-radeon xf86-video-amdgpu libva-mesa-driver"
    elif [[ "$gpu" == *"Intel"* ]]; then
        gpu_pkgs="mesa vulkan-intel xf86-video-intel intel-media-driver"
    fi

    local audio_pkgs=""
    [[ "${CFG[install_audio]}" == "yes" ]] && audio_pkgs="alsa-utils alsa-plugins pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol"

    local wifi_pkgs=""
    [[ "${CFG[install_wifi]}" == "yes" ]] && wifi_pkgs="wireless_tools wpa_supplicant iwd linux-firmware wireless-regdb broadcom-wl-dkms rtl88xxau-aircrack-dkms"

    local bt_pkgs=""
    [[ "${CFG[install_bt]}" == "yes" ]] && bt_pkgs="bluez bluez-utils"

    local tp_pkgs=""
    [[ "${CFG[install_touchpad]}" == "yes" ]] && tp_pkgs="xf86-input-libinput xf86-input-synaptics"

    local tlp_pkgs=""
    [[ "${CFG[install_tlp]}" == "yes" && "$(detect_laptop)" == "是" ]] && tlp_pkgs="tlp tlp-rdw acpi_call"

    local print_pkgs=""
    [[ "${CFG[install_printer]}" == "yes" ]] && print_pkgs="cups cups-pdf hplip system-config-printer"

    local cam_pkgs=""
    [[ "${CFG[install_camera]}" == "yes" ]] && cam_pkgs="v4l-utils cheese"

    local wine_pkgs=""
    [[ "${CFG[install_wine]}" == "yes" ]] && wine_pkgs="wine wine-mono wine-gecko winetricks lutris gamemode lib32-gamemode"

    local extra_pkgs=""
    [[ "${CFG[pkg_browser]}" == "yes" ]] && extra_pkgs="$extra_pkgs firefox firefox-i18n-zh-cn"
    [[ "${CFG[pkg_editor]}" == "yes" ]] && extra_pkgs="$extra_pkgs nano vim neovim"
    [[ "${CFG[pkg_media]}" == "yes" ]] && extra_pkgs="$extra_pkgs vlc mpv ffmpeg"
    [[ "${CFG[pkg_office]}" == "yes" ]] && extra_pkgs="$extra_pkgs libreoffice-still libreoffice-still-zh-cn"
    [[ "${CFG[pkg_gaming]}" == "yes" ]] && extra_pkgs="$extra_pkgs steam lutris mangohud"

    local de_pkgs=""
    case "${CFG[de]}" in
        gnome) de_pkgs="gnome gnome-tweaks gdm" ;;
        kde) de_pkgs="plasma plasma-wayland-session kde-applications sddm" ;;
        xfce) de_pkgs="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter" ;;
        hyprland) de_pkgs="hyprland waybar rofi-wayland swww kitty thunar dolphin xdg-desktop-portal-hyprland" ;;
    esac

    local dm_enable=""
    [[ "${CFG[de]}" == "gnome" ]] && dm_enable="systemctl enable gdm"
    [[ "${CFG[de]}" == "kde" ]] && dm_enable="systemctl enable sddm"
    [[ "${CFG[de]}" == "xfce" ]] && dm_enable="systemctl enable lightdm"

    local mirror_block=""
    if [[ "${CFG[mirror]}" == "china" ]]; then
        mirror_block="cat > /etc/pacman.d/mirrorlist << 'MIRROR'
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.aliyun.com/archlinux/\$repo/os/\$arch
MIRROR"
    fi

    local multilib=""
    [[ -n "$wine_pkgs" ]] && multilib="sed -i '/\\[multilib\\]/,/^Include/s/^#//' /etc/pacman.conf
pacman -Sy"

    local part_cmd=""
    if [[ "${CFG[scheme]}" == "auto" ]]; then
        part_cmd="parted -s $disk mklabel gpt
parted -s $disk mkpart EFI fat32 1MiB 512MiB
parted -s $disk set 1 esp on
parted -s $disk mkpart Swap linux-swap 512MiB 8.5GiB
parted -s $disk mkpart Root $fs 8.5GiB 100%
mkfs.fat -F32 ${disk}1
mkswap ${disk}2
mkfs.$fs ${disk}3
mount ${disk}3 /mnt
mkdir -p /mnt/boot/efi
mount ${disk}1 /mnt/boot/efi
swapon ${disk}2"
    else
        part_cmd="# 手动分区 - 请使用 cfdisk $disk 分区后，手动格式化和挂载"
    fi

    cat > /tmp/arch-install.sh << EOF
#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Arch Linux 安装脚本
# 生成时间: $(date)
# 配置: ${CFG[username]}@${CFG[hostname]} / ${CFG[de]} / ${CFG[locale]}
# ═══════════════════════════════════════════════════════════════

set -e
trap 'echo "[!] 安装中断于第 \$LINENO 行"; exit 1' ERR

echo "[AUTO] Arch Linux 安装开始..."

# 1. 基础设置
echo "[NET] 设置网络..."
timedatectl set-ntp true

# 2. 镜像源
echo "[MIRROR] 配置镜像源..."
$mirror_block
$multilib

# 3. 分区
echo "[DISK] 正在分区 $disk..."
$part_cmd

echo "[OK] 分区完成"

# 4. 安装基础系统
echo "[PKG] 安装基础系统（可能需要 10-30 分钟）..."
pacstrap /mnt base base-devel linux linux-firmware linux-headers \\
    grub efibootmgr os-prober networkmanager vim nano git curl wget \\
    man-db man-pages texinfo bash-completion \\
    noto-fonts-cjk noto-fonts-emoji \\
    xdg-utils xdg-user-dirs reflector pacman-contrib \\
    zram-generator ufw firewalld \\
    $gpu_pkgs $audio_pkgs $wifi_pkgs $bt_pkgs $tp_pkgs $tlp_pkgs $print_pkgs $cam_pkgs $wine_pkgs

# 5. fstab
genfstab -U /mnt >> /mnt/etc/fstab

# 6. Chroot
echo "[CFG] 配置系统..."
arch-chroot /mnt /bin/bash << 'CHROOT'

# 基础配置
ln -sf /usr/share/zoneinfo/${CFG[timezone]} /etc/localtime
hwclock --systohc

echo "${CFG[locale]} UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=${CFG[locale]}" > /etc/locale.conf

echo "${CFG[hostname]}" > /etc/hostname
cat > /etc/hosts << 'HOSTS'
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${CFG[hostname]}.localdomain  ${CFG[hostname]}
HOSTS

echo "root:${CFG[root_password]}" | chpasswd
useradd -m -G wheel,audio,video,storage,optical,power,network,lp,scanner -s /bin/bash ${CFG[username]}
echo "${CFG[username]}:${CFG[password]}" | chpasswd

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# 启用服务
systemctl enable NetworkManager
systemctl enable fstrim.timer
systemctl enable reflector.timer
systemctl enable firewalld
[[ -n "$bt_pkgs" ]] && systemctl enable bluetooth
[[ -n "$print_pkgs" ]] && systemctl enable cups
[[ -n "$tlp_pkgs" ]] && systemctl enable tlp

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

# 桌面环境
[[ -n "$de_pkgs" ]] && pacman -S --needed --noconfirm $de_pkgs
$dm_enable

# 额外软件
[[ -n "$extra_pkgs" ]] && pacman -S --needed --noconfirm $extra_pkgs

# Wine 配置
[[ -n "$wine_pkgs" ]] && sudo -u ${CFG[username]} bash -c 'winetricks corefonts vcrun2019 dotnet48 dxvk 2>/dev/null || true'

CHROOT

# 7. GRUB
echo "[BOOT] 安装引导..."
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# 8. 完成
umount -R /mnt
echo ""
echo "============================================"
echo "[OK] Arch Linux 安装完成！"
echo ""
echo "用户名: ${CFG[username]}"
echo "密码:   ${CFG[password]}"
echo "桌面:   ${CFG[de]}"
echo ""
echo "请执行 reboot 重启"
echo "============================================"
EOF

    chmod +x /tmp/arch-install.sh
}

page_auto_confirm() {
    dialog --title "[AUTO] 自动安装确认" --yesno "
    即将执行自动安装，以下配置不可更改：

    安装模式:   全自动一键安装
    桌面环境:   GNOME Wayland
    系统语言:   英文 (en_US.UTF-8)
    默认密码:   arch (用户名: user)
    分区方案:   自动 (EFI + Root + Swap)
    镜像源:     中国镜像
    显卡驱动:   自动检测安装
    声卡驱动:   ALSA + PipeWire
    网卡驱动:   有线 + 无线
    蓝牙驱动:   自动检测
    Wine:       自动安装
    系统优化:   zram + swap + fstab + 防火墙

    [!] 警告：此操作将格式化整个目标磁盘！

    是否确认继续？
" 25 60

    if [[ $? -ne 0 ]]; then
        dialog --title "已取消" --msgbox "安装已取消。" 8 40
        exit 0
    fi
}

page_auto_install() {
    generate_script

    dialog --title "[OK] 脚本已生成" --msgbox "
    自动安装脚本已生成！

    位置: /tmp/arch-install.sh

    安全提示：
    - 建议先查看脚本内容确认无误
    - 在终端中执行: bash /tmp/arch-install.sh

    脚本包含：
    - 分区/格式化
    - 基础系统安装
    - 驱动安装
    - 桌面环境
    - 常用软件
    - 系统优化
" 18 60
}

page_manual_install() {
    generate_script

    dialog --title "[OK] 脚本已生成" --msgbox "
    手动安装脚本已生成！

    位置: /tmp/arch-install.sh

    请在终端中执行:
    bash /tmp/arch-install.sh

    或先查看脚本内容确认无误后再执行。
" 15 60
}

# ── 主流程 ──

main() {
    # 检查是否在 Live CD
    if [[ ! -f /arch ]]; then
        dialog --title "[!] 环境检测" --yesno "
    未检测到 Arch Live CD 环境。
    本向导应在 Arch ISO 启动后的 Live 环境中运行。

    当前仅为演示/测试模式，是否继续？
" 12 60
        [[ $? -ne 0 ]] && exit 0
    fi

    # 检查 dialog
    if ! command -v dialog &>/dev/null; then
        dialog --title "[!] 缺少依赖" --yesno "
    未找到 dialog 工具。
    是否自动安装？ (pacman -S dialog)
" 10 50
        if [[ $? -eq 0 ]]; then
            pacman -Sy --noconfirm dialog
        else
            echo "[!] 需要安装 dialog 才能运行本向导"
            exit 1
        fi
    fi

    # 欢迎页
    page_welcome

    # 硬件检测（两种模式都要）
    page_hw_detect
    page_dual_boot_check

    if [[ "${CFG[mode]}" == "auto" ]]; then
        # 自动模式
        page_disk_select
        page_auto_confirm
        page_auto_install
    else
        # 手动模式
        page_disk_select
        page_partition
        page_format_confirm
        page_system_config
        page_desktop
        page_driver
        page_network
        page_confirm
        page_manual_install
    fi

    clear
    echo ""
    echo "============================================"
    echo "[OK] 向导完成！"
    echo ""
    echo "安装脚本位置: /tmp/arch-install.sh"
    echo ""
    if [[ "${CFG[mode]}" == "auto" ]]; then
        echo "自动模式配置:"
        echo "  用户名: user"
        echo "  密码:   arch"
        echo "  桌面:   GNOME Wayland"
        echo "  语言:   英文"
    else
        echo "手动模式配置:"
        echo "  用户名: ${CFG[username]}"
        echo "  主机名: ${CFG[hostname]}"
        echo "  桌面:   ${CFG[de]}"
        echo "  语言:   ${CFG[locale]}"
    fi
    echo ""
    echo "执行命令: bash /tmp/arch-install.sh"
    echo "============================================"
    echo ""
}

main "$@"
