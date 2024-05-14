#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
set -euo pipefail
IFS=$'\n\t'
tree -ls | tree tree.txt 
find -L -type f -exec md5sum '{}' \; | tee md5.txt
