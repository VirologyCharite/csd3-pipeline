#!/bin/bash -e

#SBATCH -J panel-civ-rna-hcov
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=2:00:00

srun -n 1 panel.sh "$@"
