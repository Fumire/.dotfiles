#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Create a Linux server user under /BiO/Live and add the user to compbio and
#   docker groups.
# Usage:
#   sudo utility/make_user.sh --id USER_ID [--uid UID] [--gid GID]
# Notes:
#   adduser remains interactive for password and user information prompts.
set -euo pipefail
IFS=$'\n\t'

show_help() {
    cat <<EOF
Usage:
  sudo utility/make_user.sh --id USER_ID [--uid UID] [--gid GID]

Create a Linux server user under /BiO/Live, then add the user to compbio and
docker groups. The script still leaves adduser's password and user information
prompts interactive.

Options:
  --id USER_ID    Required login ID for the new user
  --uid UID       Optional numeric UID
  --gid GID       Optional numeric GID
  -h, --help      Show this help message
EOF
}

ID=""
newUID=""
newGID=""

while (($# > 0)); do
    case "$1" in
        --id)
            if [[ -z "${2:-}" ]]; then
                echo "--id requires a value" >&2
                exit 1
            fi
            ID=$2
            shift 2
            ;;
        --uid)
            if [[ -z "${2:-}" ]]; then
                echo "--uid requires a value" >&2
                exit 1
            fi
            newUID=$2
            shift 2
            ;;
        --gid)
            if [[ -z "${2:-}" ]]; then
                echo "--gid requires a value" >&2
                exit 1
            fi
            newGID=$2
            shift 2
            ;;
        -h | --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

if [[ -n "${ID}" ]]; then
    echo "ID is <${ID}>"
else
    echo "ID cannot be NULL" >&2
    show_help >&2
    exit 1
fi

if [[ -n "${newUID}" ]]; then
    if [[ ! "$newUID" =~ ^[0-9]+$ ]]; then
        echo "UID must be numeric: ${newUID}" >&2
        exit 1
    fi
    echo "UID is <${newUID}>"
else
    echo "UID is NULL"
fi

if [[ -n "${newGID}" ]]; then
    if [[ ! "$newGID" =~ ^[0-9]+$ ]]; then
        echo "GID must be numeric: ${newGID}" >&2
        exit 1
    fi
    echo "GID is <${newGID}>"
else
    echo "GID is NULL"
fi

if getent passwd "${ID}" >/dev/null 2>&1; then
    echo "Same ID exists"
    exit 1
fi

adduser_args=(--home "/BiO/Live/${ID}" --shell /bin/bash)

if [[ -n "${newUID}" ]]; then
    adduser_args+=(--uid "${newUID}")
fi

if [[ -n "${newGID}" ]]; then
    adduser_args+=(--gid "${newGID}")
fi

adduser "${adduser_args[@]}" "${ID}"

gpasswd -a "${ID}" compbio
gpasswd -a "${ID}" docker

echo "Done!!"
