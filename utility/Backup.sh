#!/usr/bin/env bash
# Maintainer: jwlee230@unist.ac.kr
set -euo pipefail
IFS=$'\n\t'
mkdir /BiO/Backup/$(date +%Y%m%d)
tar -czpf /BiO/Backup/$(date +%Y%m%d)/$(date +%Y%m%d).tgz /etc/passwd /etc/group /etc/shadow 1>/dev/null 2>&1
date | mail --attach /BiO/Backup/$(date +%Y%m%d)/$(date +%Y%m%d).tgz --subject "Backup from $(hostname)" "root@compbio.unist.ac.kr"
