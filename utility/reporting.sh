#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
set -euo pipefail
IFS=$'\n\t'

hosts=("host1" "host2")

for h in ${hosts[@]}; do
	scp -c aes256-cbc -P $PORT jwlee230@$h.kogic.kr:/var/log/sysstat/sa$(date +%d) $h
done

for h in ${hosts[@]}; do
	sadf -g -O autoscale,showinfo,packed,height=700 -T -- -r -u $h > $h.svg
	convert -density 500 -crop 5500x3500+0+0 $h.svg /var/www/html/image/top/$h.jpg &
done
wait

for h in ${hosts[@]}; do
	rm -fv $h*
done

for h in ${hosts[@]}; do
	date | mail --attach /var/www/html/image/top/$h.jpg --subject "Server report ($h) on $(date +%Y%m%d)" -- "root@compbio.unist.ac.kr"
done
