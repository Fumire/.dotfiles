#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
set -euo pipefail
IFS=$'\n\t'

for f in "$@"; do
    touch "$f/.metadata_never_index"
    dot_clean -mv "$f"
done
