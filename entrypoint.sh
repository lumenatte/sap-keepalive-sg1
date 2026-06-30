#!/bin/bash

# 1. 刷新日志文件
echo "=== Container Started at $(date) ===" > /tmp/komari.log

# ==========================================
# 2. 直接下载真正的 Komari-Agent 纯二进制文件
# ==========================================
if [ ! -f "/usr/local/bin/komari-agent" ]; then
    echo "Fetching the official Komari-Agent binary..." >> /tmp/komari.log
    
    # 【修复】改用官方正确的 GitHub Release 裸文件下载链接
    curl -L "https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-amd64" -o /tmp/komari-agent
    
    # 检查是否下载成功（避免下到 404 网页）
    if [ -s "/tmp/komari-agent" ]; then
        mv /tmp/komari-agent /usr/local/bin/komari-agent
        chmod +x /usr/local/bin/komari-agent
        echo "Official Komari-agent deployment completed." >> /tmp/komari.log
    else
        echo "ERROR: Failed to download komari-agent from GitHub!" >> /tmp/komari.log
    fi
fi

# ==========================================
# 3. Komari v2 公网直连逻辑（改为纯参数启动模式）
# ==========================================
SERVER_DOMAIN="nezha.eluke.dpdns.org"
KOMARI_PORT="25774"

if [ -n "${KOMARI_TOKEN}" ]; then
    # 检查文件是否确实存在
    if [ -f "/usr/local/bin/komari-agent" ]; then
        echo "Starting Komari Agent v2 via Command Line Flags..." >> /tmp/komari.log
        
        # 【核心修改】不用 -c，改用 -e 指定服务器，-t 指定 Token 启动
        nohup /usr/local/bin/komari-agent -e "http://${SERVER_DOMAIN}:${KOMARI_PORT}" -t "${KOMARI_TOKEN}" >> /tmp/komari.log 2>&1 &
        
        # 💡 注：如果服务端开了 TLS/SSL，请把上面的 http:// 改为 https://
        
        AGENT_PID=$!
        echo "Agent started with PID: ${AGENT_PID}" >> /tmp/komari.log
        
        # 前台阻塞监视循环
        while kill -0 ${AGENT_PID} 2>/dev/null; do
            sleep 30
        done
        echo "Agent process ${AGENT_PID} exited. Entrypoint entering backup block to prevent crash..." >> /tmp/komari.log
    else
        echo "ERROR: /usr/local/bin/komari-agent does not exist." >> /tmp/komari.log
    fi
    
    # 防崩保护
    exec tail -f /dev/null
else
    echo "Warning: KOMARI_TOKEN is not set." >> /tmp/komari.log
    exec tail -f /dev/null
fi
