#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

for f in "$@"; do
    touch "$f/.metadata_never_index"
    dot_clean -mv "$f"
done
