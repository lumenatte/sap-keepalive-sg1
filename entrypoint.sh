#!/bin/bash

# 1. 刷新日志文件
echo "=== Container Started at $(date) ===" > /tmp/komari.log

# ==========================================
# 2. 动态下载真正的 Komari-Agent（对齐 Komari 服务端）
# ==========================================
if [ ! -f "/usr/local/bin/komari-agent" ]; then
    echo "Fetching the correct Komari-Agent binary..." >> /tmp/komari.log
    # 彻底抛弃哪吒官方包，改用你原汁原味的 Komari 专用客户端
    curl -L "https://github.com/lumenatte/sap-keepalive/releases/download/v2/komari-agent" -o /usr/local/bin/komari-agent
    chmod +x /usr/local/bin/komari-agent
    echo "Komari-agent deployment completed." >> /tmp/komari.log
fi

# ==========================================
# 3. 纯净版 Komari v2 公网直连逻辑
# ==========================================
SERVER_DOMAIN="nezha.eluke.dpdns.org"
KOMARI_PORT="25774"

if [ -n "${KOMARI_TOKEN}" ]; then
    echo "Creating v2 config file..." >> /tmp/komari.log
    cat <<EOF > /tmp/komari_config.yaml
server: "${SERVER_DOMAIN}:${KOMARI_PORT}"
client_secret: "${KOMARI_TOKEN}"
tls: false
debug: false
EOF

    echo "Starting Komari Agent v2 with config file via Public Domain..." >> /tmp/komari.log
    # 使用 exec 让正确的二进制接管主进程，直接走公网
    exec /usr/local/bin/komari-agent -c /tmp/komari_config.yaml >> /tmp/komari.log 2>&1
else
    echo "Warning: KOMARI_TOKEN is not set." >> /tmp/komari.log
    tail -f /dev/null
fi
