#!/bin/bash -e

#SBATCH -J dmnd-okiav
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=05:00:00

task=$1

srun -n 1 diamond.sh $task
