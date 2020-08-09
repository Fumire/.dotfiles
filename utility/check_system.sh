#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
# Last modified: 2020-08-07

date

IDLE_CPU=`top -b -n 1 | grep "\%Cpu(s)" | awk '{ print $8}' | cut -d "." -f 1`

if (( $IDLE_CPU < 10 )); then
    sar | mail -s "[Error] CPU Usage is too high" "230@fumire.moe"
    echo "CPU Error:" $IDLE_CPU
elif (( $IDLE_CPU < 20 )); then
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
elif (( $IDLE_MEM < 20 )); then
    free -mh | mail -s "[Warning] MEM Usage is too high" "230@fumire.moe"
    echo "MEM Warning:" $IDLE_MEM
else
    echo "MEM is Okay:" $IDLE_MEM
fi
