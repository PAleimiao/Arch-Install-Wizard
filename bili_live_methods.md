# 🐧 Linux 获取 B 站推流码 — 方案总结

> 系统：Arch Linux + Hyprland  
> 目标：获取 B 站直播推流码（RTMP 地址 + 串流密钥），填入 OBS 开播

---

## 方案一：Rust 预编译二进制 ⭐ 推荐先试

**项目**：`TNXG/bilibili_live_stream`  
**特点**：纯命令行、零依赖、开箱即用

```bash
# 1. 下载 Release（选 x86_64-unknown-linux-musl 版，静态链接兼容性最好）
wget https://github.com/TNXG/bilibili_live_stream/releases/download/vX.X.X/bili_live-x86_64-unknown-linux-musl.tar.gz

# 2. 解压运行
tar -xzf bili_live-x86_64-unknown-linux-musl.tar.gz
chmod +x bili_live
./bili_live
```

**使用流程**：扫码登录 → 设置直播间标题/分区 → 点"开始直播" → 复制 RTMP 服务器地址 + 串流密钥 → 填入 OBS

| ✅ 优点 | ❌ 缺点 |
|---|---|
| 免费、跨平台、零依赖 | 纯命令行，无 GUI |
| 静态链接，不挑系统 | |

---

## 方案二：Python + Vue GUI（功能最全）

**项目**：`ChaceQC/bilibili_live_stream_code`  
**特点**：图形界面、支持弹幕/礼物显示、直播间管理

**依赖**：git、nodejs(≥18)、npm、python3、pip3、Qt 运行时库

```bash
# 1. 克隆
git clone https://github.com/ChaceQC/bilibili_live_stream_code.git
cd bilibili_live_stream_code

# 2. 构建前端
cd frontend && npm install && npm run build && cd ..

# 3. 装 Python 依赖
pip3 install -r requirements.txt

# 4. 运行
python3 main.py
```

**Arch 可能缺的 Qt 依赖**（报错 `xcb` 时）：
```bash
sudo pacman -S libxinerama libxcb libnss libxcomposite libxdamage libxrandr libxtst libxi
```

| ✅ 优点 | ❌ 缺点 |
|---|---|
| 图形界面、功能全 | 需要 Node.js + Python 环境 |
| 支持弹幕/礼物 | 构建步骤稍多 |

---

## 方案三（备选）：Python CLI 工具

**项目**：`chenxi-Eumenides/bilibili_live_tool`

```bash
git clone https://github.com/chenxi-Eumenides/bilibili_live_tool.git
cd bilibili_live_tool
pip3 install uv
uv sync
uv run main_cli.py
```

---

## 🎯 推荐路线

| 你的需求 | 选哪个 |
|---|---|
| 只想快速拿到推流码开播 | **方案一**（Rust 二进制） |
| 想要图形界面 + 弹幕功能 | **方案二**（Python GUI） |
| 系统干净，不想装 Node.js | **方案一** |

**推流码有效期**：约 2 小时，过期前在工具里刷新即可。  
**OBS 填法**：推流 → 自定义 → 服务器填 RTMP 地址，串流密钥填密钥（两段分开填）。

---

*整理 by 啊嘞喵 + Kimi*
