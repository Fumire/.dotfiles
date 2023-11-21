#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
# Last modified: 2023-11-21
set -euo pipefail
IFS=$'\n\t'
mkdir /BiO/Backup/`date +%Y%m%d`
tar -czpf /BiO/Backup/`date +%Y%m%d`/`date +%Y%m%d`.tgz /etc/passwd /etc/group /etc/shadow 1>/dev/null 2>&1
