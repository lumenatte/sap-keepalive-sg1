#!/bin/bash

# 1. 刷新日志文件
echo "=== Container Started at $(date) ===" > /tmp/komari.log

# ==========================================
# 2. 下载并部署真正的 Komari-Agent
# ==========================================
if [ ! -f "/usr/local/bin/komari-agent" ]; then
    echo "Fetching the official Komari-Agent binary..." >> /tmp/komari.log
    
    # 下载压缩包
    curl -L "https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent_linux_amd64.tar.gz" -o /tmp/komari.tar.gz
    
    # 【优化】解压到临时目录
    mkdir -p /tmp/komari_unpack
    tar -zxvf /tmp/komari.tar.gz -C /tmp/komari_unpack
    
    # 【关键修复】模糊匹配解压出来的可执行文件，确保一定能移过去并重命名为 komari-agent
    TARGET_BIN=$(find /tmp/komari_unpack -type f -name "*komari-agent*" | head -n 1)
    if [ -n "${TARGET_BIN}" ]; then
        mv "${TARGET_BIN}" /usr/local/bin/komari-agent
        chmod +x /usr/local/bin/komari-agent
        echo "Official Komari-agent deployment completed." >> /tmp/komari.log
    else
        echo "ERROR: Failed to find komari-agent binary in the archive!" >> /tmp/komari.log
    fi
    
    # 清理垃圾
    rm -rf /tmp/komari.tar.gz /tmp/komari_unpack
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

    # 检查文件是否确实存在，存在才启动
    if [ -f "/usr/local/bin/komari-agent" ]; then
        echo "Starting Komari Agent v2 via Public Domain..." >> /tmp/komari.log
        
        # 启动真正的 Komari 客户端
        nohup /usr/local/bin/komari-agent -c /tmp/komari_config.yaml >> /tmp/komari.log 2>&1 &
        
        AGENT_PID=$!
        echo "Agent started with PID: ${AGENT_PID}" >> /tmp/komari.log
        
        # 前台阻塞监视循环
        while kill -0 ${AGENT_PID} 2>/dev/null; do
            sleep 30
        done
        echo "Agent process ${AGENT_PID} exited. Entrypoint entering backup block to prevent crash..." >> /tmp/komari.log
    else
        echo "ERROR: /usr/local/bin/komari-agent does not exist. Cannot start agent." >> /tmp/komari.log
    fi
    
    # 【关键防崩保护】如果程序意外退出或没启动成功，用此命令死循环卡住主线程，允许你 cf ssh 进来调试，而不是直接容器崩溃
    exec tail -f /dev/null
    
else
    echo "Warning: KOMARI_TOKEN is not set." >> /tmp/komari.log
    exec tail -f /dev/null
fi
