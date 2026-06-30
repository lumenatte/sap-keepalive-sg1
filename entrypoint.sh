#!/bin/bash

# 1. 刷新日志文件
echo "=== Container Started at $(date) ===" > /tmp/komari.log

# ==========================================
# 2. 借用官方一键部署脚本的源，动态下载真正的 Komari-Agent
# ==========================================
if [ ! -f "/usr/local/bin/komari-agent" ]; then
    echo "Fetching the official Komari-Agent binary..." >> /tmp/komari.log
    
    # 1. 直接从官方一键部署的源里下载最新版的独立二进制压缩包
    curl -L "https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent_linux_amd64.tar.gz" -o /tmp/komari.tar.gz
    
    # 2. 解压并移到对应位置
    tar -zxvf /tmp/komari.tar.gz -C /tmp/
    mv /tmp/komari-agent /usr/local/bin/komari-agent
    
    chmod +x /usr/local/bin/komari-agent
    rm -f /tmp/komari.tar.gz
    echo "Official Komari-agent deployment completed." >> /tmp/komari.log
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
