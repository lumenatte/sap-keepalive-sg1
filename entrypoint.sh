#!/bin/bash
set -u

LOG=/tmp/komari.log
echo "=== Container Started at $(date) ===" > "$LOG"

AGENT_BIN="/usr/local/bin/komari-agent"
SERVER_DOMAIN="nezha.eluke.dpdns.org"
KOMARI_PORT="25774"

# ==========================================
# 下载函数：带超时 + 重试，避免 SAP BTP 出口慢时一次失败就放弃
# ==========================================
download_agent() {
    local max_retries=10
    local attempt=1
    while [ $attempt -le $max_retries ]; do
        echo "[$(date)] Downloading komari-agent, attempt ${attempt}/${max_retries}..." >> "$LOG"
        # --max-time 1800: 单次最多等30分钟，不会因为你说的"半小时下载"被误判失败
        curl -L --connect-timeout 30 --max-time 1800 \
             "https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-amd64" \
             -o /tmp/komari-agent 2>> "$LOG"

        if [ -s /tmp/komari-agent ]; then
            mv /tmp/komari-agent "$AGENT_BIN"
            chmod +x "$AGENT_BIN"
            echo "[$(date)] Download succeeded." >> "$LOG"
            return 0
        fi

        echo "[$(date)] Attempt ${attempt} failed, retrying in 10s..." >> "$LOG"
        attempt=$((attempt + 1))
        sleep 10
    done
    return 1
}

if [ ! -x "$AGENT_BIN" ]; then
    download_agent || echo "[$(date)] ERROR: all download attempts failed." >> "$LOG"
fi

if [ -z "${KOMARI_TOKEN:-}" ]; then
    echo "Warning: KOMARI_TOKEN is not set." >> "$LOG"
    exec tail -f /dev/null
fi

# ==========================================
# 收到 TERM 信号（容器被回收/重建）时，杀掉所有子进程再退出
# ==========================================
trap 'echo "[$(date)] Caught TERM, shutting down..." >> "'"$LOG"'"; kill -9 0' TERM

# ==========================================
# 守护循环：komari-agent 无论因为什么原因退出，都会自动重启
# 这就是你要的"每次保活后都能看到 komari-agent"的效果
# ==========================================
run_agent_forever() {
    while true; do
        if [ ! -x "$AGENT_BIN" ]; then
            echo "[$(date)] Binary missing, re-downloading..." >> "$LOG"
            download_agent
        fi

        echo "[$(date)] Starting komari-agent..." >> "$LOG"
        "$AGENT_BIN" -e "http://${SERVER_DOMAIN}:${KOMARI_PORT}" -t "${KOMARI_TOKEN}" >> "$LOG" 2>&1
        # 💡 若服务端开了 TLS/SSL，把上面 http:// 改成 https://

        EXIT_CODE=$?
        echo "[$(date)] komari-agent exited (code ${EXIT_CODE}), restarting in 5s..." >> "$LOG"
        sleep 5
    done
}

run_agent_forever &
AGENT_LOOP_PID=$!
echo "Agent supervisor loop started, PID: ${AGENT_LOOP_PID}" >> "$LOG"

wait ${AGENT_LOOP_PID}
