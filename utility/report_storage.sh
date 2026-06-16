#!/usr/bin/env bash
#SBATCH --chdir=.
#SBATCH --job-name=Storage
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH --mail-user='root@compbio.unist.ac.kr'
#SBATCH --output=/root/%x_%A.txt
#SBATCH --error=/root/%x_%A.txt
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Generate a du-based storage report for the current directory and email it
#   as a TSV attachment.
# Usage:
#   sbatch utility/report_storage.sh
number=$RANDOM
du -s ./* > /BiO/Live/jwlee230/Report_${number}.tsv
pwd | mail --attach /BiO/Live/jwlee230/Report_${number}.tsv --subject "Storage report for $(hostname)" -- "root@compbio.unist.ac.kr"
rm /BiO/Live/jwlee230/Report_${number}.tsv
