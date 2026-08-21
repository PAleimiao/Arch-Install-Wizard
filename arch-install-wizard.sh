#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Arch Linux 安装向导 (Bash + Dialog 版)
# 无需 Python，Arch Live CD 直接运行
# 作者: PAleimiao
# 协议: GPL-3.0
# ═══════════════════════════════════════════════════════════════

set -e

# ── 国际化 (i18n) ──
declare -A I18N

select_language() {
    local choice=$(dialog --title "Language / Yu Yan" --menu "Select language / Xuan Ze Yu Yan:" 12 55 2 \
        "zh" "Chinese (Han Yu Pin Yin)" \
        "en" "English" 2>&1 >/dev/tty)
    CFG[lang]="${choice:-en}"
}

load_i18n() {
    if [[ "${CFG[lang]}" == "zh" ]]; then
        I18N["  主机名: ${CFG[hostname]}"]="  Zhu Ji Ming: \${CFG[hostname]}"
        I18N["  密码:   arch"]="  Mi Ma:   arch"
        I18N["  桌面:   GNOME Wayland"]="  Zhuo Mian:   GNOME Wayland"
        I18N["  用户名: ${CFG[username]}"]="  Yong Hu Ming: \${CFG[username]}"
        I18N["  用户名: user"]="  Yong Hu Ming: user"
        I18N["  语言:   英文"]="  Yu Yan:   Ying Wen"
        I18N["# 手动分区 - 请使用 cfdisk $disk 分区后，手动格式化和挂载"]="# Shou Dong Fen Qu - Qing Shi Yong cfdisk \$disk Fen Qu Hou, Shou Dong Ge Shi Hua He Gua Zai"
        I18N["${warnings}检测到 $name 系统引导\n"]="\${warnings}Jian Ce Dao \$name Xi Tong Yin Dao\n"
        I18N["${warnings}检测到 NTFS 分区 (可能为 Windows)\n"]="\${warnings}Jian Ce Dao NTFS Fen Qu (Ke Neng Wei Windows)\n"
        I18N["- 分区/格式化"]="- Fen Qu/Ge Shi Hua"
        I18N["- 在终端中执行: bash /tmp/arch-install.sh"]="- Zai Zhong Duan Zhong Zhi Xing: bash /tmp/arch-install.sh"
        I18N["- 基础系统安装"]="- Ji Chu Xi Tong An Zhuang"
        I18N["- 常用软件"]="- Chang Yong Ruan Jian"
        I18N["- 建议先查看脚本内容确认无误"]="- Jian Yi Xian Cha Kan Jiao Ben Nei Rong Que Ren Wu Wu"
        I18N["- 建议在虚拟机中先行测试"]="- Jian Yi Zai Xu Ni Ji Zhong Xian Xing Ce Shi"
        I18N["- 本向导会格式化目标磁盘"]="- Ben Xiang Dao Hui Ge Shi Hua Mu Biao Ci Pan"
        I18N["- 桌面环境"]="- Zhuo Mian Huan Jing"
        I18N["- 系统优化"]="- Xi Tong You Hua"
        I18N["- 请确保已备份所有重要数据"]="- Qing Que Bao Yi Bei Fen Suo You Zhong Yao Shu Ju"
        I18N["- 驱动安装"]="- Qu Dong An Zhuang"
        I18N["============"]="============"
        I18N["Arch Linux 图形化安装向导"]="Arch Linux Tu Xing Hua An Zhuang Xiang Dao"
        I18N["Arch Linux 安装向导"]="Arch Linux An Zhuang Xiang Dao"
        I18N["CPU:     $cpu"]="CPU:     \$cpu"
        I18N["CPU: ${model} (${cores}核)"]="CPU: \${model} (\${cores}He)"
        I18N["EFI 分区"]="EFI Fen Qu"
        I18N["EFI 分区大小 (如 512M):"]="EFI Fen Qu Da Xiao (Ru 512M):"
        I18N["GNOME - 简洁现代，适合新手"]="GNOME - Jian Jie Xian Dai, Shi He Xin Shou"
        I18N["Home 分区"]="Home Fen Qu"
        I18N["Home 分区大小 (不需要输 none):"]="Home Fen Qu Da Xiao (Bu Xu Yao Shu none):"
        I18N["Hyprland - Wayland 平铺，极客首选"]="Hyprland - Wayland Ping Pu, Ji Ke Shou Xuan"
        I18N["KDE Plasma - 功能丰富，高度定制"]="KDE Plasma - Gong Neng Feng Fu, Gao Du Ding Zhi"
        I18N["Root 分区"]="Root Fen Qu"
        I18N["Root 分区大小 (输 max 表示剩余全部):"]="Root Fen Qu Da Xiao (Shu max Biao Shi Sheng Yu Quan Bu):"
        I18N["Root 密码"]="Root Mi Ma"
        I18N["Swap 分区"]="Swap Fen Qu"
        I18N["Swap 分区大小 (如 8G):"]="Swap Fen Qu Da Xiao (Ru 8G):"
        I18N["Wine"]="Wine"
        I18N["Wine 兼容层 + Lutris"]="Wine Jian Rong Ceng + Lutris"
        I18N["Wine:       自动安装"]="Wine:       Zi Dong An Zhuang"
        I18N["XFCE - 轻量稳定"]="XFCE - Qing Liang Wen Ding"
        I18N["[!!!] 双系统检测警告"]="[!!!] Shuang Xi Tong Jian Ce Jing Gao"
        I18N["[!!!] 警告：检测到双系统！"]="[!!!] Jing Gao: Jian Ce Dao Shuang Xi Tong!"
        I18N["[!] 安装中断于第 \$LINENO 行"]="[!] An Zhuang Zhong Duan Yu Di \\$LINENO Hang"
        I18N["[!] 所有数据将不可恢复！"]="[!] Suo You Shu Ju Jiang Bu Ke Hui Fu!"
        I18N["[!] 格式化确认"]="[!] Ge Shi Hua Que Ren"
        I18N["[!] 环境检测"]="[!] Huan Jing Jian Ce"
        I18N["[!] 缺少依赖"]="[!] Que Shao Yi Lai"
        I18N["[!] 警告：此操作将格式化"]="[!] Jing Gao: Ci Cao Zuo Jiang Ge Shi Hua"
        I18N["[!] 警告：此操作将格式化 ${CFG[disk]}！"]="[!] Jing Gao: Ci Cao Zuo Jiang Ge Shi Hua \${CFG[disk]}!"
        I18N["[!] 警告：此操作将格式化整个目标磁盘！"]="[!] Jing Gao: Ci Cao Zuo Jiang Ge Shi Hua Zheng Ge Mu Biao Ci Pan!"
        I18N["[!] 警告：此操作将清除磁盘上所有数据！"]="[!] Jing Gao: Ci Cao Zuo Jiang Qing Chu Ci Pan Shang Suo You Shu Ju!"
        I18N["[!] 需要安装 dialog 才能运行本向导"]="[!] Xu Yao An Zhuang dialog Cai Neng Yun Xing Ben Xiang Dao"
        I18N["[AUTO] Arch Linux 安装开始..."]="[AUTO] Arch Linux An Zhuang Kai Shi..."
        I18N["[AUTO] 自动安装 - 一键完成，默认配置"]="[AUTO] Zi Dong An Zhuang - Yi Jian Wan Cheng, Mo Ren Pei Zhi"
        I18N["[AUTO] 自动安装 -> 一键傻瓜式"]="[AUTO] Zi Dong An Zhuang -> Yi Jian Sha Gua Shi"
        I18N["[AUTO] 自动安装确认"]="[AUTO] Zi Dong An Zhuang Que Ren"
        I18N["[BOOT] 安装引导..."]="[BOOT] An Zhuang Yin Dao..."
        I18N["[CFG]  手动安装 -> 逐步自定义"]="[CFG]  Shou Dong An Zhuang -> Zhu Bu Zi Ding Yi"
        I18N["[CFG] 手动安装 - 逐步自定义"]="[CFG] Shou Dong An Zhuang - Zhu Bu Zi Ding Yi"
        I18N["[CFG] 配置系统..."]="[CFG] Pei Zhi Xi Tong..."
        I18N["[DISK] 正在分区 $disk..."]="[DISK] Zheng Zai Fen Qu \$disk..."
        I18N["[MIRROR] 配置镜像源..."]="[MIRROR] Pei Zhi Jing Xiang Yuan..."
        I18N["[NET] 设置网络..."]="[NET] She Zhi Wang Luo..."
        I18N["[OK] Arch Linux 安装完成！"]="[OK] Arch Linux An Zhuang Wan Cheng!"
        I18N["[OK] 分区完成"]="[OK] Fen Qu Wan Cheng"
        I18N["[OK] 双系统检测"]="[OK] Shuang Xi Tong Jian Ce"
        I18N["[OK] 向导完成！"]="[OK] Xiang Dao Wan Cheng!"
        I18N["[OK] 脚本已生成"]="[OK] Jiao Ben Yi Sheng Cheng"
        I18N["[PKG] 安装基础系统（可能需要 10-30 分钟）..."]="[PKG] An Zhuang Ji Chu Xi Tong (Ke Neng Xu Yao 10-30 Fen Zhong)..."
        I18N["bash /tmp/arch-install.sh"]="bash /tmp/arch-install.sh"
        I18N["btrfs - 高级功能，支持快照"]="btrfs - Gao Ji Gong Neng, Zhi Chi Kuai Zhao"
        I18N["ext4 - 推荐，稳定可靠"]="ext4 - Tui Jian, Wen Ding Ke Kao"
        I18N["xfs - 大文件性能优秀"]="xfs - Da Wen Jian Xing Neng You Xiu"
        I18N["一键傻瓜式"]="Yi Jian Sha Gua Shi"
        I18N["上海 (中国)"]="Shang Hai (Zhong Guo)"
        I18N["下一步需要输入确认信息。"]="Xia Yi Bu Xu Yao Shu Ru Que Ren Xin Xi."
        I18N["不安装桌面 - 仅基础系统"]="Bu An Zhuang Zhuo Mian - Jin Ji Chu Xi Tong"
        I18N["东京"]="Dong Jing"
        I18N["两次输入的密码不一致！请重新输入。"]="Liang Ci Shu Ru De Mi Ma Bu Yi Zhi! Qing Chong Xin Shu Ru."
        I18N["中国镜像"]="Zhong Guo Jing Xiang"
        I18N["中国镜像 (清华/中科大/阿里)"]="Zhong Guo Jing Xiang (Qing Hua/Zhong Ke Da/A Li)"
        I18N["主机名"]="Zhu Ji Ming"
        I18N["主机名:     ${CFG[hostname]}"]="Zhu Ji Ming:     \${CFG[hostname]}"
        I18N["伦敦"]="Lun Dun"
        I18N["位置"]="Wei Zhi"
        I18N["位置: /tmp/arch-install.sh"]="Wei Zhi: /tmp/arch-install.sh"
        I18N["使用"]="Shi Yong"
        I18N["全自动一键安装"]="Quan Zi Dong Yi Jian An Zhuang"
        I18N["内存"]="Nei Cun"
        I18N["内存:    $mem"]="Nei Cun:    \$mem"
        I18N["再次输入用户密码:"]="Zai Ci Shu Ru Yong Hu Mi Ma:"
        I18N["分区"]="Fen Qu"
        I18N["分区/格式化"]="Fen Qu/Ge Shi Hua"
        I18N["分区方案"]="Fen Qu Fang An"
        I18N["分区方案:   ${CFG[scheme]}"]="Fen Qu Fang An:   \${CFG[scheme]}"
        I18N["分区方案:   自动 (EFI + Root + Swap)"]="Fen Qu Fang An:   Zi Dong (EFI + Root + Swap)"
        I18N["分区方案: ${CFG[scheme]}"]="Fen Qu Fang An: \${CFG[scheme]}"
        I18N["办公套件 (LibreOffice)"]="Ban Gong Tao Jian (LibreOffice)"
        I18N["即将执行自动安装，以下配置不可更改："]="Ji Jiang Zhi Xing Zi Dong An Zhuang, Yi Xia Pei Zhi Bu Ke Geng Gai:"
        I18N["即将格式化磁盘"]="Ji Jiang Ge Shi Hua Ci Pan"
        I18N["即将格式化磁盘: ${CFG[disk]}"]="Ji Jiang Ge Shi Hua Ci Pan: \${CFG[disk]}"
        I18N["可能为"]="Ke Neng Wei"
        I18N["台北"]="Tai Bei"
        I18N["向导将根据检测结果推荐驱动方案。"]="Xiang Dao Jiang Gen Ju Jian Ce Jie Guo Tui Jian Qu Dong Fang An."
        I18N["否"]="Fou"
        I18N["图形化安装向导"]="Tu Xing Hua An Zhuang Xiang Dao"
        I18N["在终端中执行"]="Zai Zhong Duan Zhong Zhi Xing"
        I18N["在终端中执行: bash /tmp/arch-install.sh"]="Zai Zhong Duan Zhong Zhi Xing: bash /tmp/arch-install.sh"
        I18N["基础系统安装"]="Ji Chu Xi Tong An Zhuang"
        I18N["声卡"]="Sheng Ka"
        I18N["声卡:    $audio"]="Sheng Ka:    \$audio"
        I18N["声卡驱动"]="Sheng Ka Qu Dong"
        I18N["声卡驱动 (ALSA/PipeWire)"]="Sheng Ka Qu Dong (ALSA/PipeWire)"
        I18N["声卡驱动:   ALSA + PipeWire"]="Sheng Ka Qu Dong:   ALSA + PipeWire"
        I18N["多媒体 (VLC/MPV)"]="Duo Mei Ti (VLC/MPV)"
        I18N["安全提示"]="An Quan Ti Shi"
        I18N["安全提示："]="An Quan Ti Shi:"
        I18N["安装已取消。"]="An Zhuang Yi Qu Xiao."
        I18N["安装模式"]="An Zhuang Mo Shi"
        I18N["安装模式:   全自动一键安装"]="An Zhuang Mo Shi:   Quan Zi Dong Yi Jian An Zhuang"
        I18N["安装确认"]="An Zhuang Que Ren"
        I18N["安装脚本位置: /tmp/arch-install.sh"]="An Zhuang Jiao Ben Wei Zhi: /tmp/arch-install.sh"
        I18N["安装配置摘要"]="An Zhuang Pei Zhi Zhai Yao"
        I18N["官方镜像"]="Guan Fang Jing Xiang"
        I18N["密码不能为空！"]="Mi Ma Bu Neng Wei Kong!"
        I18N["已取消"]="Yi Qu Xiao"
        I18N["已检测"]="Yi Jian Ce"
        I18N["已检测 ($wifi 个设备)"]="Yi Jian Ce (\$wifi Ge She Bei)"
        I18N["常用软件"]="Chang Yong Ruan Jian"
        I18N["建议先查看脚本内容确认无误"]="Jian Yi Xian Cha Kan Jiao Ben Nei Rong Que Ren Wu Wu"
        I18N["建议在虚拟机中先行测试"]="Jian Yi Zai Xu Ni Ji Zhong Xian Xing Ce Shi"
        I18N["当前仅为演示/测试模式，是否继续？"]="Dang Qian Jin Wei Yan Shi/Ce Shi Mo Shi, Shi Fou Ji Xu?"
        I18N["或先查看脚本内容确认无误后再执行。"]="Huo Xian Cha Kan Jiao Ben Nei Rong Que Ren Wu Wu Hou Zai Zhi Xing."
        I18N["手动分区 - 使用 cfdisk 自行划分"]="Shou Dong Fen Qu - Shi Yong cfdisk Zi Xing Hua Fen"
        I18N["手动安装脚本已生成！"]="Shou Dong An Zhuang Jiao Ben Yi Sheng Cheng!"
        I18N["手动模式配置:"]="Shou Dong Mo Shi Pei Zhi:"
        I18N["打印机驱动 (CUPS)"]="Da Yin Ji Qu Dong (CUPS)"
        I18N["执行命令: bash /tmp/arch-install.sh"]="Zhi Xing Ming Ling: bash /tmp/arch-install.sh"
        I18N["摄像头驱动 (V4L)"]="She Xiang Tou Qu Dong (V4L)"
        I18N["支持两种安装模式"]="Zhi Chi Liang Zhong An Zhuang Mo Shi"
        I18N["支持两种安装模式："]="Zhi Chi Liang Zhong An Zhuang Mo Shi:"
        I18N["文件系统"]="Wen Jian Xi Tong"
        I18N["文件系统:   ${CFG[filesystem]}"]="Wen Jian Xi Tong:   \${CFG[filesystem]}"
        I18N["无线"]="Wu Xian"
        I18N["无线:    $wifi"]="Wu Xian:    \$wifi"
        I18N["无线网卡驱动"]="Wu Xian Wang Ka Qu Dong"
        I18N["日文"]="Ri Wen"
        I18N["时区"]="Shi Qu"
        I18N["时区:       ${CFG[timezone]}"]="Shi Qu:       \${CFG[timezone]}"
        I18N["是"]="Shi"
        I18N["是否确认继续？"]="Shi Fou Que Ren Ji Xu?"
        I18N["是否自动安装？ (pacman -S dialog)"]="Shi Fou Zi Dong An Zhuang? (pacman -S dialog)"
        I18N["显卡"]="Xian Ka"
        I18N["显卡:    $gpu"]="Xian Ka:    \$gpu"
        I18N["显卡驱动 ($gpu)"]="Xian Ka Qu Dong (\$gpu)"
        I18N["显卡驱动:   自动检测安装"]="Xian Ka Qu Dong:   Zi Dong Jian Ce An Zhuang"
        I18N["有线"]="You Xian"
        I18N["未找到 dialog 工具。"]="Wei Zhao Dao dialog Gong Ju."
        I18N["未检测"]="Wei Jian Ce"
        I18N["未检测到"]="Wei Jian Ce Dao"
        I18N["未检测到 Arch Live CD 环境。"]="Wei Jian Ce Dao Arch Live CD Huan Jing."
        I18N["未检测到双系统，可以继续安装。"]="Wei Jian Ce Dao Shuang Xi Tong, Ke Yi Ji Xu An Zhuang."
        I18N["未检测到磁盘！"]="Wei Jian Ce Dao Ci Pan!"
        I18N["本向导会格式化目标磁盘"]="Ben Xiang Dao Hui Ge Shi Hua Mu Biao Ci Pan"
        I18N["本向导应在 Arch ISO 启动后的 Live 环境中运行。"]="Ben Xiang Dao Ying Zai Arch ISO Qi Dong Hou De Live Huan Jing Zhong Yun Xing."
        I18N["根据硬件检测，选择要安装的驱动:"]="Gen Ju Ying Jian Jian Ce, Xuan Ze Yao An Zhuang De Qu Dong:"
        I18N["桌面环境"]="Zhuo Mian Huan Jing"
        I18N["桌面环境:   ${CFG[de]}"]="Zhuo Mian Huan Jing:   \${CFG[de]}"
        I18N["桌面环境:   GNOME Wayland"]="Zhuo Mian Huan Jing:   GNOME Wayland"
        I18N["检测到"]="Jian Ce Dao"
        I18N["欢迎"]="Huan Ying"
        I18N["欢迎使用 Arch Linux 安装向导！"]="Huan Ying Shi Yong Arch Linux An Zhuang Xiang Dao!"
        I18N["浏览器 (Firefox)"]="Liu Lan Qi (Firefox)"
        I18N["游戏工具 (Steam/Lutris)"]="You Xi Gong Ju (Steam/Lutris)"
        I18N["用户名"]="Yong Hu Ming"
        I18N["用户名:     ${CFG[username]}"]="Yong Hu Ming:     \${CFG[username]}"
        I18N["用户名: ${CFG[username]}"]="Yong Hu Ming: \${CFG[username]}"
        I18N["用户密码"]="Yong Hu Mi Ma"
        I18N["目标磁盘"]="Mu Biao Ci Pan"
        I18N["目标磁盘:   ${CFG[disk]}"]="Mu Biao Ci Pan:   \${CFG[disk]}"
        I18N["硬件检测"]="Ying Jian Jian Ce"
        I18N["硬件检测报告"]="Ying Jian Jian Ce Bao Gao"
        I18N["确认"]="Que Ren"
        I18N["确认失败！必须输入 I KNOW（全大写）才能继续。"]="Que Ren Shi Bai! Bi Xu Shu Ru I KNOW (Quan Da Xie) Cai Neng Ji Xu."
        I18N["确认密码"]="Que Ren Mi Ma"
        I18N["笔记本"]="Bi Ji Ben"
        I18N["笔记本:  $laptop"]="Bi Ji Ben:  \$laptop"
        I18N["笔记本电源管理 (TLP)"]="Bi Ji Ben Dian Yuan Guan Li (TLP)"
        I18N["简体中文"]="Jian Ti Zhong Wen"
        I18N["系统优化"]="Xi Tong You Hua"
        I18N["系统优化:   zram + swap + fstab + 防火墙"]="Xi Tong You Hua:   zram + swap + fstab + Fang Huo Qiang"
        I18N["系统引导"]="Xi Tong Yin Dao"
        I18N["系统语言"]="Xi Tong Yu Yan"
        I18N["系统语言:   英文 (en_US.UTF-8)"]="Xi Tong Yu Yan:   Ying Wen (en_US.UTF-8)"
        I18N["繁体中文"]="Fan Ti Zhong Wen"
        I18N["纽约"]="Niu Yue"
        I18N["继续安装可能导致其他系统无法启动！"]="Ji Xu An Zhuang Ke Neng Dao Zhi Qi Ta Xi Tong Wu Fa Qi Dong!"
        I18N["编辑器 (Vim/Nano)"]="Bian Ji Qi (Vim/Nano)"
        I18N["网卡驱动"]="Wang Ka Qu Dong"
        I18N["网卡驱动:   有线 + 无线"]="Wang Ka Qu Dong:   You Xian + Wu Xian"
        I18N["脚本包含"]="Jiao Ben Bao Han"
        I18N["脚本包含："]="Jiao Ben Bao Han:"
        I18N["自动"]="Zi Dong"
        I18N["自动分区 - EFI(512M) + Swap(8G) + Root(剩余)"]="Zi Dong Fen Qu - EFI(512M) + Swap(8G) + Root(Sheng Yu)"
        I18N["自动安装"]="Zi Dong An Zhuang"
        I18N["自动安装脚本已生成！"]="Zi Dong An Zhuang Jiao Ben Yi Sheng Cheng!"
        I18N["自动检测"]="Zi Dong Jian Ce"
        I18N["自动检测安装"]="Zi Dong Jian Ce An Zhuang"
        I18N["自动模式配置:"]="Zi Dong Mo Shi Pei Zhi:"
        I18N["英文"]="Ying Wen"
        I18N["蓝牙"]="Lan Ya"
        I18N["蓝牙:    $bt"]="Lan Ya:    \$bt"
        I18N["蓝牙驱动"]="Lan Ya Qu Dong"
        I18N["蓝牙驱动:   自动检测"]="Lan Ya Qu Dong:   Zi Dong Jian Ce"
        I18N["触摸板"]="Chu Mo Ban"
        I18N["触摸板:  $tp"]="Chu Mo Ban:  \$tp"
        I18N["触摸板驱动"]="Chu Mo Ban Qu Dong"
        I18N["设置 Root 密码 (留空则与用户密码相同):"]="She Zhi Root Mi Ma (Liu Kong Ze Yu Yong Hu Mi Ma Xiang Tong):"
        I18N["设置主机名:"]="She Zhi Zhu Ji Ming:"
        I18N["设置用户名:"]="She Zhi Yong Hu Ming:"
        I18N["设置用户密码:"]="She Zhi Yong Hu Mi Ma:"
        I18N["语言:       ${CFG[locale]}"]="Yu Yan:       \${CFG[locale]}"
        I18N["请务必确认你知道自己在做什么！"]="Qing Wu Bi Que Ren Ni Zhi Dao Zi Ji Zai Zuo Shi Me!"
        I18N["请在终端中执行"]="Qing Zai Zhong Duan Zhong Zhi Xing"
        I18N["请在终端中执行:"]="Qing Zai Zhong Duan Zhong Zhi Xing:"
        I18N["请执行 reboot 重启"]="Qing Zhi Xing reboot Chong Qi"
        I18N["请确保已备份所有重要数据"]="Qing Que Bao Yi Bei Fen Suo You Zhong Yao Shu Ju"
        I18N["请输入 I KNOW 以确认继续:"]="Qing Shu Ru I KNOW Yi Que Ren Ji Xu:"
        I18N["请选择安装模式:"]="Qing Xuan Ze An Zhuang Mo Shi:"
        I18N["请选择要安装 Arch 的目标磁盘:"]="Qing Xuan Ze Yao An Zhuang Arch De Mu Biao Ci Pan:"
        I18N["选择 Root 分区文件系统:"]="Xuan Ze Root Fen Qu Wen Jian Xi Tong:"
        I18N["选择分区方式:"]="Xuan Ze Fen Qu Fang Shi:"
        I18N["选择安装模式"]="Xuan Ze An Zhuang Mo Shi"
        I18N["选择时区:"]="Xuan Ze Shi Qu:"
        I18N["选择桌面环境:"]="Xuan Ze Zhuo Mian Huan Jing:"
        I18N["选择磁盘"]="Xuan Ze Ci Pan"
        I18N["选择系统语言:"]="Xuan Ze Xi Tong Yu Yan:"
        I18N["选择要安装的额外软件:"]="Xuan Ze Yao An Zhuang De E Wai Ruan Jian:"
        I18N["选择软件源:"]="Xuan Ze Ruan Jian Yuan:"
        I18N["逐步自定义"]="Zhu Bu Zi Ding Yi"
        I18N["重要提示"]="Zhong Yao Ti Shi"
        I18N["重要提示："]="Zhong Yao Ti Shi:"
        I18N["错误"]="Cuo Wu"
        I18N["镜像源"]="Jing Xiang Yuan"
        I18N["镜像源:     ${CFG[mirror]}"]="Jing Xiang Yuan:     \${CFG[mirror]}"
        I18N["镜像源:     中国镜像"]="Jing Xiang Yuan:     Zhong Guo Jing Xiang"
        I18N["防火墙"]="Fang Huo Qiang"
        I18N["韩文"]="Han Wen"
        I18N["额外软件"]="E Wai Ruan Jian"
        I18N["香港"]="Xiang Gang"
        I18N["驱动安装"]="Qu Dong An Zhuang"
        I18N["驱动选择"]="Qu Dong Xuan Ze"
        I18N["默认密码"]="Mo Ren Mi Ma"
        I18N["默认密码:   arch (用户名: user)"]="Mo Ren Mi Ma:   arch (Yong Hu Ming: user)"
    else
        I18N["  主机名: ${CFG[hostname]}"]="  Hostname: \${CFG[hostname]}"
        I18N["  密码:   arch"]="  Password:   arch"
        I18N["  桌面:   GNOME Wayland"]="  Desktop:   GNOME Wayland"
        I18N["  用户名: ${CFG[username]}"]="  Username: \${CFG[username]}"
        I18N["  用户名: user"]="  Username: user"
        I18N["  语言:   英文"]="  Language:   English"
        I18N["# 手动分区 - 请使用 cfdisk $disk 分区后，手动格式化和挂载"]="# Manual partition - Use cfdisk \$disk to partition, then manually format and mount"
        I18N["${warnings}检测到 $name 系统引导\n"]="\${warnings}Detected \$name system boot\n"
        I18N["${warnings}检测到 NTFS 分区 (可能为 Windows)\n"]="\${warnings}Detected NTFS partition (possibly Windows)\n"
        I18N["- 分区/格式化"]="- Partition/Format"
        I18N["- 在终端中执行: bash /tmp/arch-install.sh"]="- Execute in terminal: bash /tmp/arch-install.sh"
        I18N["- 基础系统安装"]="- Base system install"
        I18N["- 常用软件"]="- Common software"
        I18N["- 建议先查看脚本内容确认无误"]="- Recommended to review script content first"
        I18N["- 建议在虚拟机中先行测试"]="- Recommended to test in VM first"
        I18N["- 本向导会格式化目标磁盘"]="- This wizard will format the target disk"
        I18N["- 桌面环境"]="- Desktop environment"
        I18N["- 系统优化"]="- System optimization"
        I18N["- 请确保已备份所有重要数据"]="- Please ensure all important data is backed up"
        I18N["- 驱动安装"]="- Driver install"
        I18N["============"]="============"
        I18N["Arch Linux 图形化安装向导"]="Arch Linux Graphical Installation Wizard"
        I18N["Arch Linux 安装向导"]="Arch Linux Installation Wizard"
        I18N["CPU:     $cpu"]="CPU:     \$cpu"
        I18N["CPU: ${model} (${cores}核)"]="CPU: \${model} (\${cores} cores)"
        I18N["EFI 分区"]="EFI Partition"
        I18N["EFI 分区大小 (如 512M):"]="EFI partition size (e.g. 512M):"
        I18N["GNOME - 简洁现代，适合新手"]="GNOME - Clean and modern, beginner friendly"
        I18N["Home 分区"]="Home Partition"
        I18N["Home 分区大小 (不需要输 none):"]="Home partition size (type none if not needed):"
        I18N["Hyprland - Wayland 平铺，极客首选"]="Hyprland - Wayland tiling, geek's choice"
        I18N["KDE Plasma - 功能丰富，高度定制"]="KDE Plasma - Feature rich, highly customizable"
        I18N["Root 分区"]="Root Partition"
        I18N["Root 分区大小 (输 max 表示剩余全部):"]="Root partition size (type max for all remaining):"
        I18N["Root 密码"]="Root Password"
        I18N["Swap 分区"]="Swap Partition"
        I18N["Swap 分区大小 (如 8G):"]="Swap partition size (e.g. 8G):"
        I18N["Wine"]="Wine"
        I18N["Wine 兼容层 + Lutris"]="Wine Compatibility Layer + Lutris"
        I18N["Wine:       自动安装"]="Wine:       Auto install"
        I18N["XFCE - 轻量稳定"]="XFCE - Lightweight and stable"
        I18N["[!!!] 双系统检测警告"]="[!!!] Dual Boot Detection Warning"
        I18N["[!!!] 警告：检测到双系统！"]="[!!!] Warning: Dual boot detected!"
        I18N["[!] 安装中断于第 \$LINENO 行"]="[!] Installation interrupted at line \\$LINENO"
        I18N["[!] 所有数据将不可恢复！"]="[!] All data will be unrecoverable!"
        I18N["[!] 格式化确认"]="[!] Format Confirmation"
        I18N["[!] 环境检测"]="[!] Environment Check"
        I18N["[!] 缺少依赖"]="[!] Missing Dependencies"
        I18N["[!] 警告：此操作将格式化"]="[!] Warning: This will format"
        I18N["[!] 警告：此操作将格式化 ${CFG[disk]}！"]="[!] Warning: This will format \${CFG[disk]}!"
        I18N["[!] 警告：此操作将格式化整个目标磁盘！"]="[!] Warning: This will format the entire target disk!"
        I18N["[!] 警告：此操作将清除磁盘上所有数据！"]="[!] Warning: This will erase all data on the disk!"
        I18N["[!] 需要安装 dialog 才能运行本向导"]="[!] dialog is required to run this wizard"
        I18N["[AUTO] Arch Linux 安装开始..."]="[AUTO] Arch Linux installation starting..."
        I18N["[AUTO] 自动安装 - 一键完成，默认配置"]="[AUTO] Automatic Install - One-click, default config"
        I18N["[AUTO] 自动安装 -> 一键傻瓜式"]="[AUTO] Automatic Install -> One-click easy"
        I18N["[AUTO] 自动安装确认"]="[AUTO] Automatic Installation Confirmation"
        I18N["[BOOT] 安装引导..."]="[BOOT] Installing bootloader..."
        I18N["[CFG]  手动安装 -> 逐步自定义"]="[CFG]  Manual Install -> Step by step custom"
        I18N["[CFG] 手动安装 - 逐步自定义"]="[CFG] Manual Install - Step by step custom"
        I18N["[CFG] 配置系统..."]="[CFG] Configuring system..."
        I18N["[DISK] 正在分区 $disk..."]="[DISK] Partitioning \$disk..."
        I18N["[MIRROR] 配置镜像源..."]="[MIRROR] Configuring mirror source..."
        I18N["[NET] 设置网络..."]="[NET] Setting up network..."
        I18N["[OK] Arch Linux 安装完成！"]="[OK] Arch Linux installation complete!"
        I18N["[OK] 分区完成"]="[OK] Partitioning complete"
        I18N["[OK] 双系统检测"]="[OK] Dual Boot Check"
        I18N["[OK] 向导完成！"]="[OK] Wizard complete!"
        I18N["[OK] 脚本已生成"]="[OK] Script generated"
        I18N["[PKG] 安装基础系统（可能需要 10-30 分钟）..."]="[PKG] Installing base system (may take 10-30 minutes)..."
        I18N["bash /tmp/arch-install.sh"]="bash /tmp/arch-install.sh"
        I18N["btrfs - 高级功能，支持快照"]="btrfs - Advanced features, supports snapshots"
        I18N["ext4 - 推荐，稳定可靠"]="ext4 - Recommended, stable and reliable"
        I18N["xfs - 大文件性能优秀"]="xfs - Excellent large file performance"
        I18N["一键傻瓜式"]="One-click Easy"
        I18N["上海 (中国)"]="Shanghai (China)"
        I18N["下一步需要输入确认信息。"]="Next step requires confirmation input."
        I18N["不安装桌面 - 仅基础系统"]="No desktop - Base system only"
        I18N["东京"]="Tokyo"
        I18N["两次输入的密码不一致！请重新输入。"]="Passwords do not match! Please re-enter."
        I18N["中国镜像"]="China Mirror"
        I18N["中国镜像 (清华/中科大/阿里)"]="China Mirror (Tsinghua/USTC/Alibaba)"
        I18N["主机名"]="Hostname"
        I18N["主机名:     ${CFG[hostname]}"]="Hostname:     \${CFG[hostname]}"
        I18N["伦敦"]="London"
        I18N["位置"]="Location"
        I18N["位置: /tmp/arch-install.sh"]="Location: /tmp/arch-install.sh"
        I18N["使用"]="Use"
        I18N["全自动一键安装"]="Fully Automatic One-click"
        I18N["内存"]="Memory"
        I18N["内存:    $mem"]="Memory:    \$mem"
        I18N["再次输入用户密码:"]="Re-enter user password:"
        I18N["分区"]="Partition"
        I18N["分区/格式化"]="Partition/Format"
        I18N["分区方案"]="Partition Scheme"
        I18N["分区方案:   ${CFG[scheme]}"]="Partition scheme:   \${CFG[scheme]}"
        I18N["分区方案:   自动 (EFI + Root + Swap)"]="Partition scheme:   Auto (EFI + Root + Swap)"
        I18N["分区方案: ${CFG[scheme]}"]="Partition scheme: \${CFG[scheme]}"
        I18N["办公套件 (LibreOffice)"]="Office Suite (LibreOffice)"
        I18N["即将执行自动安装，以下配置不可更改："]="About to execute automatic install, following config cannot be changed:"
        I18N["即将格式化磁盘"]="About to Format Disk"
        I18N["即将格式化磁盘: ${CFG[disk]}"]="About to format disk: \${CFG[disk]}"
        I18N["可能为"]="Possibly"
        I18N["台北"]="Taipei"
        I18N["向导将根据检测结果推荐驱动方案。"]="Wizard will recommend drivers based on detection results."
        I18N["否"]="No"
        I18N["图形化安装向导"]="Graphical Installation Wizard"
        I18N["在终端中执行"]="Execute in Terminal"
        I18N["在终端中执行: bash /tmp/arch-install.sh"]="Execute in terminal: bash /tmp/arch-install.sh"
        I18N["基础系统安装"]="Base system install"
        I18N["声卡"]="Audio"
        I18N["声卡:    $audio"]="Audio:    \$audio"
        I18N["声卡驱动"]="Audio Driver"
        I18N["声卡驱动 (ALSA/PipeWire)"]="Audio Driver (ALSA/PipeWire)"
        I18N["声卡驱动:   ALSA + PipeWire"]="Audio driver:   ALSA + PipeWire"
        I18N["多媒体 (VLC/MPV)"]="Media (VLC/MPV)"
        I18N["安全提示"]="Safety Notes"
        I18N["安全提示："]="Safety Notes:"
        I18N["安装已取消。"]="Installation cancelled."
        I18N["安装模式"]="Install Mode"
        I18N["安装模式:   全自动一键安装"]="Install mode:   Fully automatic one-click"
        I18N["安装确认"]="Installation Confirmation"
        I18N["安装脚本位置: /tmp/arch-install.sh"]="Installation script location: /tmp/arch-install.sh"
        I18N["安装配置摘要"]="Installation Config Summary"
        I18N["官方镜像"]="Official Mirror"
        I18N["密码不能为空！"]="Password cannot be empty!"
        I18N["已取消"]="Cancelled"
        I18N["已检测"]="Detected"
        I18N["已检测 ($wifi 个设备)"]="Detected (\$wifi devices)"
        I18N["常用软件"]="Common software"
        I18N["建议先查看脚本内容确认无误"]="Recommended to review script content first"
        I18N["建议在虚拟机中先行测试"]="Recommended to test in VM first"
        I18N["当前仅为演示/测试模式，是否继续？"]="Currently in demo/test mode, continue?"
        I18N["或先查看脚本内容确认无误后再执行。"]="Or review script content first before executing."
        I18N["手动分区 - 使用 cfdisk 自行划分"]="Manual partition - Use cfdisk to partition manually"
        I18N["手动安装脚本已生成！"]="Manual install script generated!"
        I18N["手动模式配置:"]="Manual mode config:"
        I18N["打印机驱动 (CUPS)"]="Printer Driver (CUPS)"
        I18N["执行命令: bash /tmp/arch-install.sh"]="Execute command: bash /tmp/arch-install.sh"
        I18N["摄像头驱动 (V4L)"]="Camera Driver (V4L)"
        I18N["支持两种安装模式"]="Supports two installation modes"
        I18N["支持两种安装模式："]="Supports two installation modes:"
        I18N["文件系统"]="Filesystem"
        I18N["文件系统:   ${CFG[filesystem]}"]="Filesystem:   \${CFG[filesystem]}"
        I18N["无线"]="Wireless"
        I18N["无线:    $wifi"]="Wireless:    \$wifi"
        I18N["无线网卡驱动"]="Wireless Driver"
        I18N["日文"]="Japanese"
        I18N["时区"]="Timezone"
        I18N["时区:       ${CFG[timezone]}"]="Timezone:       \${CFG[timezone]}"
        I18N["是"]="Yes"
        I18N["是否确认继续？"]="Confirm to continue?"
        I18N["是否自动安装？ (pacman -S dialog)"]="Auto install? (pacman -S dialog)"
        I18N["显卡"]="GPU"
        I18N["显卡:    $gpu"]="GPU:    \$gpu"
        I18N["显卡驱动 ($gpu)"]="GPU Driver (\$gpu)"
        I18N["显卡驱动:   自动检测安装"]="GPU driver:   Auto detect and install"
        I18N["有线"]="Wired"
        I18N["未找到 dialog 工具。"]="dialog tool not found."
        I18N["未检测"]="Not detected"
        I18N["未检测到"]="Not detected"
        I18N["未检测到 Arch Live CD 环境。"]="Arch Live CD environment not detected."
        I18N["未检测到双系统，可以继续安装。"]="No dual boot detected, can continue installation."
        I18N["未检测到磁盘！"]="No disk detected!"
        I18N["本向导会格式化目标磁盘"]="This wizard will format the target disk"
        I18N["本向导应在 Arch ISO 启动后的 Live 环境中运行。"]="This wizard should run in Arch ISO Live environment."
        I18N["根据硬件检测，选择要安装的驱动:"]="Based on hardware detection, select drivers to install:"
        I18N["桌面环境"]="Desktop Environment"
        I18N["桌面环境:   ${CFG[de]}"]="Desktop:   \${CFG[de]}"
        I18N["桌面环境:   GNOME Wayland"]="Desktop:   GNOME Wayland"
        I18N["检测到"]="Detected"
        I18N["欢迎"]="Welcome"
        I18N["欢迎使用 Arch Linux 安装向导！"]="Welcome to Arch Linux Installation Wizard!"
        I18N["浏览器 (Firefox)"]="Browser (Firefox)"
        I18N["游戏工具 (Steam/Lutris)"]="Gaming Tools (Steam/Lutris)"
        I18N["用户名"]="Username"
        I18N["用户名:     ${CFG[username]}"]="Username:     \${CFG[username]}"
        I18N["用户名: ${CFG[username]}"]="Username: \${CFG[username]}"
        I18N["用户密码"]="User Password"
        I18N["目标磁盘"]="Target Disk"
        I18N["目标磁盘:   ${CFG[disk]}"]="Target disk:   \${CFG[disk]}"
        I18N["硬件检测"]="Hardware Detection"
        I18N["硬件检测报告"]="Hardware Detection Report"
        I18N["确认"]="Confirm"
        I18N["确认失败！必须输入 I KNOW（全大写）才能继续。"]="Confirm failed! Must type I KNOW (ALL CAPS) to continue."
        I18N["确认密码"]="Confirm Password"
        I18N["笔记本"]="Laptop"
        I18N["笔记本:  $laptop"]="Laptop:  \$laptop"
        I18N["笔记本电源管理 (TLP)"]="Laptop Power Management (TLP)"
        I18N["简体中文"]="Simplified Chinese"
        I18N["系统优化"]="System Optimization"
        I18N["系统优化:   zram + swap + fstab + 防火墙"]="System optimize:   zram + swap + fstab + Firewall"
        I18N["系统引导"]="System Boot"
        I18N["系统语言"]="System Language"
        I18N["系统语言:   英文 (en_US.UTF-8)"]="System language:   English (en_US.UTF-8)"
        I18N["繁体中文"]="Traditional Chinese"
        I18N["纽约"]="New York"
        I18N["继续安装可能导致其他系统无法启动！"]="Continuing may cause other systems to fail booting!"
        I18N["编辑器 (Vim/Nano)"]="Editor (Vim/Nano)"
        I18N["网卡驱动"]="Network Driver"
        I18N["网卡驱动:   有线 + 无线"]="Network driver:   Wired + Wireless"
        I18N["脚本包含"]="Script includes"
        I18N["脚本包含："]="Script includes:"
        I18N["自动"]="Auto"
        I18N["自动分区 - EFI(512M) + Swap(8G) + Root(剩余)"]="Auto partition - EFI(512M) + Swap(8G) + Root(remaining)"
        I18N["自动安装"]="Auto Install"
        I18N["自动安装脚本已生成！"]="Auto install script generated!"
        I18N["自动检测"]="Auto Detect"
        I18N["自动检测安装"]="Auto Detect and Install"
        I18N["自动模式配置:"]="Auto mode config:"
        I18N["英文"]="English"
        I18N["蓝牙"]="Bluetooth"
        I18N["蓝牙:    $bt"]="Bluetooth:    \$bt"
        I18N["蓝牙驱动"]="Bluetooth Driver"
        I18N["蓝牙驱动:   自动检测"]="Bluetooth driver:   Auto detect"
        I18N["触摸板"]="Touchpad"
        I18N["触摸板:  $tp"]="Touchpad:  \$tp"
        I18N["触摸板驱动"]="Touchpad Driver"
        I18N["设置 Root 密码 (留空则与用户密码相同):"]="Set Root password (leave empty to use user password):"
        I18N["设置主机名:"]="Set hostname:"
        I18N["设置用户名:"]="Set username:"
        I18N["设置用户密码:"]="Set user password:"
        I18N["语言:       ${CFG[locale]}"]="Language:       \${CFG[locale]}"
        I18N["请务必确认你知道自己在做什么！"]="Please make sure you know what you are doing!"
        I18N["请在终端中执行"]="Please Execute in Terminal"
        I18N["请在终端中执行:"]="Please execute in terminal:"
        I18N["请执行 reboot 重启"]="Please run reboot to restart"
        I18N["请确保已备份所有重要数据"]="Please ensure all important data is backed up"
        I18N["请输入 I KNOW 以确认继续:"]="Please type I KNOW to confirm continue:"
        I18N["请选择安装模式:"]="Please select installation mode:"
        I18N["请选择要安装 Arch 的目标磁盘:"]="Please select target disk for Arch installation:"
        I18N["选择 Root 分区文件系统:"]="Select Root partition filesystem:"
        I18N["选择分区方式:"]="Select partition method:"
        I18N["选择安装模式"]="Select Installation Mode"
        I18N["选择时区:"]="Select timezone:"
        I18N["选择桌面环境:"]="Select desktop environment:"
        I18N["选择磁盘"]="Select Disk"
        I18N["选择系统语言:"]="Select system language:"
        I18N["选择要安装的额外软件:"]="Select extra software to install:"
        I18N["选择软件源:"]="Select software source:"
        I18N["逐步自定义"]="Step by Step Custom"
        I18N["重要提示"]="Important Notes"
        I18N["重要提示："]="Important Notes:"
        I18N["错误"]="Error"
        I18N["镜像源"]="Mirror Source"
        I18N["镜像源:     ${CFG[mirror]}"]="Mirror:     \${CFG[mirror]}"
        I18N["镜像源:     中国镜像"]="Mirror:     China Mirror"
        I18N["防火墙"]="Firewall"
        I18N["韩文"]="Korean"
        I18N["额外软件"]="Extra Software"
        I18N["香港"]="Hong Kong"
        I18N["驱动安装"]="Driver install"
        I18N["驱动选择"]="Driver Selection"
        I18N["默认密码"]="Default Password"
        I18N["默认密码:   arch (用户名: user)"]="Default password:   arch (Username: user)"
    fi
}

t() {
    echo "${I18N[$1]:-$1}"
}

# 默认英文，然后让用户选择
CFG[lang]="en"
select_language
load_i18n


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
    echo "$(t "CPU: ${model} (${cores}核)")"
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
        echo "$(t "未检测到")"
    fi
}

detect_wireless() {
    local wifi=$(lspci -nn | grep -i "network\|wireless\|wifi" | wc -l)
    if [[ $wifi -gt 0 ]]; then
        echo "$(t "已检测 ($wifi 个设备)")"
    else
        echo "$(t "未检测")"
    fi
}

detect_bluetooth() {
    if lsusb 2>/dev/null | grep -qi "bluetooth"; then
        echo "$(t "已检测")"
    else
        echo "$(t "未检测")"
    fi
}

detect_touchpad() {
    if [[ -f /proc/bus/input/devices ]] && grep -qi "touchpad" /proc/bus/input/devices; then
        echo "$(t "已检测")"
    else
        echo "$(t "未检测")"
    fi
}

detect_laptop() {
    local chassis=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)
    if [[ "$chassis" =~ ^(8|9|10|14)$ ]]; then
        echo "$(t "是")"
    else
        echo "$(t "否")"
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
                        warnings="${warnings}$(t "检测到") $name $(t "系统引导")\n"
                        ;;
                esac
            done
        fi
    fi
    # 检查 NTFS
    if lsblk -o FSTYPE -n | grep -qi "ntfs"; then
        warnings="${warnings}$(t "检测到") NTFS $(t "分区") ($(t "可能为") Windows)\n"
    fi
    echo -e "$warnings"
}

# ── 页面函数 ──

page_welcome() {
    dialog --title "$(t "Arch Linux 安装向导")" --msgbox "
    $(t "Arch Linux 图形化安装向导")
    ==========================

    $(t "欢迎使用 Arch Linux 安装向导！")

    $(t "重要提示")：
    $(t "- 请确保已备份所有重要数据")
    $(t "- 本向导会格式化目标磁盘")
    $(t "- 建议在虚拟机中先行测试")

    $(t "支持两种安装模式")：
    $(t "[AUTO] 自动安装 -> 一键傻瓜式")
    $(t "[CFG]  手动安装 -> 逐步自定义")
" 20 60

    local choice=$(menu_box "$(t "选择安装模式")" "$(t "请选择安装模式:")" \
        "auto" "$(t "[AUTO] 自动安装 - 一键完成，默认配置")" \
        "manual" "$(t "[CFG] 手动安装 - 逐步自定义")" 2>&1 >/dev/tty)

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

    dialog --title "$(t "硬件检测")" --msgbox "
    $(t "硬件检测报告")
    ============

    CPU:     $cpu
    $(t "内存"):    $mem
    $(t "显卡"):    $gpu
    $(t "声卡"):    $audio
    $(t "无线"):    $wifi
    $(t "蓝牙"):    $bt
    $(t "触摸板"):  $tp
    $(t "笔记本"):  $laptop

    $(t "向导将根据检测结果推荐驱动方案。")
" 18 65
}

page_dual_boot_check() {
    local warnings=$(detect_dual_boot)

    if [[ -n "$warnings" ]]; then
        beep 3
        dialog --title "$(t "[!!!] 双系统检测警告")" --msgbox "
    $(t "[!!!] 警告：检测到双系统！")

    $warnings

    $(t "继续安装可能导致其他系统无法启动！")
    $(t "请务必确认你知道自己在做什么！")

    $(t "下一步需要输入确认信息。")
" 20 65

        local confirm=$(input_box "$(t "确认")" "$(t "请输入 I KNOW 以确认继续:")" "")
        if [[ "$confirm" != "I KNOW" ]]; then
            dialog --title "$(t "错误")" --msgbox "$(t "确认失败！必须输入 I KNOW（全大写）才能继续。")" 8 50
            exit 1
        fi
    else
        dialog --title "$(t "[OK] 双系统检测")" --msgbox "$(t "未检测到双系统，可以继续安装。")" 8 50
    fi
}

page_disk_select() {
    local disks=()
    while IFS=' ' read -r dev size model; do
        disks+=("$dev" "$size - $model")
    done <<< "$(get_disks)"

    if [[ ${#disks[@]} -eq 0 ]]; then
        dialog --title "$(t "错误")" --msgbox "$(t "未检测到磁盘！")" 8 40
        exit 1
    fi

    CFG[disk]=$(menu_box "$(t "选择磁盘")" "$(t "请选择要安装 Arch 的目标磁盘:")" "${disks[@]}")
}

page_partition() {
    local choice=$(menu_box "$(t "分区方案")" "$(t "选择分区方式:")" \
        "auto" "$(t "自动分区 - EFI(512M) + Swap(8G) + Root(剩余)")" \
        "manual" "$(t "手动分区 - 使用 cfdisk 自行划分")" 2>&1 >/dev/tty)

    CFG[scheme]="$choice"

    if [[ "$choice" == "manual" ]]; then
        CFG[efi_size]=$(input_box "$(t "EFI 分区")" "$(t "EFI 分区大小 (如 512M):")" "512M")
        CFG[swap_size]=$(input_box "$(t "Swap 分区")" "$(t "Swap 分区大小 (如 8G):")" "8G")
        local root_size=$(input_box "$(t "Root 分区")" "$(t "Root 分区大小 (输 max 表示剩余全部):")" "max")
        local home_size=$(input_box "$(t "Home 分区")" "$(t "Home 分区大小 (不需要输 none):")" "none")
    fi
}

page_format_confirm() {
    dialog --title "$(t "[!] 格式化确认")" --yesno "
    $(t "即将格式化磁盘"): ${CFG[disk]}
    $(t "分区方案"): ${CFG[scheme]}

    $(t "[!] 警告：此操作将清除磁盘上所有数据！")
    $(t "[!] 所有数据将不可恢复！")

    $(t "是否确认继续？")
" 15 60

    if [[ $? -ne 0 ]]; then
        dialog --title "$(t "已取消")" --msgbox "$(t "安装已取消。")" 8 40
        exit 0
    fi

    local fs=$(menu_box "$(t "文件系统")" "$(t "选择 Root 分区文件系统:")" \
        "ext4" "$(t "ext4 - 推荐，稳定可靠")" \
        "btrfs" "$(t "btrfs - 高级功能，支持快照")" \
        "xfs" "$(t "xfs - 大文件性能优秀")" 2>&1 >/dev/tty)
    CFG[filesystem]="$fs"
}

page_system_config() {
    CFG[hostname]=$(input_box "$(t "主机名")" "$(t "设置主机名:")" "${CFG[hostname]}")
    CFG[username]=$(input_box "$(t "用户名")" "$(t "设置用户名:")" "${CFG[username]}")

    while true; do
        local pw1=$(password_box "$(t "用户密码")" "$(t "设置用户密码:")")
        local pw2=$(password_box "$(t "确认密码")" "$(t "再次输入用户密码:")")

        if [[ "$pw1" != "$pw2" ]]; then
            dialog --title "$(t "错误")" --msgbox "$(t "两次输入的密码不一致！请重新输入。")" 8 50
        elif [[ -z "$pw1" ]]; then
            dialog --title "$(t "错误")" --msgbox "$(t "密码不能为空！")" 8 40
        else
            CFG[password]="$pw1"
            break
        fi
    done

    local root_pw=$(password_box "$(t "Root 密码")" "$(t "设置 Root 密码 (留空则与用户密码相同):")")
    if [[ -z "$root_pw" ]]; then
        CFG[root_password]="${CFG[password]}"
    else
        CFG[root_password]="$root_pw"
    fi

    CFG[timezone]=$(menu_box "$(t "时区")" "$(t "选择时区:")" \
        "Asia/Shanghai" "$(t "上海 (中国)")" \
        "Asia/Hong_Kong" "$(t "香港")" \
        "Asia/Taipei" "$(t "台北")" \
        "Asia/Tokyo" "$(t "东京")" \
        "Europe/London" "$(t "伦敦")" \
        "America/New_York" "$(t "纽约")" 2>&1 >/dev/tty)

    CFG[locale]=$(menu_box "$(t "系统语言")" "$(t "选择系统语言:")" \
        "zh_CN.UTF-8" "$(t "简体中文")" \
        "zh_TW.UTF-8" "$(t "繁体中文")" \
        "en_US.UTF-8" "$(t "英文")" \
        "ja_JP.UTF-8" "$(t "日文")" \
        "ko_KR.UTF-8" "$(t "韩文")" 2>&1 >/dev/tty)
}

page_desktop() {
    CFG[de]=$(menu_box "$(t "桌面环境")" "$(t "选择桌面环境:")" \
        "gnome" "$(t "GNOME - 简洁现代，适合新手")" \
        "kde" "$(t "KDE Plasma - 功能丰富，高度定制")" \
        "xfce" "$(t "XFCE - 轻量稳定")" \
        "hyprland" "$(t "Hyprland - Wayland 平铺，极客首选")" \
        "none" "$(t "不安装桌面 - 仅基础系统")" 2>&1 >/dev/tty)

    local pkgs=$(checklist_box "$(t "额外软件")" "$(t "选择要安装的额外软件:")" \
        "browser" "$(t "浏览器 (Firefox)")" on \
        "editor" "$(t "编辑器 (Vim/Nano)")" on \
        "media" "$(t "多媒体 (VLC/MPV)")" off \
        "office" "$(t "办公套件 (LibreOffice)")" off \
        "gaming" "$(t "游戏工具 (Steam/Lutris)")" off 2>&1 >/dev/tty)

    [[ "$pkgs" == *"browser"* ]] && CFG[pkg_browser]="yes" || CFG[pkg_browser]="no"
    [[ "$pkgs" == *"editor"* ]] && CFG[pkg_editor]="yes" || CFG[pkg_editor]="no"
    [[ "$pkgs" == *"media"* ]] && CFG[pkg_media]="yes" || CFG[pkg_media]="no"
    [[ "$pkgs" == *"office"* ]] && CFG[pkg_office]="yes" || CFG[pkg_office]="no"
    [[ "$pkgs" == *"gaming"* ]] && CFG[pkg_gaming]="yes" || CFG[pkg_gaming]="no"
}

page_driver() {
    local gpu=$(detect_gpu)

    local drivers=$(checklist_box "$(t "驱动选择")" "$(t "根据硬件检测，选择要安装的驱动:")" \
        "gpu" "$(t "显卡驱动 ($gpu)")" on \
        "audio" "$(t "声卡驱动 (ALSA/PipeWire)")" on \
        "wifi" "$(t "无线网卡驱动")" on \
        "bt" "$(t "蓝牙驱动")" on \
        "touchpad" "$(t "触摸板驱动")" on \
        "tlp" "$(t "笔记本电源管理 (TLP)")" on \
        "printer" "$(t "打印机驱动 (CUPS)")" off \
        "camera" "$(t "摄像头驱动 (V4L)")" off \
        "wine" "$(t "Wine 兼容层 + Lutris")" on 2>&1 >/dev/tty)

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
    CFG[mirror]=$(menu_box "$(t "镜像源")" "$(t "选择软件源:")" \
        "china" "$(t "中国镜像 (清华/中科大/阿里)")" \
        "official" "$(t "官方镜像")" 2>&1 >/dev/tty)
}

page_confirm() {
    local summary="
    $(t "安装配置摘要")
    ============

    $(t "目标磁盘"):   ${CFG[disk]}
    $(t "分区方案"):   ${CFG[scheme]}
    $(t "文件系统"):   ${CFG[filesystem]}
    $(t "主机名"):     ${CFG[hostname]}
    $(t "用户名"):     ${CFG[username]}
    $(t "时区"):       ${CFG[timezone]}
    $(t "语言"):       ${CFG[locale]}
    $(t "桌面环境"):   ${CFG[de]}
    $(t "镜像源"):     ${CFG[mirror]}

    $(t "[!] 警告：此操作将格式化") ${CFG[disk]}！
"

    dialog --title "$(t "安装确认")" --yesno "$summary" 20 60
    if [[ $? -ne 0 ]]; then
        dialog --title "$(t "已取消")" --msgbox "$(t "安装已取消。")" 8 40
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
    [[ "${CFG[install_tlp]}" == "yes" && "$(detect_laptop)" == "$(t "是")" ]] && tlp_pkgs="tlp tlp-rdw acpi_call"

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
        part_cmd="$(t "# 手动分区 - 请使用 cfdisk $disk 分区后，手动格式化和挂载")"
    fi

    cat > /tmp/arch-install.sh << EOF
#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Arch Linux 安装脚本
# 生成时间: $(date)
# 配置: ${CFG[username]}@${CFG[hostname]} / ${CFG[de]} / ${CFG[locale]}
# ═══════════════════════════════════════════════════════════════

set -e
trap 'echo "$(t "[!] 安装中断于第 \$LINENO 行")"; exit 1' ERR

echo "$(t "[AUTO] Arch Linux 安装开始...")"

# 1. 基础设置
echo "$(t "[NET] 设置网络...")"
timedatectl set-ntp true

# 2. 镜像源
echo "$(t "[MIRROR] 配置镜像源...")"
$mirror_block
$multilib

# 3. 分区
echo "$(t "[DISK] 正在分区 $disk...")"
$part_cmd

echo "$(t "[OK] 分区完成")"

# 4. 安装基础系统
echo "$(t "[PKG] 安装基础系统（可能需要 10-30 分钟）...")"
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
echo "$(t "[CFG] 配置系统...")"
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
echo "$(t "[BOOT] 安装引导...")"
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# 8. 完成
umount -R /mnt
echo ""
echo "============================================"
echo "$(t "[OK] Arch Linux 安装完成！")"
echo ""
echo "$(t "用户名: ${CFG[username]}")"
echo "密码:   ${CFG[password]}"
echo "桌面:   ${CFG[de]}"
echo ""
echo "$(t "请执行 reboot 重启")"
echo "============================================"
EOF

    chmod +x /tmp/arch-install.sh
}

page_auto_confirm() {
    dialog --title "$(t "[AUTO] 自动安装确认")" --yesno "
    $(t "即将执行自动安装，以下配置不可更改：")

    $(t "安装模式"):   $(t "全自动一键安装")
    $(t "桌面环境"):   GNOME Wayland
    $(t "系统语言"):   $(t "英文") (en_US.UTF-8)
    $(t "默认密码"):   arch ($(t "用户名"): user)
    $(t "分区方案"):   $(t "自动") (EFI + Root + Swap)
    $(t "镜像源"):     $(t "中国镜像")
    $(t "显卡驱动"):   $(t "自动检测安装")
    $(t "声卡驱动"):   ALSA + PipeWire
    $(t "网卡驱动"):   $(t "有线") + $(t "无线")
    $(t "蓝牙驱动"):   $(t "自动检测")
    $(t "Wine"):       $(t "自动安装")
    $(t "系统优化"):   zram + swap + fstab + $(t "防火墙")

    $(t "[!] 警告：此操作将格式化整个目标磁盘！")

    $(t "是否确认继续？")
" 25 60

    if [[ $? -ne 0 ]]; then
        dialog --title "$(t "已取消")" --msgbox "$(t "安装已取消。")" 8 40
        exit 0
    fi
}

page_auto_install() {
    generate_script

    dialog --title "$(t "[OK] 脚本已生成")" --msgbox "
    $(t "自动安装脚本已生成！")

    $(t "位置"): /tmp/arch-install.sh

    $(t "安全提示")：
    $(t "- 建议先查看脚本内容确认无误")
    $(t "- 在终端中执行: bash /tmp/arch-install.sh")

    $(t "脚本包含")：
    $(t "- 分区/格式化")
    $(t "- 基础系统安装")
    $(t "- 驱动安装")
    $(t "- 桌面环境")
    $(t "- 常用软件")
    $(t "- 系统优化")
" 18 60
}

page_manual_install() {
    generate_script

    dialog --title "$(t "[OK] 脚本已生成")" --msgbox "
    $(t "手动安装脚本已生成！")

    $(t "位置"): /tmp/arch-install.sh

    $(t "请在终端中执行"):
    bash /tmp/arch-install.sh

    $(t "或先查看脚本内容确认无误后再执行。")
" 15 60
}

# ── 主流程 ──

main() {
    # 检查是否在 Live CD
    if [[ ! -f /arch ]]; then
        dialog --title "$(t "[!] 环境检测")" --yesno "
    未检测到 Arch Live CD 环境。
    本向导应在 Arch ISO 启动后的 Live 环境中运行。

    当前仅为演示/测试模式，是否继续？
" 12 60
        [[ $? -ne 0 ]] && exit 0
    fi

    # 检查 dialog
    if ! command -v dialog &>/dev/null; then
        dialog --title "$(t "[!] 缺少依赖")" --yesno "
    未找到 dialog 工具。
    是否自动安装？ (pacman -S dialog)
" 10 50
        if [[ $? -eq 0 ]]; then
            pacman -Sy --noconfirm dialog
        else
            echo "$(t "[!] 需要安装 dialog 才能运行本向导")"
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
    echo "$(t "[OK] 向导完成！")"
    echo ""
    echo "$(t "安装脚本位置: /tmp/arch-install.sh")"
    echo ""
    if [[ "${CFG[mode]}" == "auto" ]]; then
        echo "$(t "自动模式配置:")"
        echo "$(t "  用户名: user")"
        echo "$(t "  密码:   arch")"
        echo "$(t "  桌面:   GNOME Wayland")"
        echo "$(t "  语言:   英文")"
    else
        echo "$(t "手动模式配置:")"
        echo "$(t "  用户名: ${CFG[username]}")"
        echo "$(t "  主机名: ${CFG[hostname]}")"
        echo "  桌面:   ${CFG[de]}"
        echo "  语言:   ${CFG[locale]}"
    fi
    echo ""
    echo "$(t "执行命令: bash /tmp/arch-install.sh")"
    echo "============================================"
    echo ""
}

main "$@"
