#!/bin/bash
# Maintainer: jwlee230@unist.ac.kr
# Last modified: 2023-11-21
# Original from: https://shutcoding.tistory.com/24
# UPPERCASE space-separated country codes to ACCEPT
ALLOW_COUNTRIES="KR"

if [ $# -ne 1 ]; then
    echo "Usage:  `basename $0` <ip>" 1>&2
    exit 0 # return true in case of config issue
fi

COUNTRY=`geoiplookup $1 | awk -F ": " '{ print $2 }' | awk -F "," '{ print $1 }' | head -n 1`

[[ $COUNTRY = "IP Address not found" || $ALLOW_COUNTRIES =~ $COUNTRY ]] && RESPONSE="ALLOW" || RESPONSE="DENY"

if [ $RESPONSE = "ALLOW" ]
then
    exit 0
else
    logger "$RESPONSE sshd connection from $1 ($COUNTRY)"
    exit 1
fi
