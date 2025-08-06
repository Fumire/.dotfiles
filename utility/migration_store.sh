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
tree -ls | tee tree.txt 
find -L -type f ! -name 'tree.txt' -exec md5sum '{}' \; | tee md5.txt
rsync -alrtvzLP -e 'ssh -p 3030 -c aes256-cbc' $(realpath .) root@kimura.kogic.kr:/BiO/Archive/ && rm -rfv $(realpath .)
