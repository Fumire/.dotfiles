#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
set -euo pipefail
IFS=$'\n\t'
tree -ls -I "tree.txt|md5.txt" | diff - tree.txt
md5sum -c md5.txt
