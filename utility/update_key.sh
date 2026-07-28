#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Export legacy apt trusted keys into modern /etc/apt/keyrings keyring files.
# Notes:
#   Intended for Debian/Ubuntu systems where apt-key migration from
#   /etc/apt/trusted.gpg is still required.
set -euo pipefail
IFS=$'\n\t'

readonly LEGACY_TRUSTED_GPG="/etc/apt/trusted.gpg"
readonly OUTPUT_KEYRING_DIR="/etc/apt/keyrings"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Run this script as root to write to ${OUTPUT_KEYRING_DIR}." >&2
    exit 1
fi

if [[ ! -f "$LEGACY_TRUSTED_GPG" ]]; then
    echo "No legacy keyring at $LEGACY_TRUSTED_GPG; nothing to migrate."
    exit 0
fi

mkdir -p "$OUTPUT_KEYRING_DIR"

readonly TMP_KEY="$(mktemp)"
cleanup() {
    rm -f "$TMP_KEY"
}
trap cleanup EXIT

for KEY in $(gpg --no-default-keyring --keyring "$LEGACY_TRUSTED_GPG" --list-keys --with-colons 2>/dev/null | awk -F: '/^pub:/ {print $5}'); do
    if [[ ! "$KEY" =~ ^[0-9A-Fa-f]{8,40}$ ]]; then
        continue
    fi

    gpg --batch --yes --no-default-keyring --keyring "$LEGACY_TRUSTED_GPG" --export "$KEY" > "$TMP_KEY"

    if [[ ! -s "$TMP_KEY" ]]; then
        echo "No key material exported for $KEY" >&2
        continue
    fi

    gpg --dearmor --batch --yes --output "/etc/apt/keyrings/imported-from-trusted-gpg-$KEY.gpg" "$TMP_KEY"
    chmod 0644 "/etc/apt/keyrings/imported-from-trusted-gpg-$KEY.gpg"
    echo "Imported $KEY -> /etc/apt/keyrings/imported-from-trusted-gpg-$KEY.gpg"
done
