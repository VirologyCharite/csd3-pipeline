#!/bin/bash -e

#SBATCH -J trim-civ
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=01:30:00

task=$1

srun -n 1 trim.sh $task
