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
# 3. 绕过 BTP 容器封锁：强行限制纯 IPv4 并在登录前强制初始化
# ==========================================
echo "Starting tailscaled in strict user-space IPv4 mode..." >> /tmp/komari.log

# 环境变量强行告诉 Tailscale 别去碰没有权限的内核功能
export TS_DEBUG_DISABLE_IPV6=1

tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 >> /tmp/komari.log 2>&1 &
sleep 5

echo "Cleaning stale tailscale state..." >> /tmp/komari.log
# 🧱 核心：不管之前有没有残留，先强行执行一次本地断开和状态清理，确保是张白纸
tailscale logout >> /tmp/komari.log 2>&1
tailscale down >> /tmp/komari.log 2>&1

echo "Bringing tailscale up synchronously with re-auth flag..." >> /tmp/komari.log

# 🔥 核心修正：带上 --force-reauth 标签，强行注销掉任何导致它抛出帮助信息的“残留设备锁”
tailscale up --auth-key="${TAILSCALE_AUTHKEY}" --accept-routes=true --ephemeral --force-reauth --timeout=30s >> /tmp/komari.log 2>&1

# 打印状态看看通没通
tailscale status >> /tmp/komari.log 2>&1

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
# 5. 前台日志实时跟踪
# ==========================================
tail -f /tmp/komari.log
