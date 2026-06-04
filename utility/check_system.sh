#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
set -euo pipefail
IFS=$'\n\t'

IDLE_CPU=$(top -b -n 1 | grep "\%Cpu(s)" | awk -F ',' '{ print $4}' | awk '{ print $1}' | cut -d "." -f 1)

if (( IDLE_CPU < 10 )); then
    sar | tail -n 300 | mail -s "[Error] CPU Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "CPU Error:" "$IDLE_CPU"
elif (( IDLE_CPU < 15 )); then
    sar | tail -n 300 | mail -s "[Warning] CPU Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "CPU Warning:" "$IDLE_CPU"
else
    echo "CPU is Okay:" "$IDLE_CPU"
fi

TOTAL_MEM=$(free | grep "^Mem" | awk '{print $2}')
if [[ $(free | grep -q "available") -eq 0 ]]; then
    ACTUAL_MEM=$(free | grep "^-/+" | awk '{print $4}')
else
    ACTUAL_MEM=$(free | grep "^Mem" | awk '{print $7}')
fi
IDLE_MEM=$(echo "$ACTUAL_MEM * 100 / $TOTAL_MEM" | bc)

if (( IDLE_MEM < 10 )); then
    free -mh | mail -s "[Error] MEM Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "MEM Error:" "${IDLE_MEM}"
elif (( IDLE_MEM < 15 )); then
    free -mh | mail -s "[Warning] MEM Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "MEM Warning:" "${IDLE_MEM}"
else
    echo "MEM is Okay:" "${IDLE_MEM}"
fi

TEMPERATURE=$(cat /sys/class/thermal/thermal_zone0/temp)
TEMPERATURE="$(echo "$TEMPERATURE / 1000" | bc -l | xargs printf "%1.0f")"

if [[ $TEMPERATURE -gt 80 ]]; then
    echo "TEMPERATURE Error: ${TEMPERATURE}" | mail -s "[Error] TEMPERATURE is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "TEMPERATURE Error" "${TEMPERATURE}"
elif [[ $TEMPERATURE -gt 70 && $TEMPERATURE -le 80 ]]; then
    echo "TEMPERATURE Warning: $TEMPERATURE" | mail -s "[Warning] TEMPERATURE is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "TEMPERATURE Error" "${TEMPERATURE}"
else
    echo "TEMPERATURE Error" "${TEMPERATURE}"
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
                printf 'Full nvidia-smi output:\n%s\n' "$GPU_STATUS"
            } | mail -s "[Error] GPU Usage is too high in $(hostname)" "root@compbio.unist.ac.kr"
            echo "GPU Error:"
            printf '%s\n' "$GPU_REPORT"
        elif (( GPU_ALERT_LEVEL == 1 )); then
            {
                printf '%s\n\n' "$GPU_REPORT"
                printf 'Full nvidia-smi output:\n%s\n' "$GPU_STATUS"
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
