#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Check system temperature and alert when thresholds are exceeded.
set -euo pipefail
IFS=$'\n\t'

readonly DEFAULT_HEAVY_TASK_LIMIT=5
readonly DEFAULT_TEMPERATURE_WARNING_THRESHOLD=80
readonly DEFAULT_TEMPERATURE_ERROR_THRESHOLD=90
readonly DEFAULT_ALERT_RECIPIENT="root@compbio.unist.ac.kr"

HEAVY_TASK_LIMIT=${HEAVY_TASK_LIMIT:-$DEFAULT_HEAVY_TASK_LIMIT}
TEMPERATURE_WARNING_THRESHOLD=${TEMPERATURE_WARNING_THRESHOLD:-$DEFAULT_TEMPERATURE_WARNING_THRESHOLD}
TEMPERATURE_ERROR_THRESHOLD=${TEMPERATURE_ERROR_THRESHOLD:-$DEFAULT_TEMPERATURE_ERROR_THRESHOLD}
ALERT_RECIPIENT=${ALERT_RECIPIENT:-${CHECK_SYSTEM_ALERT_RECIPIENT:-$DEFAULT_ALERT_RECIPIENT}}

require_positive_integer() {
    local option=$1
    local value=$2

    if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
        echo "${option} must be a positive integer" >&2
        exit 1
    fi
}

require_non_negative_integer() {
    local option=$1
    local value=$2

    if [[ ! "$value" =~ ^(0|[1-9][0-9]*)$ ]]; then
        echo "${option} must be a non-negative integer" >&2
        exit 1
    fi
}

require_positive_integer "HEAVY_TASK_LIMIT" "$HEAVY_TASK_LIMIT"
require_non_negative_integer "TEMPERATURE_WARNING_THRESHOLD" "$TEMPERATURE_WARNING_THRESHOLD"
require_non_negative_integer "TEMPERATURE_ERROR_THRESHOLD" "$TEMPERATURE_ERROR_THRESHOLD"

if (( TEMPERATURE_ERROR_THRESHOLD <= TEMPERATURE_WARNING_THRESHOLD )); then
    echo "TEMPERATURE_ERROR_THRESHOLD must be higher than TEMPERATURE_WARNING_THRESHOLD" >&2
    exit 1
fi

trim_field() {
    local value=$1

    value=${value#"${value%%[![:space:]]*}"}
    value=${value%"${value##*[![:space:]]}"}
    printf '%s' "$value"
}

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

read_temperature_celsius() {
    local temp_file
    local raw_temp
    local nullglob_enabled=0

    if shopt -q nullglob; then
        nullglob_enabled=1
    fi
    shopt -s nullglob

    for temp_file in /sys/class/thermal/thermal_zone*/temp; do
        [[ -r "$temp_file" ]] || continue

        if ! raw_temp=$(<"$temp_file"); then
            continue
        fi

        raw_temp=$(trim_field "$raw_temp")
        if [[ "$raw_temp" =~ ^[0-9]+$ ]]; then
            if (( nullglob_enabled == 0 )); then
                shopt -u nullglob
            fi
            echo "$raw_temp / 1000" | bc -l | xargs printf "%1.0f"
            return 0
        fi
    done

    if (( nullglob_enabled == 0 )); then
        shopt -u nullglob
    fi
    return 1
}

if TEMPERATURE=$(read_temperature_celsius); then
    if (( TEMPERATURE > TEMPERATURE_ERROR_THRESHOLD )); then
        {
            printf 'TEMPERATURE Error: %s\n\n' "$TEMPERATURE"
            report_heaviest_processes "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage"
        } | mail -s "[Error] TEMPERATURE is too high in $(hostname)" "$ALERT_RECIPIENT"
        echo "TEMPERATURE Error" "${TEMPERATURE}"
    elif (( TEMPERATURE > TEMPERATURE_WARNING_THRESHOLD && TEMPERATURE <= TEMPERATURE_ERROR_THRESHOLD )); then
        {
            printf 'TEMPERATURE Warning: %s\n\n' "$TEMPERATURE"
            report_heaviest_processes "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage"
        } | mail -s "[Warning] TEMPERATURE is too high in $(hostname)" "$ALERT_RECIPIENT"
        echo "TEMPERATURE Warning" "${TEMPERATURE}"
    else
        echo "TEMPERATURE is Okay" "${TEMPERATURE}"
    fi
else
    echo "TEMPERATURE check skipped: no readable thermal zone temperature file"
fi
