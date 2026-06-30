#!/bin/bash

# 1. 刷新日志文件
echo "=== Container Started at $(date) ===" > /tmp/komari.log

# ==========================================
# 2. 动态下载真正的 Komari-Agent
# ==========================================
if [ ! -f "/usr/local/bin/komari-agent" ]; then
    echo "Fetching the correct Komari-Agent binary..." >> /tmp/komari.log
    curl -L "https://github.com/lumenatte/sap-keepalive/releases/download/v2/komari-agent" -o /usr/local/bin/komari-agent
    chmod +x /usr/local/bin/komari-agent
    echo "Komari-agent deployment completed." >> /tmp/komari.log
fi

# ==========================================
# 3. 纯净版 Komari v2 公网直连逻辑（前台守护模式）
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
    # --- 核心修改 ---
    # 不要用 exec。把进程推到后台，但我们要监视它。
    nohup /usr/local/bin/komari-agent -c /tmp/komari_config.yaml >> /tmp/komari.log 2>&1 &
    
    # 获取进程 ID
    AGENT_PID=$!
    echo "Agent started with PID: ${AGENT_PID}" >> /tmp/komari.log
    
    # 🧱 创建一个前台阻塞循环，监视 Agent 进程，防止容器退出
    # 如果 Agent 死掉，脚本也结束，触发 BTP 重启它
    while kill -0 ${AGENT_PID} 2>/dev/null; do
        sleep 30
    done
    echo "Agent process ${AGENT_PID} exited. Entrypoint finishing..." >> /tmp/komari.log
    
else
    echo "Warning: KOMARI_TOKEN is not set." >> /tmp/komari.log
    # 如果没变量，留一个前台进程死循环防止容器退出
    exec tail -f /dev/null
fi
