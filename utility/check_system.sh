#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Monitor CPU, memory, optional temperature, and optional NVIDIA GPU usage,
#   then email threshold alerts with the five heaviest related processes.
# Notes:
#   Temperature and GPU checks are skipped when the host lacks readable sensor
#   data or a usable NVIDIA driver.
set -euo pipefail
IFS=$'\n\t'

HEAVY_TASK_LIMIT=5

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

IDLE_CPU=$(top -b -n 1 | grep "\%Cpu(s)" | awk -F ',' '{ print $4}' | awk '{ print $1}' | cut -d "." -f 1)

if (( IDLE_CPU < 10 )); then
    report_heaviest_processes "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage" | mail -s "[Error] CPU Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "CPU Error:" "$IDLE_CPU"
elif (( IDLE_CPU < 15 )); then
    report_heaviest_processes "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage" | mail -s "[Warning] CPU Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "CPU Warning:" "$IDLE_CPU"
else
    echo "CPU is Okay:" "$IDLE_CPU"
fi

TOTAL_MEM=$(free | grep "^Mem" | awk '{print $2}')
if free | grep -q "available"; then
    ACTUAL_MEM=$(free | grep "^Mem" | awk '{print $7}')
else
    ACTUAL_MEM=$(free | grep "^-/+" | awk '{print $4}')
fi
IDLE_MEM=$(echo "$ACTUAL_MEM * 100 / $TOTAL_MEM" | bc)

if (( IDLE_MEM < 10 )); then
    report_heaviest_processes "-rss" "Top ${HEAVY_TASK_LIMIT} processes by memory usage" | mail -s "[Error] MEM Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "MEM Error:" "${IDLE_MEM}"
elif (( IDLE_MEM < 15 )); then
    report_heaviest_processes "-rss" "Top ${HEAVY_TASK_LIMIT} processes by memory usage" | mail -s "[Warning] MEM Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "MEM Warning:" "${IDLE_MEM}"
else
    echo "MEM is Okay:" "${IDLE_MEM}"
fi

if TEMPERATURE=$(read_temperature_celsius); then
    if [[ $TEMPERATURE -gt 80 ]]; then
        {
            printf 'TEMPERATURE Error: %s\n\n' "$TEMPERATURE"
            report_heaviest_processes "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage"
        } | mail -s "[Error] TEMPERATURE is too high in $(hostname)" "root@compbio.unist.ac.kr"
        echo "TEMPERATURE Error" "${TEMPERATURE}"
    elif [[ $TEMPERATURE -gt 70 && $TEMPERATURE -le 80 ]]; then
        {
            printf 'TEMPERATURE Warning: %s\n\n' "$TEMPERATURE"
            report_heaviest_processes "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage"
        } | mail -s "[Warning] TEMPERATURE is too high in $(hostname)" "root@compbio.unist.ac.kr"
        echo "TEMPERATURE Warning" "${TEMPERATURE}"
    else
        echo "TEMPERATURE is Okay" "${TEMPERATURE}"
    fi
else
    echo "TEMPERATURE check skipped: no readable thermal zone temperature file"
fi

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

                if (( GPU_MEM_USED * 100 > GPU_MEM_TOTAL * 90 || GPU_UTIL > 90 )); then
                    GPU_ALERT_LEVEL=2
                elif (( GPU_ALERT_LEVEL < 1 )) && (( GPU_MEM_USED * 100 > GPU_MEM_TOTAL * 85 || GPU_UTIL > 85 )); then
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
            } | mail -s "[Error] GPU Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
            echo "GPU Error:"
            printf '%s\n' "$GPU_REPORT"
        elif (( GPU_ALERT_LEVEL == 1 )); then
            {
                printf '%s\n\n' "$GPU_REPORT"
                report_heaviest_gpu_tasks
            } | mail -s "[Warning] GPU Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
            echo "GPU Warning:"
            printf '%s\n' "$GPU_REPORT"
        else
            echo "GPU is Okay"
            printf '%s\n' "$GPU_REPORT"
        fi
    elif nvidia_driver_unavailable "$GPU_STATUS"; then
        :
    else
        printf '%s\n' "$GPU_STATUS" | mail -s "[Error] GPU status check failed in $(hostname)" "root@compbio.unist.ac.kr"
        echo "GPU Error"
        printf '%s\n' "$GPU_STATUS"
    fi
fi

exit 0
