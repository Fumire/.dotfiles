#!/bin/bash
#SBATCH --chdir=.
#SBATCH --job-name=Migration
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH --mail-user='root@compbio.unist.ac.kr'
#SBATCH --output=/root/%x_%A.txt
#SBATCH --error=/root/%x_%A.txt
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Prepare checksums and a tree listing, then transfer the current directory
#   to the remote archive with rsync source-file removal enabled.
# Usage:
#   sbatch utility/migration_store.sh
# Notes:
#   This script removes transferred source files after successful rsync.
set -euo pipefail
IFS=$'\n\t'

find -L . -type f -empty \
    ! -name 'tree.txt' \
    ! -name 'md5.txt' \
    -delete -print

find -L . -type f \
    ! -name 'tree.txt' \
    ! -name 'md5.txt' \
    ! -name '*.md5sum' \
    -print0 |
    sort -z |
    xargs -0 -r md5sum >md5.txt

tree -ls -I 'tree.txt|md5.txt|*.md5sum' >tree.txt
rsync -alrtvzLP --remove-source-files --delete-during -e 'ssh -p 3030 -c aes256-cbc' "$(realpath .)" root@kimura.kogic.kr:/BiO/Archive/
