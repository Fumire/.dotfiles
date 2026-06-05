#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
set -euo pipefail
IFS=$'\n\t'

if [[ $(uname -s) != "Darwin" ]]; then
    echo "pdf2jpg.sh is only supported on macOS." >&2
    exit 0
fi

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

for f in "$@"; do
    pdftoppm -jpeg -jpegopt quality=100 -r 600 "$f" "${f%.pdf}"
done
