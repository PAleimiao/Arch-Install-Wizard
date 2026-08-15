#!/bin/bash
# ============================================
# B站直播开播脚本 (Arch Linux)
# 用途: 获取推流码 + 用ffmpeg推流
# 作者: 啊嘞喵
#
# 📌 2026-08-15 更新：新增 3 种推流码获取方案
#    详见同目录 bili_live_methods.md
#    方案一: Rust 预编译二进制 (推荐，零依赖)
#    方案二: Python + Vue GUI (功能最全，带界面)
#    方案三: Python CLI 工具 (备选)
# ============================================


set -e

echo "🎬 B站直播开播工具"
echo "=================="

# ---------- 检查依赖 ----------
check_dep() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ 未安装: $1"
        return 1
    fi
    echo "✅ $1 已安装"
    return 0
}

echo ""
echo "📦 检查依赖..."
check_dep ffmpeg || { echo "安装: sudo pacman -S ffmpeg"; exit 1; }
check_dep curl || { echo "安装: sudo pacman -S curl"; exit 1; }

# ---------- 方式1: 用 bili-live-hime 获取推流码 ----------
# GitHub: https://github.com/Rsplwe/bili-live-hime
install_hime() {
    echo ""
    echo "📥 安装 bili-live-hime (B站直播姬替代工具)..."

    # 需要 Node.js >= 18 和 Rust
    if ! command -v node &> /dev/null; then
        echo "安装 Node.js..."
        sudo pacman -S nodejs npm
    fi

    if ! command -v rustc &> /dev/null; then
        echo "安装 Rust..."
        sudo pacman -S rust
    fi

    # 克隆并构建
    cd /tmp
    git clone https://github.com/Rsplwe/bili-live-hime.git
    cd bili-live-hime
    npm install

    echo "✅ bili-live-hime 安装完成"
    echo "启动: cd /tmp/bili-live-hime && npm run tauri dev"
    echo "或下载预编译版: https://github.com/Rsplwe/bili-live-hime/releases"
}

# ---------- 方式2: 用 Python 脚本获取推流码 ----------
# 更轻量，不需要GUI
install_python_tool() {
    echo ""
    echo "📥 安装 Python 推流码获取工具..."

    if ! command -v python3 &> /dev/null; then
        sudo pacman -S python python-pip
    fi

    pip3 install --user requests qrcode pillow

    # 创建获取推流码的脚本
    cat > /tmp/bili_get_stream.py << 'PYTHON_EOF'
#!/usr/bin/env python3
import requests
import json
import sys
import os

# B站直播API
BASE_URL = "https://api.live.bilibili.com"

class BiliLive:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
            "Referer": "https://live.bilibili.com"
        })
        self.cookies = {}

    def login_by_cookie(self, cookie_str):
        """用Cookie登录"""
        for item in cookie_str.split(";"):
            if "=" in item:
                k, v = item.strip().split("=", 1)
                self.cookies[k] = v
                self.session.cookies.set(k, v)
        print("✅ Cookie已加载")

    def get_user_info(self):
        """获取用户信息"""
        r = self.session.get(f"{BASE_URL}/xlive/web-ucenter/user/get_user_info")
        data = r.json()
        if data.get("code") == 0:
            info = data["data"]
            print(f"👤 用户: {info.get('uname', '未知')}")
            print(f"🆔 UID: {info.get('uid', '未知')}")
            return info
        else:
            print("❌ 获取用户信息失败，Cookie可能已过期")
            return None

    def get_room_info(self):
        """获取直播间信息"""
        r = self.session.get(f"{BASE_URL}/xlive/web-ucenter/v1/get_room_info")
        data = r.json()
        if data.get("code") == 0:
            room = data["data"]
            print(f"📺 直播间ID: {room.get('room_id')}")
            print(f"🏠 短号: {room.get('short_id') or '无'}")
            print(f"📊 状态: {'开播中' if room.get('live_status') == 1 else '未开播'}")
            return room
        return None

    def start_live(self, room_id, area_id=27, title="Linux直播测试"):
        """开始直播，获取推流码"""
        # area_id 27 = 单机游戏，可根据需要修改
        # 获取分区列表: https://api.live.bilibili.com/room/v1/Area/getList

        csrf = self.cookies.get("bili_jct", "")

        payload = {
            "room_id": room_id,
            "platform": "pc",
            "area_v2": area_id,
            "backup_stream": 0,
            "csrf_token": csrf,
            "csrf": csrf
        }

        r = self.session.post(f"{BASE_URL}/xlive/app-blink/v1/live/start", data=payload)
        data = r.json()

        if data.get("code") == 0:
            result = data["data"]
            print("\n🎉 开播成功！")
            print(f"🔗 RTMP地址: {result.get('rtmp', {}).get('addr', '')}")
            print(f"🔑 推流码: {result.get('rtmp', {}).get('code', '')}")
            print(f"\n📋 OBS设置:")
            print(f"   服务器: {result.get('rtmp', {}).get('addr', '')}")
            print(f"   串流密钥: {result.get('rtmp', {}).get('code', '')}")
            return result
        else:
            print(f"❌ 开播失败: {data.get('message', '未知错误')}")
            return None

    def stop_live(self, room_id):
        """结束直播"""
        csrf = self.cookies.get("bili_jct", "")
        payload = {
            "room_id": room_id,
            "platform": "pc",
            "csrf_token": csrf,
            "csrf": csrf
        }
        r = self.session.post(f"{BASE_URL}/xlive/app-blink/v1/live/stop", data=payload)
        data = r.json()
        if data.get("code") == 0:
            print("✅ 已下播")
        else:
            print(f"❌ 下播失败: {data.get('message', '')}")


def main():
    print("=" * 50)
    print("🎬 B站推流码获取工具")
    print("=" * 50)

    # 从环境变量或文件读取Cookie
    cookie_file = os.path.expanduser("~/.bili_cookies.txt")

    if len(sys.argv) > 1:
        cookie_str = sys.argv[1]
    elif os.path.exists(cookie_file):
        with open(cookie_file, "r") as f:
            cookie_str = f.read().strip()
    else:
        print("\n请提供B站Cookie，或保存到 ~/.bili_cookies.txt")
        print("获取方法:")
        print("1. 登录B站网页版")
        print("2. F12打开开发者工具 → Application/Storage → Cookies")
        print("3. 复制所有cookie拼接成字符串")
        print("\n用法: python3 bili_get_stream.py 'SESSDATA=xxx; bili_jct=xxx; ...'")
        sys.exit(1)

    bili = BiliLive()
    bili.login_by_cookie(cookie_str)

    # 获取用户信息
    user = bili.get_user_info()
    if not user:
        sys.exit(1)

    # 获取直播间信息
    room = bili.get_room_info()
    if not room:
        sys.exit(1)

    room_id = room.get("room_id")

    print("\n📋 操作选项:")
    print("1. 开始直播 (获取推流码)")
    print("2. 结束直播")
    print("3. 仅查看信息")

    choice = input("\n请选择 (1/2/3): ").strip()

    if choice == "1":
        title = input("直播标题 (回车使用默认): ").strip() or "Linux桌面直播"
        print("\n可选分区:")
        print("  27 - 单机游戏")
        print("  65 - 网络游戏")
        print("  33 - 影音馆")
        print("  235 - 学习")
        area = input("分区ID (回车使用27-单机游戏): ").strip() or "27"

        result = bili.start_live(room_id, int(area), title)
        if result:
            # 保存推流信息到文件
            rtmp_addr = result.get("rtmp", {}).get("addr", "")
            rtmp_code = result.get("rtmp", {}).get("code", "")

            with open(os.path.expanduser("~/.bili_stream.txt"), "w") as f:
                f.write(f"RTMP地址: {rtmp_addr}\n")
                f.write(f"推流码: {rtmp_code}\n")
            print("\n💾 推流信息已保存到 ~/.bili_stream.txt")

    elif choice == "2":
        bili.stop_live(room_id)
    else:
        print("👋 再见")

if __name__ == "__main__":
    main()
PYTHON_EOF

    chmod +x /tmp/bili_get_stream.py
    echo "✅ Python脚本已创建: /tmp/bili_get_stream.py"
}

# ---------- 方式3: 用 ffmpeg 推流 ----------
ffmpeg_stream() {
    echo ""
    echo "🎥 ffmpeg 推流设置"
    echo "=================="

    # 读取推流信息
    stream_file="$HOME/.bili_stream.txt"
    if [ -f "$stream_file" ]; then
        echo "📄 发现已保存的推流信息:"
        cat "$stream_file"
        echo ""
    fi

    echo "请选择推流源:"
    echo "1. 屏幕录制 (wayland)"
    echo "2. 屏幕录制 (x11)"
    echo "3. 摄像头"
    echo "4. 视频文件"
    echo "5. 手动输入推流地址"

    read -p "选择 (1-5): " source_choice

    read -p "RTMP推流地址: " rtmp_url
    read -p "推流码/串流密钥: " stream_key

    full_url="${rtmp_url}/${stream_key}"

    case $source_choice in
        1)
            # Wayland屏幕录制 (pipewire)
            echo "🎬 开始Wayland屏幕录制推流..."
            ffmpeg -f pipewire -i default -c:v libx264 -preset fast -b:v 4500k -maxrate 4500k -bufsize 9000k -g 60 -keyint_min 60 -sc_threshold 0 -c:a aac -b:a 128k -ar 44100 -f flv "$full_url"
            ;;
        2)
            # X11屏幕录制
            echo "🎬 开始X11屏幕录制推流..."
            read -p "显示器编号 (默认 :0.0): " display
            display=${display:-":0.0"}
            ffmpeg -f x11grab -r 30 -s 1920x1080 -i "$display" -f pulse -i default -c:v libx264 -preset fast -b:v 4500k -maxrate 4500k -bufsize 9000k -g 60 -c:a aac -b:a 128k -ar 44100 -f flv "$full_url"
            ;;
        3)
            # 摄像头
            echo "🎬 开始摄像头推流..."
            ffmpeg -f v4l2 -framerate 30 -video_size 1280x720 -i /dev/video0 -f pulse -i default -c:v libx264 -preset fast -b:v 3000k -maxrate 3000k -bufsize 6000k -g 60 -c:a aac -b:a 128k -ar 44100 -f flv "$full_url"
            ;;
        4)
            # 视频文件
            read -p "视频文件路径: " video_file
            echo "🎬 开始视频文件推流..."
            ffmpeg -re -i "$video_file" -c:v libx264 -preset fast -b:v 4500k -maxrate 4500k -bufsize 9000k -g 60 -c:a aac -b:a 128k -ar 44100 -f flv "$full_url"
            ;;
        5)
            # 手动
            echo "🎬 手动推流模式"
            echo "示例命令:"
            echo "ffmpeg -f x11grab -r 30 -s 1920x1080 -i :0.0 -c:v libx264 -preset fast -b:v 4500k -c:a aac -b:a 128k -f flv $full_url"
            ;;
    esac
}

# ---------- 主菜单 ----------
main_menu() {
    echo ""
    echo "🎯 主菜单"
    echo "========="
    echo "1. 安装 bili-live-hime (GUI工具，推荐)"
    echo "2. 安装 Python推流码获取脚本 (命令行)"
    echo "3. 用 ffmpeg 开始推流"
    echo "4. 退出"
    echo ""

    read -p "请选择 (1-4): " choice

    case $choice in
        1) install_hime ;;
        2) install_python_tool ;;
        3) ffmpeg_stream ;;
        4) echo "👋 再见"; exit 0 ;;
        *) echo "❌ 无效选项"; main_menu ;;
    esac
}

# 如果直接传参运行
if [ "$1" == "stream" ]; then
    ffmpeg_stream
    exit 0
fi

main_menu
