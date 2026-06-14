#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
set -euo pipefail
IFS=$'\n\t'

HEAVY_TASK_LIMIT=5

report_heaviest_tasks() {
    local sort_column=$1
    local title=$2

    printf '%s\n' "$title"
    printf 'Generated at: %s on %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$(hostname)"
    ps -eo pid,ppid,user,pcpu,pmem,etime,args --sort="$sort_column" | head -n "$((HEAVY_TASK_LIMIT + 1))"
}

report_heaviest_gpu_tasks() {
    local gpu_processes

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

    printf 'PID, Process, Used GPU memory (MiB)\n'
    printf '%s\n' "$gpu_processes" | sort -t',' -k3,3nr | head -n "$HEAVY_TASK_LIMIT"
}

IDLE_CPU=$(top -b -n 1 | grep "\%Cpu(s)" | awk -F ',' '{ print $4}' | awk '{ print $1}' | cut -d "." -f 1)

if (( IDLE_CPU < 10 )); then
    report_heaviest_tasks "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage" | mail -s "[Error] CPU Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "CPU Error:" "$IDLE_CPU"
elif (( IDLE_CPU < 15 )); then
    report_heaviest_tasks "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage" | mail -s "[Warning] CPU Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
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
    report_heaviest_tasks "-pmem" "Top ${HEAVY_TASK_LIMIT} processes by memory usage" | mail -s "[Error] MEM Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "MEM Error:" "${IDLE_MEM}"
elif (( IDLE_MEM < 15 )); then
    report_heaviest_tasks "-pmem" "Top ${HEAVY_TASK_LIMIT} processes by memory usage" | mail -s "[Warning] MEM Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "MEM Warning:" "${IDLE_MEM}"
else
    echo "MEM is Okay:" "${IDLE_MEM}"
fi

TEMPERATURE=$(cat /sys/class/thermal/thermal_zone0/temp)
TEMPERATURE="$(echo "$TEMPERATURE / 1000" | bc -l | xargs printf "%1.0f")"

if [[ $TEMPERATURE -gt 80 ]]; then
    {
        printf 'TEMPERATURE Error: %s\n\n' "$TEMPERATURE"
        report_heaviest_tasks "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage"
    } | mail -s "[Error] TEMPERATURE is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "TEMPERATURE Error" "${TEMPERATURE}"
elif [[ $TEMPERATURE -gt 70 && $TEMPERATURE -le 80 ]]; then
    {
        printf 'TEMPERATURE Warning: %s\n\n' "$TEMPERATURE"
        report_heaviest_tasks "-pcpu" "Top ${HEAVY_TASK_LIMIT} processes by CPU usage"
    } | mail -s "[Warning] TEMPERATURE is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "TEMPERATURE Warning" "${TEMPERATURE}"
else
    echo "TEMPERATURE is Okay" "${TEMPERATURE}"
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
    else
        printf '%s\n' "$GPU_STATUS" | mail -s "[Error] GPU status check failed in $(hostname)" "root@compbio.unist.ac.kr"
        echo "GPU Error"
        printf '%s\n' "$GPU_STATUS"
    fi
fi

exit 0
