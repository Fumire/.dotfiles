#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Check CPU usage from idle percentage and alert when thresholds are exceeded.
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

IDLE_CPU=$(top -b -n 1 | grep "\%Cpu(s)" | awk -F ',' '{ print $4}' | awk '{ print $1}' | cut -d "." -f 1)

if (( IDLE_CPU < IDLE_ERROR_THRESHOLD )); then
    report_heaviest_processes "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage" | mail -s "[Error] CPU Usage is too high in $(hostname)" "$ALERT_RECIPIENT"
    echo "CPU Error:" "$IDLE_CPU"
elif (( IDLE_CPU < IDLE_WARNING_THRESHOLD )); then
    report_heaviest_processes "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage" | mail -s "[Warning] CPU Usage is too high in $(hostname)" "$ALERT_RECIPIENT"
    echo "CPU Warning:" "$IDLE_CPU"
else
    echo "CPU is Okay:" "$IDLE_CPU"
fi
