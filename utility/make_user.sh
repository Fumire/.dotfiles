#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
# Last modified: 2021-03-30
set -euo pipefail
IFS=$'\n\t'

read -p "Input User ID: " ID
if [ -n "${ID}" ]
then
    echo "ID is <${ID}>"
else
    echo "ID cannot be NULL"
    exit
fi

read -p "Input UID(can be NULL): " newUID
if [ -n "${newUID}" ]
then
    echo "UID is <${newUID}>"
else
    echo "UID is NULL"
fi

read -p "Input GID(can be NULL): " newGID
if [ -n "${newGID}" ]
then
    echo "GID is <${newGID}>"
else
    echo "GID is NULL"
fi

if [ -n "`cat /etc/passwd | grep ${ID}`" ]
then
    echo "Same ID exists"
    exit
fi

if [ -z "${newUID}" -a -z "${newGID}" ]
then
    adduser --home /BiO/Live/${ID} --shell /bin/bash ${ID}
elif [ -n "${newUID}" ]
then
    adduser --home /BiO/Live/${ID} --shell /bin/bash -uid ${newUID} ${ID}
elif [ -n "${newGID}" ]
then
    adduser --home /BiO/Live/${ID} --shell /bin/bash -gid ${newGID} ${ID}
else
    adduser --home /BiO/Live/${ID} --shell /bin/bash -uid ${newUID} -gid ${newGID} ${ID}
fi

gpasswd -a ${ID} compbio
gpasswd -a ${ID} docker

passwd -e ${ID}

echo "Done!!"
