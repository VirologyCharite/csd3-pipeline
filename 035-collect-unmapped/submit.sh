#!/bin/bash

#SBATCH -J collect-unmapped
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=00:45:00

task=$1

srun -n 1 collect-unmapped.sh $task
