#!/bin/bash -e

#SBATCH -J spades-civ
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=02:00:00

task=$1

srun -n 1 spades.sh $task
