#!/bin/bash
date

IDLE_CPU=`top -b -n 1 | grep "\%Cpu(s)" | awk '{ print $8}' | cut -d "." -f 1`

if (( $IDLE_CPU < 20 )); then
    sar | mail -s "[Warning] CPU Usage is too high" -r "noreply@fumire.moe" "230@fumire.moe"
else
    echo "CPU is Okay:" $IDLE_CPU
fi

TOTAL_MEM=`free | grep "^Mem" | awk '{print $2}'`
if [[ -z `free | grep "available"` ]]; then
    ACTUAL_MEM=`free | grep "^-/+" | awk '{print $3}'`
else
    ACTUAL_MEM=`free | grep "^Mem" | awk '{print $7}'`
fi
IDLE_MEM=`echo "$ACTUAL_MEM * 100 / $TOTAL_MEM" | bc`

if (( $IDLE_MEM < 20 )); then
    sar -r | mail -s "[Warning] MEM Usage is too high" -r "noreply@fumire.moe" "230@fumire.moe"
else
    echo "MEM is Okay:" $IDLE_MEM
fi
