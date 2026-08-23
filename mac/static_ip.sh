#!/usr/bin/env bash
set -euo pipefail

# Values transcribed from the supplied macOS Network settings screenshots.
readonly NETWORK_SERVICE="${NETWORK_SERVICE:-USB 10/100/1000 LAN}"
readonly STATIC_IP_PREFIX="172.27.35."
readonly SUBNET_MASK="${SUBNET_MASK:-255.255.255.0}"
readonly ROUTER="${ROUTER:-172.27.35.254}"
readonly SEARCH_DOMAIN="${SEARCH_DOMAIN:-gist.ac.kr}"
readonly DNS_SERVERS=(
  "203.237.32.100"
  "203.237.32.101"
  "1.1.1.1"
  "1.0.0.1"
  "8.8.8.8"
  "8.8.4.4"
)

usage() {
  cat <<'EOF'
Usage:
  bash static_ip.sh <last_octet>

Applies static IP settings in 172.27.35.0/24 to the USB LAN service.

Examples:
  bash static_ip.sh 23
  bash static_ip.sh 24

Optional environment override:
  NETWORK_SERVICE (default: USB 10/100/1000 LAN)
EOF
}

if [[ "${1-}" == "-h" || "${1-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 ]]; then
  printf 'Error: missing required argument <last_octet>.\n\n' >&2
  usage >&2
  exit 1
fi

readonly STATIC_IP_OCTET="$1"
readonly STATIC_IP="${STATIC_IP_PREFIX}${STATIC_IP_OCTET}"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "This script can only be run on macOS."
fi

NETWORKSETUP="$(command -v networksetup || true)"
[[ -n "$NETWORKSETUP" ]] || die "The networksetup command was not found."

# Changing network settings with networksetup may require administrator privileges.
SUDO=()
if [[ "$EUID" -ne 0 ]]; then
  command -v sudo >/dev/null 2>&1 || die "The sudo command was not found."
  sudo -v
  SUDO=(sudo)
fi

run_networksetup() {
  "${SUDO[@]}" "$NETWORKSETUP" "$@"
}

if [[ ! "$STATIC_IP_OCTET" =~ ^[0-9]{1,3}$ ]]; then
  die "The final octet of the static IP must be 1-254 (e.g., 23)."
fi

if (( 10#$STATIC_IP_OCTET < 1 || 10#$STATIC_IP_OCTET > 254 )); then
  die "The final octet of the static IP must be 1-254 (got: $STATIC_IP_OCTET)."
fi

services="$(run_networksetup -listallnetworkservices)"
if ! printf '%s\n' "$services" \
  | sed '1d; s/^\*//' \
  | grep -Fqx -- "$NETWORK_SERVICE"; then
  printf 'Error: network service %q was not found.\n' "$NETWORK_SERVICE" >&2
  printf '\nAvailable network services:\n%s\n' "$services" >&2
  exit 1
fi

printf 'Target service: %s\n' "$NETWORK_SERVICE"
printf '\nCurrent configuration:\n'
run_networksetup -getinfo "$NETWORK_SERVICE" || true
run_networksetup -getdnsservers "$NETWORK_SERVICE" || true
run_networksetup -getsearchdomains "$NETWORK_SERVICE" || true

printf '\nApplying static IPv4 configuration...\n'
run_networksetup -setmanual \
  "$NETWORK_SERVICE" "$STATIC_IP" "$SUBNET_MASK" "$ROUTER"

# Screenshot 1 shows IPv6 as Automatically configured.
run_networksetup -setv6automatic "$NETWORK_SERVICE"

printf 'Applying DNS servers and search domain...\n'
run_networksetup -setdnsservers "$NETWORK_SERVICE" "${DNS_SERVERS[@]}"
run_networksetup -setsearchdomains "$NETWORK_SERVICE" "$SEARCH_DOMAIN"

printf '\nConfiguration after applying changes:\n'
run_networksetup -getinfo "$NETWORK_SERVICE"
run_networksetup -getdnsservers "$NETWORK_SERVICE"
run_networksetup -getsearchdomains "$NETWORK_SERVICE"

printf '\nDone: static IPv4 configuration applied to %s.\n' "$NETWORK_SERVICE"
