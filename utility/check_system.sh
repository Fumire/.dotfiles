#!/bin/bash
date

IDLE_CPU=`top -b -n 1 | grep "\%Cpu(s)" | awk '{ print $8}' | cut -d "." -f 1`

if (( $IDLE_CPU < 20 )); then
    sar | mail -s "[Warning] CPU Usage is too high" -r "noreply@fumire.moe" "230@fumire.moe"
else
    echo "CPU is Okay"
fi

TOTAL_MEM=`free | awk 'FNR == 2 {print $2}'`
AVAIL_MEM=`free | awk 'FNR == 2 {print $7}'`
IDLE_MEM=`echo "$AVAIL_MEM * 100 / $TOTAL_MEM" | bc`

if (( $IDLE_MEM < 20 )); then
    sar -r | mail -s "[Warning] MEM Usage is too high" -r "noreply@fumire.moe" "230@fumire.moe"
else
    echo "MEM is Okay"
fi
