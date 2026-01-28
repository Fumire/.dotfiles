#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

for f in "$@"; do
    pdftoppm -jpeg -jpegopt quality=100 -r 600 "$f" "${f%.pdf}"
done
