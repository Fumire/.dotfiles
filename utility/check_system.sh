#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Monitor CPU, memory, optional temperature, and optional NVIDIA GPU usage,
#   then email threshold alerts with the heaviest related processes.
# Usage:
#   utility/check_system.sh [OPTIONS]
# Notes:
#   CPU/memory/temperature checks are delegated to dedicated scripts.
#   Temperature and GPU checks are skipped when the host lacks readable sensor
#   data or a usable NVIDIA driver.
set -euo pipefail
IFS=$'\n\t'

readonly DEFAULT_HEAVY_TASK_LIMIT=5
readonly DEFAULT_IDLE_WARNING_THRESHOLD=15
readonly DEFAULT_IDLE_ERROR_THRESHOLD=10
readonly DEFAULT_TEMPERATURE_WARNING_THRESHOLD=70
readonly DEFAULT_TEMPERATURE_ERROR_THRESHOLD=80
readonly DEFAULT_GPU_WARNING_THRESHOLD=85
readonly DEFAULT_GPU_ERROR_THRESHOLD=90
readonly DEFAULT_ALERT_RECIPIENT="root@compbio.unist.ac.kr"

HEAVY_TASK_LIMIT=$DEFAULT_HEAVY_TASK_LIMIT
IDLE_WARNING_THRESHOLD=$DEFAULT_IDLE_WARNING_THRESHOLD
IDLE_ERROR_THRESHOLD=$DEFAULT_IDLE_ERROR_THRESHOLD
TEMPERATURE_WARNING_THRESHOLD=$DEFAULT_TEMPERATURE_WARNING_THRESHOLD
TEMPERATURE_ERROR_THRESHOLD=$DEFAULT_TEMPERATURE_ERROR_THRESHOLD
GPU_WARNING_THRESHOLD=$DEFAULT_GPU_WARNING_THRESHOLD
GPU_ERROR_THRESHOLD=$DEFAULT_GPU_ERROR_THRESHOLD
ALERT_RECIPIENT=${CHECK_SYSTEM_ALERT_RECIPIENT:-$DEFAULT_ALERT_RECIPIENT}

show_help() {
    cat <<EOF
Usage:
  utility/check_system.sh [OPTIONS]

Monitor CPU, memory, optional temperature, and optional NVIDIA GPU usage, then
email threshold alerts with the heaviest related processes.

Options:
  --heavy-task-limit N              Number of heavy processes to include; default: ${DEFAULT_HEAVY_TASK_LIMIT}
  --idle-warning-threshold PERCENT  CPU/MEM idle percent below which warning alerts start; default: ${DEFAULT_IDLE_WARNING_THRESHOLD}
  --idle-error-threshold PERCENT    CPU/MEM idle percent below which error alerts start; default: ${DEFAULT_IDLE_ERROR_THRESHOLD}
  --temperature-warning-threshold C Temperature above which warning alerts start; default: ${DEFAULT_TEMPERATURE_WARNING_THRESHOLD}
  --temperature-error-threshold C   Temperature above which error alerts start; default: ${DEFAULT_TEMPERATURE_ERROR_THRESHOLD}
  --gpu-warning-threshold PERCENT   GPU memory/utilization percent above which warnings start; default: ${DEFAULT_GPU_WARNING_THRESHOLD}
  --gpu-error-threshold PERCENT     GPU memory/utilization percent above which errors start; default: ${DEFAULT_GPU_ERROR_THRESHOLD}
  --alert-recipient ADDRESS         Email recipient for alerts; default: ${DEFAULT_ALERT_RECIPIENT}
  -h, --help                        Show this help message

Environment:
  CHECK_SYSTEM_ALERT_RECIPIENT      Default alert recipient when --alert-recipient is not set
EOF
}

require_value() {
    local option=$1
    local value=${2:-}

    if [[ -z "$value" ]]; then
        echo "${option} requires a value" >&2
        show_help >&2
        exit 1
    fi
}

require_positive_integer() {
    local option=$1
    local value=$2

    if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
        echo "${option} must be a positive integer" >&2
        show_help >&2
        exit 1
    fi
}

require_percent() {
    local option=$1
    local value=$2

    if [[ ! "$value" =~ ^(0|[1-9][0-9]*)$ ]] || (( value > 100 )); then
        echo "${option} must be an integer from 0 to 100" >&2
        show_help >&2
        exit 1
    fi
}

require_non_negative_integer() {
    local option=$1
    local value=$2

    if [[ ! "$value" =~ ^(0|[1-9][0-9]*)$ ]]; then
        echo "${option} must be a non-negative integer" >&2
        show_help >&2
        exit 1
    fi
}

while (($# > 0)); do
    case "$1" in
        --heavy-task-limit)
            require_value "$1" "${2:-}"
            HEAVY_TASK_LIMIT=$2
            shift 2
            ;;
        --idle-warning-threshold)
            require_value "$1" "${2:-}"
            IDLE_WARNING_THRESHOLD=$2
            shift 2
            ;;
        --idle-error-threshold)
            require_value "$1" "${2:-}"
            IDLE_ERROR_THRESHOLD=$2
            shift 2
            ;;
        --temperature-warning-threshold)
            require_value "$1" "${2:-}"
            TEMPERATURE_WARNING_THRESHOLD=$2
            shift 2
            ;;
        --temperature-error-threshold)
            require_value "$1" "${2:-}"
            TEMPERATURE_ERROR_THRESHOLD=$2
            shift 2
            ;;
        --gpu-warning-threshold)
            require_value "$1" "${2:-}"
            GPU_WARNING_THRESHOLD=$2
            shift 2
            ;;
        --gpu-error-threshold)
            require_value "$1" "${2:-}"
            GPU_ERROR_THRESHOLD=$2
            shift 2
            ;;
        --alert-recipient)
            require_value "$1" "${2:-}"
            ALERT_RECIPIENT=$2
            shift 2
            ;;
        -h | --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

require_positive_integer "--heavy-task-limit" "$HEAVY_TASK_LIMIT"
require_percent "--idle-warning-threshold" "$IDLE_WARNING_THRESHOLD"
require_percent "--idle-error-threshold" "$IDLE_ERROR_THRESHOLD"
require_non_negative_integer "--temperature-warning-threshold" "$TEMPERATURE_WARNING_THRESHOLD"
require_non_negative_integer "--temperature-error-threshold" "$TEMPERATURE_ERROR_THRESHOLD"
require_percent "--gpu-warning-threshold" "$GPU_WARNING_THRESHOLD"
require_percent "--gpu-error-threshold" "$GPU_ERROR_THRESHOLD"

if (( IDLE_ERROR_THRESHOLD >= IDLE_WARNING_THRESHOLD )); then
    echo "--idle-error-threshold must be lower than --idle-warning-threshold" >&2
    show_help >&2
    exit 1
fi

if (( TEMPERATURE_ERROR_THRESHOLD <= TEMPERATURE_WARNING_THRESHOLD )); then
    echo "--temperature-error-threshold must be higher than --temperature-warning-threshold" >&2
    show_help >&2
    exit 1
fi

if (( GPU_ERROR_THRESHOLD <= GPU_WARNING_THRESHOLD )); then
    echo "--gpu-error-threshold must be higher than --gpu-warning-threshold" >&2
    show_help >&2
    exit 1
fi

trim_field() {
    local value=$1

    value=${value#"${value%%[![:space:]]*}"}
    value=${value%"${value##*[![:space:]]}"}
    printf '%s' "$value"
}

gpu_process_utilization() {
    local pid=$1
    local pmon_output=$2

    if [[ -z "$pmon_output" ]]; then
        printf 'N/A'
        return
    fi

    awk -v pid="$pid" '
        $1 !~ /^#/ && $2 == pid {
            print $4
            found = 1
            exit
        }
        END {
            if (!found) {
                print "N/A"
            }
        }
    ' <<< "$pmon_output"
}

process_identity() {
    local pid=$1
    local fallback_process=$2
    local identity

    if identity=$(ps -o user=,uid=,comm= -p "$pid" 2>/dev/null) && [[ -n "$identity" ]]; then
        awk -v fallback_process="$fallback_process" '{
            user = $1
            uid = $2
            process = $3
            if (process == "") {
                process = fallback_process
            }
            printf "%s\t%s\t%s\n", process, user, uid
        }' <<< "$identity"
    else
        printf '%s\t%s\t%s\n' "$fallback_process" "N/A" "N/A"
    fi
}

nvidia_driver_unavailable() {
    local status=$1

    [[ "$status" == *"couldn't communicate with the NVIDIA driver"* ]]
}

report_heaviest_gpu_tasks() {
    local gpu_processes
    local gpu_pmon_output
    local gpu_pid
    local gpu_process
    local gpu_mem_mib
    local gpu_util
    local process
    local user
    local uid

    printf 'Top %d GPU processes by memory usage\n' "$HEAVY_TASK_LIMIT"
    printf 'Generated at: %s on %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$(hostname)"

    if ! gpu_processes=$(nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader,nounits 2>&1); then
        printf 'nvidia-smi process query failed:\n%s\n' "$gpu_processes"
        return
    fi

    if [[ -z "$gpu_processes" ]]; then
        printf 'No active GPU compute processes reported.\n'
        return
    fi

    if ! gpu_pmon_output=$(nvidia-smi pmon -c 1 -s u 2>/dev/null); then
        gpu_pmon_output=""
    fi

    printf '%-8s %-24s %-16s %-8s %8s %14s\n' "PID" "PROCESS" "USER" "UID" "GPU%" "GPU_MEM_MiB"
    printf '%s\n' "$gpu_processes" | sort -t',' -k3,3nr | head -n "$HEAVY_TASK_LIMIT" |
        while IFS=',' read -r gpu_pid gpu_process gpu_mem_mib; do
            gpu_pid=$(trim_field "$gpu_pid")
            gpu_process=$(trim_field "$gpu_process")
            gpu_mem_mib=$(trim_field "$gpu_mem_mib")
            gpu_util=$(gpu_process_utilization "$gpu_pid" "$gpu_pmon_output")

            IFS=$'\t' read -r process user uid < <(process_identity "$gpu_pid" "$gpu_process")
            printf '%-8s %-24.24s %-16.16s %-8s %8s %14s\n' "$gpu_pid" "$process" "$user" "$uid" "$gpu_util" "$gpu_mem_mib"
        done
}

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HEAVY_TASK_LIMIT
export IDLE_WARNING_THRESHOLD
export IDLE_ERROR_THRESHOLD
export TEMPERATURE_WARNING_THRESHOLD
export TEMPERATURE_ERROR_THRESHOLD
export ALERT_RECIPIENT

"$SCRIPT_DIR/check_system_cpu.sh"
"$SCRIPT_DIR/check_system_memory.sh"
"$SCRIPT_DIR/check_system_temperature.sh"

if command -v nvidia-smi >/dev/null 2>&1; then
    if GPU_STATUS=$(nvidia-smi 2>&1); then
        GPU_ALERT_LEVEL=0
        GPU_REPORT=""
        GPU_QUERY_FAILED=0

        if ! GPU_QUERY=$(nvidia-smi --query-gpu=index,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits 2>&1); then
            GPU_QUERY_FAILED=1
        fi

        if (( GPU_QUERY_FAILED == 0 )); then
            while IFS=',' read -r GPU_INDEX GPU_MEM_USED GPU_MEM_TOTAL GPU_UTIL; do
                [[ -z "${GPU_INDEX:-}" ]] && continue

                GPU_INDEX=${GPU_INDEX//[[:space:]]/}
                GPU_MEM_USED=${GPU_MEM_USED//[[:space:]]/}
                GPU_MEM_TOTAL=${GPU_MEM_TOTAL//[[:space:]]/}
                GPU_UTIL=${GPU_UTIL//[[:space:]]/}

                if [[ ! "$GPU_MEM_USED" =~ ^[0-9]+$ || ! "$GPU_MEM_TOTAL" =~ ^[0-9]+$ || ! "$GPU_UTIL" =~ ^[0-9]+$ || "$GPU_MEM_TOTAL" -eq 0 ]]; then
                    GPU_REPORT+="GPU ${GPU_INDEX}: unable to parse status"$'\n'
                    GPU_ALERT_LEVEL=2
                    continue
                fi

                GPU_MEM_PERCENT_TENTHS=$((GPU_MEM_USED * 1000 / GPU_MEM_TOTAL))
                GPU_MEM_PERCENT=$(printf '%d.%d' "$((GPU_MEM_PERCENT_TENTHS / 10))" "$((GPU_MEM_PERCENT_TENTHS % 10))")
                GPU_REPORT+="GPU ${GPU_INDEX}: memory ${GPU_MEM_PERCENT}% (${GPU_MEM_USED} MiB / ${GPU_MEM_TOTAL} MiB), util ${GPU_UTIL}%"$'\n'

                if (( GPU_MEM_USED * 100 > GPU_MEM_TOTAL * GPU_ERROR_THRESHOLD || GPU_UTIL > GPU_ERROR_THRESHOLD )); then
                    GPU_ALERT_LEVEL=2
                elif (( GPU_ALERT_LEVEL < 1 )) && (( GPU_MEM_USED * 100 > GPU_MEM_TOTAL * GPU_WARNING_THRESHOLD || GPU_UTIL > GPU_WARNING_THRESHOLD )); then
                    GPU_ALERT_LEVEL=1
                fi
            done <<< "$GPU_QUERY"
        else
            GPU_REPORT+="nvidia-smi query failed:"$'\n'
            GPU_REPORT+="${GPU_QUERY}"$'\n'
            GPU_ALERT_LEVEL=2
        fi

        if (( GPU_ALERT_LEVEL == 2 )); then
            {
                printf '%s\n\n' "$GPU_REPORT"
                report_heaviest_gpu_tasks
            } | mail -s "[Error] GPU Usage is too high in $(hostname)" "$ALERT_RECIPIENT"
            echo "GPU Error:"
            printf '%s\n' "$GPU_REPORT"
        elif (( GPU_ALERT_LEVEL == 1 )); then
            {
                printf '%s\n\n' "$GPU_REPORT"
                report_heaviest_gpu_tasks
            } | mail -s "[Warning] GPU Usage is too high in $(hostname)" "$ALERT_RECIPIENT"
            echo "GPU Warning:"
            printf '%s\n' "$GPU_REPORT"
        else
            echo "GPU is Okay"
            printf '%s\n' "$GPU_REPORT"
        fi
    elif nvidia_driver_unavailable "$GPU_STATUS"; then
        :
    else
        printf '%s\n' "$GPU_STATUS" | mail -s "[Error] GPU status check failed in $(hostname)" "$ALERT_RECIPIENT"
        echo "GPU Error"
        printf '%s\n' "$GPU_STATUS"
    fi
fi

exit 0
