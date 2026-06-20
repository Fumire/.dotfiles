#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Convert PDF pages to 600 DPI JPEG images with pdftoppm.
# Usage:
#   utility/pdf2jpg.sh FILE.pdf [...]
set -euo pipefail
IFS=$'\n\t'

show_help() {
    cat <<EOF
Usage:
  utility/pdf2jpg.sh FILE.pdf [...]

Convert one or more PDF files to 600 DPI JPEG images with pdftoppm.
Each output prefix is the input path without the trailing .pdf extension.

Arguments:
  FILE.pdf    PDF file to convert. At least one is required.

Options:
  -h, --help  Show this help message
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

if (($# == 0)); then
    echo "Error: at least one PDF file is required." >&2
    show_help >&2
    exit 1
fi

if [[ $(uname -s) != "Darwin" ]]; then
    echo "pdf2jpg.sh is only supported on macOS." >&2
    exit 0
fi

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

for f in "$@"; do
    if [[ ! -f "$f" ]]; then
        echo "Error: not a file: $f" >&2
        show_help >&2
        exit 1
    fi

    pdftoppm -jpeg -jpegopt quality=100 -r 600 "$f" "${f%.pdf}"
done
