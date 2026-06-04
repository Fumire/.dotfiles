#!/bin/bash
#SBATCH --chdir=.
#SBATCH --job-name=Migration_check
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH --mail-user='root@compbio.unist.ac.kr'
#SBATCH --output=/root/%x_%A.txt
#SBATCH --error=/root/%x_%A.txt
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
set -euo pipefail
IFS=$'\n\t'
tree -ls -I "tree.txt|md5.txt" | diff - tree.txt
md5sum -c md5.txt 2>&1 | mail -s "MD5 check report for $(hostname): $(basename "$(realpath .)")" "root@compbio.unist.ac.kr"
