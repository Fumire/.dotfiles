#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
for h in 'darwin' 'wallace' 'compbio' 'huxley' 'kimura' 'fisher'; do
    scp -c aes256-cbc -P 3030 jwlee230@$h.kogic.kr:/var/log/sysstat/sa$(date +%d) $h
done
for h in 'darwin' 'wallace' 'compbio' 'huxley' 'kimura' 'fisher'; do
    if [[ "$h" != "compbio" ]]; then
        sadf -c $h 1> $h.new 2> /dev/null
        rm $h
    else
        mv $h $h.new
    fi
    sadf -g -O autoscale,showinfo,packed,height=400 -T -- $h.new > $h.svg && rm $h.new
    convert -density 500 $h.svg /var/www/html/image/top/$h.jpg && rm $h.svg
done
