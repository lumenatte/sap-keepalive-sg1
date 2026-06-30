#!/bin/bash

# 1. 在后台拉起 Tailscale 核心守护进程（使用用户态网络，并开启 1055 代理端口）
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &

# 2. 等待 2 秒让守护进程稳固运行
sleep 2

# 3. 自动登录并加入网络，同时开启 --ssh 托管服务！
if [ -z "$TAILSCALE_AUTHKEY" ]; then
  echo "错误：未设置 TAILSCALE_AUTHKEY 环境变量" >&2
else
  tailscale up --authkey="$TAILSCALE_AUTHKEY" --accept-routes=true --ssh=true &
fi

# 4. 下载并启动 Komari 监控探针（CF 容器无 init 系统，需手动后台运行）
KOMARI_DIR=/tmp/komari
mkdir -p "$KOMARI_DIR"

if [ ! -f "$KOMARI_DIR/komari-agent" ]; then
  curl -fsSL -o "$KOMARI_DIR/komari-agent" \
    https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-amd64
  chmod +x "$KOMARI_DIR/komari-agent"
fi

if [ -z "$KOMARI_TOKEN" ] || [ -z "$KOMARI_ENDPOINT" ]; then
  echo "错误：未设置 KOMARI_TOKEN 或 KOMARI_ENDPOINT 环境变量" >&2
else
  "$KOMARI_DIR/komari-agent" -e "$KOMARI_ENDPOINT" -t "$KOMARI_TOKEN" &
fi

# 5. 保持容器前台挂起
tail -f /dev/null
