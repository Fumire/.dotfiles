#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Check memory idle percentage and alert when thresholds are exceeded.
set -euo pipefail
IFS=$'\n\t'

readonly DEFAULT_HEAVY_TASK_LIMIT=5
readonly DEFAULT_IDLE_WARNING_THRESHOLD=15
readonly DEFAULT_IDLE_ERROR_THRESHOLD=10
readonly DEFAULT_ALERT_RECIPIENT="root@compbio.unist.ac.kr"

HEAVY_TASK_LIMIT=${HEAVY_TASK_LIMIT:-$DEFAULT_HEAVY_TASK_LIMIT}
IDLE_WARNING_THRESHOLD=${IDLE_WARNING_THRESHOLD:-$DEFAULT_IDLE_WARNING_THRESHOLD}
IDLE_ERROR_THRESHOLD=${IDLE_ERROR_THRESHOLD:-$DEFAULT_IDLE_ERROR_THRESHOLD}
ALERT_RECIPIENT=${ALERT_RECIPIENT:-${CHECK_SYSTEM_ALERT_RECIPIENT:-$DEFAULT_ALERT_RECIPIENT}}

require_positive_integer() {
    local option=$1
    local value=$2

    if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
        echo "${option} must be a positive integer" >&2
        exit 1
    fi
}

require_percent() {
    local option=$1
    local value=$2

    if [[ ! "$value" =~ ^(0|[1-9][0-9]*)$ ]] || (( value > 100 )); then
        echo "${option} must be an integer from 0 to 100" >&2
        exit 1
    fi
}

require_positive_integer "HEAVY_TASK_LIMIT" "$HEAVY_TASK_LIMIT"
require_percent "IDLE_WARNING_THRESHOLD" "$IDLE_WARNING_THRESHOLD"
require_percent "IDLE_ERROR_THRESHOLD" "$IDLE_ERROR_THRESHOLD"

if (( IDLE_ERROR_THRESHOLD >= IDLE_WARNING_THRESHOLD )); then
    echo "IDLE_ERROR_THRESHOLD must be lower than IDLE_WARNING_THRESHOLD" >&2
    exit 1
fi

report_heaviest_processes() {
    local sort_column=$1
    local title=$2

    printf '%s\n' "$title"
    printf 'Generated at: %s on %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$(hostname)"
    printf '%-8s %-24s %-16s %-8s %8s %10s %8s\n' "PID" "PROCESS" "USER" "UID" "CPU%" "MEM_GB" "MEM%"
    ps -eo pid=,comm=,user=,uid=,pcpu=,rss=,pmem= --sort="$sort_column" |
        head -n "$HEAVY_TASK_LIMIT" |
        awk '{
            printf "%-8s %-24.24s %-16.16s %-8s %8s %10.2f %8s\n", $1, $2, $3, $4, $5, $6 / 1048576, $7
        }'
}

TOTAL_MEM=$(free | grep "^Mem" | awk '{print $2}')
if free | grep -q "available"; then
    ACTUAL_MEM=$(free | grep "^Mem" | awk '{print $7}')
else
    ACTUAL_MEM=$(free | grep "^-/+" | awk '{print $4}')
fi
IDLE_MEM=$(echo "$ACTUAL_MEM * 100 / $TOTAL_MEM" | bc)

if (( IDLE_MEM < IDLE_ERROR_THRESHOLD )); then
    report_heaviest_processes "-rss" "Top ${HEAVY_TASK_LIMIT} processes by memory usage" | mail -s "[Error] MEM Usage is too high in $(hostname)" "$ALERT_RECIPIENT"
    echo "MEM Error:" "${IDLE_MEM}"
elif (( IDLE_MEM < IDLE_WARNING_THRESHOLD )); then
    report_heaviest_processes "-rss" "Top ${HEAVY_TASK_LIMIT} processes by memory usage" | mail -s "[Warning] MEM Usage is too high in $(hostname)" "$ALERT_RECIPIENT"
    echo "MEM Warning:" "${IDLE_MEM}"
else
    echo "MEM is Okay:" "${IDLE_MEM}"
fi
