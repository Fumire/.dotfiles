#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
set -euo pipefail
IFS=$'\n\t'
rsync -alrtvzLP -e 'ssh -p 3030 -c aes256-cbc' $(realpath .)
