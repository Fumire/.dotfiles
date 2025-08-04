#!/bin/bash
#SBATCH --chdir=$(realpath .)
#SBATCH --job-name=$(hostname)_$(realpath .)
#SbATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH --mail-user='root@compbio.unist.ac.kr'
#SBATCH --output=~/%x_%A.txt
#SBATCH --error=~/%x_%A.txt
# Maintainer: jwlee230@unist.ac.kr
number=$RANDOM
du -s * > /BiO/Live/jwlee230/Report_${number}.txt
