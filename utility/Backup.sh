#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Archive account-related system files into a dated /BiO/Backup folder and
#   email the archive to root.
# Notes:
#   Intended for the matching Linux server environment with root access.
set -euo pipefail
IFS=$'\n\t'
mkdir "/BiO/Backup/$(date +%Y%m%d)"
tar -czpf "/BiO/Backup/$(date +%Y%m%d)/$(date +%Y%m%d).tgz" /etc/passwd /etc/group /etc/shadow 1>/dev/null 2>&1
date | mail --attach "/BiO/Backup/$(date +%Y%m%d)/$(date +%Y%m%d).tgz" --subject "Backup from $(hostname) on $(date +%Y%m%d)" "root@compbio.unist.ac.kr"
