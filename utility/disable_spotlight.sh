#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Mark macOS paths as Spotlight-excluded and clean AppleDouble metadata.
# Usage:
#   utility/disable_spotlight.sh PATH [...]
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
