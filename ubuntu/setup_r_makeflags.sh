#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.R" && echo "MAKEFLAGS = -j 10" > "$HOME/.R/Makevars"
