#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Email root when PAM reports a failed login attempt.
# Environment:
#   PAM_USER, PAM_SERVICE, and HOSTNAME are expected from PAM.
set -euo pipefail
IFS=$'\n\t'

if [ -z "$PAM_USER" ]; then
    exit 0
fi

/usr/bin/mail -s "${PAM_SERVICE}-${HOSTNAME}" "root@compbio.unist.ac.kr" <<< "Failed login attempt in ${PAM_USER} on $(date)"
exit 0
