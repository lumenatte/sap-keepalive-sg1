#!/bin/bash

# 1. 启动 Tailscale 核心守护进程（保持你现有的用户态网络和代理配置）
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &
sleep 2

# 2. 🔥 重点：加上 --ephemeral 参数登录 Tailscale
# 这样每次 SAP 机器因为保活重启变动 IP 时，Tailscale 后台会自动擦除旧节点，不会留下僵尸主机
tailscale up --authkey="${TAILSCALE_AUTHKEY}" --accept-routes=true --ssh=true --ephemeral &
sleep 2

# 3. 🔥 核心修改：让 Agent 直接连接 RackNerd 固定的内网 IP
# 💡 请把下面的 100.xx.xx.xx 替换为你刚刚记录的 RackNerd 的 Tailscale 内网 IP
RN_INNER_IP="100.91.38.95"
KOMARI_PORT="25774"

if [ -n "${KOMARI_TOKEN}" ]; then
    echo "Starting Komari Agent via Tailscale tunnel..."
    # 顺着内网 IP 跨越隧道连接，并使用 nohup 挂在后台
    nohup komari-agent -e "${RN_INNER_IP}:${KOMARI_PORT}" -t "${KOMARI_TOKEN}" --protocol-version 1 > /tmp/komari.log 2>&1 &
else
    echo "Warning: KOMARI_TOKEN is not set."
fi

# 4. 保持容器前台运行
echo "Container fully initialized with secure tunnel."
tail -f /tmp/komari.log /dev/null
