#!/usr/bin/bash
#SBATCH --time=1-
#SBATCH --cpus-per-task 1
#SBATCH --mem 30g
#SBATCH --job-name=summary
#SBATCH --account=kitzmanj99
#SBATCH --mail-user tovar@umich.edu
#SBATCH --mail-type ALL

Rscript bc_summary.R
