#!/bin/bash

# ==========================================
# 1. 基础环境配置与下载 Komari-Agent
# ==========================================
echo "Starting initialization..." > /tmp/komari.log
cd /tmp

if [ ! -f "/usr/local/bin/komari-agent" ]; then
    echo "Fetching komari-agent binary..." >> /tmp/komari.log
    curl -L "https://github.com/lumenatte/sap-keepalive/releases/download/v2/komari-agent" -o /usr/local/bin/komari-agent
    chmod +x /usr/local/bin/komari-agent
fi

# ==========================================
# 2. 纯净版 Komari 公网直连逻辑（不要 Tailscale）
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

    echo "Starting Komari Agent v2 via Public Domain..." >> /tmp/komari.log
    # 使用 exec 接管进程，防止沙盒认为主进程退出而闪退
    exec /usr/local/bin/komari-agent -c /tmp/komari_config.yaml >> /tmp/komari.log 2>&1
else
    echo "Warning: KOMARI_TOKEN is not set." >> /tmp/komari.log
fi
