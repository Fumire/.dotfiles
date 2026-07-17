#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Email root when PAM reports a failed login attempt.
# Environment:
#   PAM_USER is required to send a notification. PAM_SERVICE and HOSTNAME are
#   used when available and otherwise receive safe fallback values.
set -euo pipefail
IFS=$'\n\t'

readonly PAM_LOGIN_USER="${PAM_USER:-}"
readonly PAM_LOGIN_SERVICE="${PAM_SERVICE:-unknown-service}"
readonly PAM_LOGIN_HOST="${HOSTNAME:-$(hostname)}"

if [[ -z "$PAM_LOGIN_USER" ]]; then
    exit 0
fi

/usr/bin/mail -s "${PAM_LOGIN_SERVICE}-${PAM_LOGIN_HOST}" "root@compbio.unist.ac.kr" <<< "Failed login attempt for ${PAM_LOGIN_USER} on $(date)"
exit 0
