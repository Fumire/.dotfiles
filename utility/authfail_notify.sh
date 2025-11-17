#!/bin/bash
# Maintainer: jaewoong@unist.ac.kr
set -euo pipefail
IFS=$'\n\t'

if [ -z "$PAM_USER" ]; then
    exit 0
fi

/usr/bin/mail -s "${PAM_SERVICE}-${HOSTNAME}" "root@compbio.unist.ac.kr" <<< "Failed login attempt in ${PAM_USER} on $(date)"

exit 0
