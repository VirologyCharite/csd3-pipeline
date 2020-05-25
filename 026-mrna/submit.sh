#!/bin/bash

#SBATCH -J mrna-civ
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=00:30:00

task=$1

srun -n 1 mrna.sh $task
