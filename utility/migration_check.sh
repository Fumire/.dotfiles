#!/bin/bash
#SBATCH --chdir=$(realpath .)
#SBATCH --job-name=$(hostname)_$(basename $(realpath .))
#SbATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH --mail-user='root@compbio.unist.ac.kr'
#SBATCH --output=~/%x_%A.txt
#SBATCH --error=~/%x_%A.txt
# Maintainer: jwlee230@unist.ac.kr
set -euo pipefail
IFS=$'\n\t'
tree -ls -I "tree.txt|md5.txt" | diff - tree.txt
md5sum --quiet -c md5.txt
