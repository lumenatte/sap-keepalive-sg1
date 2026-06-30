#!/bin/bash

# 1. 刷新日志文件
echo "=== Container Started at $(date) ===" > /tmp/komari.log

# ==========================================
# 2. 动态检测并下载最新的 komari-agent
# ==========================================
if [ ! -f "/usr/local/bin/komari-agent" ]; then
    echo "komari-agent not found, fetching the latest release..." >> /tmp/komari.log
    curl -L "https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip" -o /tmp/komari.zip
    unzip -q /tmp/komari.zip -d /tmp/komari_unpack/
    mv /tmp/komari_unpack/*agent* /usr/local/bin/komari-agent
    chmod +x /usr/local/bin/komari-agent
    rm -rf /tmp/komari.zip /tmp/komari_unpack/
    echo "komari-agent deployment completed." >> /tmp/komari.log
fi

# ==========================================
# 3. 启动 Tailscale 核心服务（修正参数为 --auth-key）
# ==========================================
echo "Starting tailscaled..." >> /tmp/komari.log
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 >> /tmp/komari.log 2>&1 &
sleep 3

echo "Bringing tailscale up..." >> /tmp/komari.log
# 🔥 按照 image_717d3b.png 的确凿证据，修改为 --auth-key
tailscale up --auth-key="${TAILSCALE_AUTHKEY}" --accept-routes=true --ssh=true --ephemeral >> /tmp/komari.log 2>&1 &
sleep 5

# ==========================================
# 4. 纯净版 Komari v2 配置文件连接逻辑
# ==========================================
RN_INNER_IP="100.91.38.95"
KOMARI_PORT="25774"

if [ -n "${KOMARI_TOKEN}" ]; then
    echo "Creating v2 config file..." >> /tmp/komari.log
    cat <<EOF > /tmp/komari_config.yaml
server: "${RN_INNER_IP}:${KOMARI_PORT}"
client_secret: "${KOMARI_TOKEN}"
tls: false
debug: false
EOF

    echo "Starting Komari Agent v2 with config file..." >> /tmp/komari.log
    nohup /usr/local/bin/komari-agent -c /tmp/komari_config.yaml >> /tmp/komari.log 2>&1 &
else
    echo "Warning: KOMARI_TOKEN is not set." >> /tmp/komari.log
fi

# ==========================================
# 5. 终极守护：前台实时跟踪整个大日志
# ==========================================
tail -f /tmp/komari.log
