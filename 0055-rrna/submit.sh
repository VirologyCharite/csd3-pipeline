#!/bin/bash

#SBATCH -J rrna-civ
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=00:30:00

task=$1

srun -n 1 rrna.sh $task
