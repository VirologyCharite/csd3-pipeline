#!/bin/bash

set -Eeuo pipefail

. ../common.sh

task=$1
task2=$(mateFile $task)

log=$logDir/sbatch.log

# NOTE!! The following must have the identical value set and used in trim.sh
out=$task.trim.fastq.gz
out2=$task2.trim.fastq.gz

echo "$(basename $(pwd)) sbatch.sh running at $(date)" >> $log
echo "  Task is $task" >> $log
echo "  Dependencies are $SP_DEPENDENCY_ARG" >> $log

if [ -f $out -a -f $out2 ]
then
    if [ "$SP_FORCE" = "1" -a "$SP_SKIP" = "0" ]
    then
        schedule=1
        echo "  Output files $out and $out2 already exist, but SP_FORCE is 1. Will run." >> $log
    else
        # The output file already exists and we're not using --force, so
        # there's no need to do anything. Just pass along our task name to the
        # next pipeline step.
        schedule=0
        echo "  Output files $out and $out2 already exist and SP_FORCE is 0. Nothing to do." >> $log
    fi
else
    schedule=1
    echo "  Output files $out and $out2 do not both exist. Will run." >> $log
fi

if [ $schedule -eq 1 ]
then
    if [ "$SP_SIMULATE" = "1" -o "$SP_SKIP" = "1" ]
    then
        exclusive=
        echo "  Simulating or skipping. Not requesting exclusive node. No way to skip this step." >> $log
    else
        # No need to get an exclusive machine. On a busy SLURM system it's
        # faster to just get one CPU and do it that way.
        exclusive=
        echo "  Not simulating or skipping. Not requesting exclusive node." >> $log
    fi

    jobid=$(sbatch -n 1 $exclusive $SP_DEPENDENCY_ARG $SP_NICE_ARG submit.sh $task | cut -f4 -d' ')
    echo "TASK: $task $jobid"
    echo "  Job id is $jobid" >> $log
else
    echo "TASK: $task"
fi

echo >> $log
