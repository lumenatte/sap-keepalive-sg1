#!/bin/bash
set -u

LOG=/tmp/komari.log
echo "=== Container Started at $(date) ===" > "$LOG"

AGENT_BIN="/usr/local/bin/komari-agent"
SERVER_DOMAIN="nezha.eluke.dpdns.org"
KOMARI_PORT="25774"

if [ -z "${KOMARI_TOKEN:-}" ]; then
    echo "Warning: KOMARI_TOKEN is not set." >> "$LOG"
    exec tail -f /dev/null
fi

trap 'echo "[$(date)] Caught TERM, shutting down..." >> "'"$LOG"'"; kill -9 0' TERM

run_agent_forever() {
    while true; do
        echo "[$(date)] Starting komari-agent..." >> "$LOG"
        "$AGENT_BIN" -e "http://${SERVER_DOMAIN}:${KOMARI_PORT}" -t "${KOMARI_TOKEN}" >> "$LOG" 2>&1
        EXIT_CODE=$?
        echo "[$(date)] komari-agent exited (code ${EXIT_CODE}), restarting in 5s..." >> "$LOG"
        sleep 5
    done
}

run_agent_forever &
AGENT_LOOP_PID=$!
echo "Agent supervisor loop started, PID: ${AGENT_LOOP_PID}" >> "$LOG"

wait ${AGENT_LOOP_PID}
