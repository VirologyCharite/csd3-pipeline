#!/bin/bash -e

#SBATCH -J stats
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=00:05:00

task=$1

srun -n 1 stats.sh $task
