#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
# Last modified: 2020-10-27

date

IDLE_CPU=`top -b -n 1 | grep "\%Cpu(s)" | awk '{ print $8}' | cut -d "." -f 1`

if (( $IDLE_CPU < 10 )); then
    sar | mail -s "[Error] CPU Usage is too high" "230@fumire.moe"
    echo "CPU Error:" $IDLE_CPU
elif (( $IDLE_CPU < 15 )); then
    sar | mail -s "[Warning] CPU Usage is too high" "230@fumire.moe"
    echo "CPU Warning:" $IDLE_CPU
else
    echo "CPU is Okay:" $IDLE_CPU
fi

TOTAL_MEM=`free | grep "^Mem" | awk '{print $2}'`
if [[ -z `free | grep "available"` ]]; then
    ACTUAL_MEM=`free | grep "^-/+" | awk '{print $4}'`
else
    ACTUAL_MEM=`free | grep "^Mem" | awk '{print $7}'`
fi
IDLE_MEM=`echo "$ACTUAL_MEM * 100 / $TOTAL_MEM" | bc`

if (( $IDLE_MEM < 10 )); then
    free -mh | mail -s "[Error] MEM Usage is too high" "230@fumire.moe"
    echo "MEM Error:" $IDLE_MEM
elif (( $IDLE_MEM < 15 )); then
    free -mh | mail -s "[Warning] MEM Usage is too high" "230@fumire.moe"
    echo "MEM Warning:" $IDLE_MEM
else
    echo "MEM is Okay:" $IDLE_MEM
fi

TEMPERATURE=$(cat /sys/class/thermal/thermal_zone0/temp)
TEMPERATURE="$(echo "$TEMPERATURE / 1000" | bc -l | xargs printf "%1.0f")"

if [[ $TEMPERATURE -gt 80 ]]; then
    mail -s "[ERROR] TEMPERATURE is too high" "230@fumire.moe"
    echo "TEMPERATURE Error" $TEMPERATURE
elif [[ $TEMPERATURE -gt 60 && $TEMPERATURE -le 80 ]]; then
    mail -s "[Warning] TEMPERATURE is too high" "230@fumire.moe"
    echo "TEMPERATURE Warning:" $TEMPERATURE
else
    echo "TEMPERATURE is Okay:" $TEMPERATURE
fi
