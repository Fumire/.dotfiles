#!/bin/bash
# Maintainer: jaewoong@unist.ac.kr
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
    echo "TEMPERATURE Error: ${TEMPERATURE}" | mail -s "[ERROR] TEMPERATURE is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "TEMPERATURE Error" "${TEMPERATURE}"
elif [[ $TEMPERATURE -gt 70 && $TEMPERATURE -le 80 ]]; then
    echo "TEMPERATURE Warning: $TEMPERATURE" | mail -s "[Warning] TEMPERATURE is too high in $(hostname)" "root@compbio.unist.ac.kr"
    echo "TEMPERATURE Error" "${TEMPERATURE}"
else
    echo "TEMPERATURE Error" "${TEMPERATURE}"
fi
