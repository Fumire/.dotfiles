#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

for f in "$@"; do
    /opt/homebrew/bin/pdftoppm -jpeg -jpegopt quality=100 -r 600 "$f" "${f%.pdf}"
done
