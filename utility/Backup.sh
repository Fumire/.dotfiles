#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Archive account-related system files into a dated /BiO/Backup folder and
#   email the archive to root.
# Notes:
#   Intended for the matching Linux server environment with root access.
set -euo pipefail
IFS=$'\n\t'

readonly BACKUP_DATE="$(date +%Y%m%d)"
readonly BACKUP_DIR="/BiO/Backup/${BACKUP_DATE}"
readonly BACKUP_ARCHIVE="${BACKUP_DIR}/${BACKUP_DATE}.tgz"

mkdir -p "$BACKUP_DIR"
tar -czpf "$BACKUP_ARCHIVE" /etc/passwd /etc/group /etc/shadow
date | mail --attach "$BACKUP_ARCHIVE" --subject "Backup from $(hostname) on ${BACKUP_DATE}" "root@compbio.unist.ac.kr"
