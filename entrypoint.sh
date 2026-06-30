#!/bin/bash

# 1. 刷新日志文件
echo "=== Container Started at $(date) ===" > /tmp/komari.log

# ==========================================
# 2. 纯净版：自动检测并下载最新的 komari-agent
# ==========================================
if [ ! -f "/usr/local/bin/komari-agent" ]; then
    echo "komari-agent not found, fetching the latest release..." >> /tmp/komari.log
    
    # 直接从官方发布源下载纯净的 Linux AMD64 架构二进制文件
    curl -L "https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip" -o /tmp/komari.zip
    
    # 解压并精准命名为 komari-agent，不留任何痕迹
    unzip -q /tmp/komari.zip -d /tmp/komari_unpack/
    mv /tmp/komari_unpack/*agent* /usr/local/bin/komari-agent
    chmod +x /usr/local/bin/komari-agent
    
    # 清理现场临时文件
    rm -rf /tmp/komari.zip /tmp/komari_unpack/
    echo "komari-agent deployment completed." >> /tmp/komari.log
fi

# ==========================================
# 3. 启动 Tailscale 核心服务
# ==========================================
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &
sleep 2

tailscale up --authkey="${TAILSCALE_AUTHKEY}" --accept-routes=true --ssh=true --ephemeral &
sleep 2

# ==========================================
# 4. 纯净版 Komari v2 连接逻辑
# ==========================================
RN_INNER_IP="100.91.38.95"
KOMARI_PORT="25774"

if [ -n "${KOMARI_TOKEN}" ]; then
    echo "Starting Komari Agent v2 via Tailscale tunnel to RN..." >> /tmp/komari.log
    
    # 🔥 v2 架构一键直接运行的正确命令格式：
    nohup /usr/local/bin/komari-agent service run --server "${RN_INNER_IP}:${KOMARI_PORT}" --secret "${KOMARI_TOKEN}" --tls >> /tmp/komari.log 2>&1 &
    
    # 💡 提示：如果你的 RackNerd 服务端没开 gRPC 的 TLS（证书加密），请把上面的 --tls 删掉，改成下面这行：
    # nohup /usr/local/bin/komari-agent service run --server "${RN_INNER_IP}:${KOMARI_PORT}" --secret "${KOMARI_TOKEN}" >> /tmp/komari.log 2>&1 &
else
    echo "Warning: KOMARI_TOKEN is not set." >> /tmp/komari.log
fi

# 保持前台运行
tail -f /tmp/komari.log
