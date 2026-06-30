#!/bin/bash

# 1. 刷新日志文件
echo "=== Container Started at $(date) ===" > /tmp/komari.log

# ==========================================
# 2. 彻底放弃外部下载，直接检查并确认本地 Komari 客户端
# ==========================================
if [ -f "/usr/local/bin/komari-agent" ]; then
    echo "Using pre-installed local Komari-Agent binary." >> /tmp/komari.log
else
    # 预防万一，如果在这个路径没找到，去常见的全局路径找一下
    echo "Checking alternative paths..." >> /tmp/komari.log
    if command -v komari-agent &> /dev/null; then
        cp $(command -v komari-agent) /usr/local/bin/komari-agent
        echo "Found komari-agent in system PATH." >> /tmp/komari.log
    else
        echo "ERROR: komari-agent not found in this image!" >> /tmp/komari.log
        tail -f /dev/null
    fi
fi

# ==========================================
# 3. Komari v2 公网直连逻辑（本地进程守护模式）
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
    
    # 启动本地真正的 Komari 客户端
    nohup /usr/local/bin/komari-agent -c /tmp/komari_config.yaml >> /tmp/komari.log 2>&1 &
    
    AGENT_PID=$!
    echo "Agent started with PID: ${AGENT_PID}" >> /tmp/komari.log
    
    # 前台阻塞监视循环，防止 BTP 容器因为脚本退出而报 127 错误
    while kill -0 ${AGENT_PID} 2>/dev/null; do
        sleep 30
    done
    echo "Agent process ${AGENT_PID} exited. Entrypoint finishing..." >> /tmp/komari.log
    
else
    echo "Warning: KOMARI_TOKEN is not set." >> /tmp/komari.log
    exec tail -f /dev/null
fi
