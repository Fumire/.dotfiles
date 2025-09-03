#!/usr/bin/env bash
#SBATCH --chdir=.
#SBATCH --job-name=Storage
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH --mail-user='root@compbio.unist.ac.kr'
#SBATCH --output=/root/%x_%A.txt
#SBATCH --error=/root/%x_%A.txt
# Maintainer: jwlee230@unist.ac.kr
number=$RANDOM
du -s * > /BiO/Live/jwlee230/Report_${number}.txt
pwd | mail --attach /BiO/Live/jwlee230/Report_${number}.txt --subject "Storage report for $(hostname)" "root@compbio.unist.ac.kr"
rm /BiO/Live/jwlee230/Report_${number}.txt
