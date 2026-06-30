#!/bin/bash

# 1. 刷新日志文件
echo "=== Container Started at $(date) ===" > /tmp/komari.log

# ==========================================
# 2. 启动 Tailscale 核心服务
# ==========================================
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &
sleep 2

tailscale up --authkey="${TAILSCALE_AUTHKEY}" --accept-routes=true --ssh=true --ephemeral &
sleep 2

# ==========================================
# 3. 纯净版 Komari 连接逻辑
# ==========================================
RN_INNER_IP="100.91.38.95"
KOMARI_PORT="25774"

if [ -n "${KOMARI_TOKEN}" ]; then
    echo "Starting Komari Agent via Tailscale tunnel to RN..." >> /tmp/komari.log
    
    # 直接在后台拉起系统中的 komari-agent，并将日志追加输出
    nohup komari-agent -e "${RN_INNER_IP}:${KOMARI_PORT}" -t "${KOMARI_TOKEN}" --protocol-version 1 >> /tmp/komari.log 2>&1 &
else
    echo "Warning: KOMARI_TOKEN is not set." >> /tmp/komari.log
fi

# 保持前台运行，方便你随时 cat /tmp/komari.log 查看
tail -f /tmp/komari.log
