#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Mark macOS paths as Spotlight-excluded and clean AppleDouble metadata.
# Usage:
#   utility/disable_spotlight.sh DIRECTORY [...]
set -euo pipefail
IFS=$'\n\t'

show_help() {
    cat <<EOF
Usage:
  utility/disable_spotlight.sh DIRECTORY [...]

Mark one or more macOS directories or mounted volumes as Spotlight-excluded,
then clean AppleDouble metadata with dot_clean.

Arguments:
  DIRECTORY    Target directory or mounted volume. At least one is required.

Options:
  -h, --help   Show this help message
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

if (($# == 0)); then
    echo "Error: at least one directory is required." >&2
    show_help >&2
    exit 1
fi

if [[ $(uname -s) != "Darwin" ]]; then
    echo "disable_spotlight.sh is only supported on macOS." >&2
    exit 0
fi

for f in "$@"; do
    if [[ ! -d "$f" ]]; then
        echo "Error: not a directory: $f" >&2
        show_help >&2
        exit 1
    fi

    touch "$f/.metadata_never_index"
    dot_clean -mv "$f"
done
