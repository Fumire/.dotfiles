#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
# Last modified: 2023-11-21
set -euo pipefail
IFS=$'\n\t'
# sadf -g -O autoscale,showinfo,packed,height=700 -T -- -r -u /var/log/sysstat/sa$(date +%d) > $(hostname).svg
sadf -g -O autoscale,showinfo,packed,height=700 -T -- -b -P all -r -u /var/log/sysstat/sa$(date +%d) > $(hostname).svg
convert -density 300 -background none -crop x3300+0+0 $(hostname).svg $(hostname).png
date -Iseconds | mutt -s "Daily Usage of $(hostname): $(date +%F)" -a $(hostname).png -- "root@compbio.unist.ac.kr"
