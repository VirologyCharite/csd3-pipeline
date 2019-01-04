#!/bin/bash -e

#SBATCH -J stop
#SBATCH -A ACORG-SL2-CPU
#SBATCH -o slurm-%A.out
#SBATCH -p skylake
#SBATCH --time=00:05:00

srun -n 1 stop.sh
