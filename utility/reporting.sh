#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
# Last modified: 2023-11-21
set -euo pipefail
IFS=$'\n\t'
for h in 'host1' 'host2'; do
    scp -c aes256-cbc -P $PORT jwlee230@$h.kogic.kr:/var/log/sysstat/sa$(date +%d) $h
done
for h in 'host1' 'host2'; do
    sadf -g -O autoscale,showinfo,packed,height=700 -T -- -r -u $h > $h.svg
    convert -density 500 -crop 5500x3500+0+0 $h.svg /var/www/html/image/top/$h.jpg &
done
wait
for h in 'host1' 'host2'; do
    rm -fv $h*
done
date | mail --attach /var/www/html/image/top/*.jpg --subject "Server report on $(date +%Y%m%d)" -- "root@compbio.unist.ac.kr"
