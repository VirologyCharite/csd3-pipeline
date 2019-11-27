#!/bin/bash -e

#SBATCH -J dedup-civ
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=05:00:00

task=$1

srun -n 1 dedup.sh $task
