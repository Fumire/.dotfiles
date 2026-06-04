#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
set -euo pipefail
IFS=$'\n\t'

if [[ $(uname -s) != "Darwin" ]]; then
    echo "disable_spotlight.sh is only supported on macOS." >&2
    exit 0
fi

for f in "$@"; do
    touch "$f/.metadata_never_index"
    dot_clean -mv "$f"
done
