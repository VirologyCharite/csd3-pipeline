#!/bin/bash

#SBATCH -J flash
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=00:15:00

task=$1

srun -n 1 flash.sh $task
