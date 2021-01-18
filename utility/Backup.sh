#!/bin/bash
mkdir /BiO/Backup/`date +%Y%m%d`
tar -czpf /BiO/Backup/`date +%Y%m%d`/`date +%Y%m%d`.tgz /etc/passwd /etc/group /etc/shadow 1>/dev/null 2>/dev/null
