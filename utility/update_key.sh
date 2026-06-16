#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Export legacy apt-key entries into /etc/apt/trusted.gpg.d keyring files.
# Notes:
#   Intended for Debian/Ubuntu systems where apt-key migration is still needed.
for KEY in $(apt-key --keyring /etc/apt/trusted.gpg list | grep -E "(([ ]{1,2}(([0-9A-F]{4}))){10})" | tr -d " " | grep -E "([0-9A-F]){8}\b"); do
    K=${KEY:(-8)}
    apt-key export "$K" | sudo gpg --dearmour -o "/etc/apt/trusted.gpg.d/imported-from-trusted-gpg-$K.gpg"
done
