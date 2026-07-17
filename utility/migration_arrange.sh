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
#   Prepare a migration source directory by deleting empty files, writing
#   checksum and tree manifests for later verification.
# Usage:
#   sbatch utility/migration_arrange.sh
set -euo pipefail
IFS=$'\n\t'

find -L . -type f -empty \
    ! -name 'tree.txt' \
    ! -name 'md5.txt' \
    -delete -print

find . -type f \
    ! -name 'tree.txt' \
    ! -name 'md5.txt' \
    ! -name '*.md5sum' \
    -print0 |
    sort -z |
    xargs -0 -r md5sum >md5.txt

tree -ls -I 'tree.txt|md5.txt|*.md5sum' >tree.txt
