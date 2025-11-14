#!/bin/bash
# Maintainer: jaewoong@unist.ac.kr
set -euo pipefail
IFS=$'\n\t'

read -rp "Input User ID: " ID
if [ -n "${ID}" ]; then
    echo "ID is <${ID}>"
else
    echo "ID cannot be NULL"
    exit
fi

read -rp "Input UID(can be NULL): " newUID
if [ -n "${newUID}" ]; then
    echo "UID is <${newUID}>"
else
    echo "UID is NULL"
fi

read -rp "Input GID(can be NULL): " newGID
if [ -n "${newGID}" ]; then
    echo "GID is <${newGID}>"
else
    echo "GID is NULL"
fi

if [ "$(cat /etc/passwd | grep -q "${ID}")" -eq 0 ]; then
    echo "Same ID exists"
    exit
fi

if [ -z "${newUID}" ] && [ -z "${newGID}" ]; then
    adduser --home "/BiO/Live/${ID}" --shell /bin/bash "${ID}"
elif [ -n "${newUID}" ]; then
    adduser --home "/BiO/Live/${ID}" --shell /bin/bash --uid "${newUID}" "${ID}"
elif [ -n "${newGID}" ]; then
    adduser --home "/BiO/Live/${ID}" --shell /bin/bash --gid "${newGID}" "${ID}"
else
    adduser --home "/BiO/Live/${ID}" --shell /bin/bash --uid "${newUID}" --gid "${newGID}" "${ID}"
fi

gpasswd -a "${ID}" compbio
gpasswd -a "${ID}" docker

echo "Done!!"
