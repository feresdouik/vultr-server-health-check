#!/usr/bin/env bash

set -uo pipefail

# Configuration
DISK_THRESHOLD=80
SERVICES=("ssh.service" "cron.service")

SERVER_NAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PROBLEMS=0

log() {
    printf '%s %-7s %s\n' "$TIMESTAMP" "$1" "$2"
}

log INFO "Health check started on $SERVER_NAME"

# Disk usage
DISK_USAGE=$(df --output=pcent / | tail -n 1 | tr -dc '0-9')

if (( DISK_USAGE > DISK_THRESHOLD )); then
    log WARNING "Disk usage is ${DISK_USAGE}% (threshold: ${DISK_THRESHOLD}%)"
    PROBLEMS=$((PROBLEMS + 1))
else
    log OK "Disk usage: ${DISK_USAGE}%"
fi

# Memory usage
MEMORY_USAGE=$(free | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')
log INFO "Memory usage: ${MEMORY_USAGE}%"

# Load average
LOAD_AVERAGE=$(awk '{print $1, $2, $3}' /proc/loadavg)
log INFO "Load average (1m, 5m, 15m): $LOAD_AVERAGE"

# Uptime
UPTIME=$(uptime -p)
log INFO "System uptime: $UPTIME"

# Service checks
for SERVICE in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$SERVICE"; then
        log OK "Service $SERVICE is active"
    else
        log WARNING "Service $SERVICE is not active"
        PROBLEMS=$((PROBLEMS + 1))
    fi
done

# Final result
if (( PROBLEMS > 0 )); then
    log FAIL "$PROBLEMS problem(s) detected"
    exit 1
fi

log INFO "All health checks passed"
exit 0
