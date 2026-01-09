#!/bin/bash
#SBATCH --chdir=.
#SBATCH --job-name=Migration
#SbATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH --mail-user='root@compbio.unist.ac.kr'
#SBATCH --output=/root/%x_%A.txt
#SBATCH --error=/root/%x_%A.txt
# Maintainer: jwlee230@unist.ac.kr
find -L . -type f -empty -delete -print
find . -type f ! -empty ! -name '*.md5sum' -exec sh -c 'md5sum "$1" | awk "{print \$1}" > "$1.md5sum"' _ '{}' \; -print
tree -ls | tee tree.txt
