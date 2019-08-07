#!/bin/bash

set -Eeuo pipefail

. ../common.sh

task=$1
log=$logDir/sbatch.log

# NOTE!! The following must have the identical value set and used in spades.sh
out=$task-contigs.fastq.gz


echo "$(basename $(pwd)) sbatch.sh running at $(date)" >> $log
echo "  Task is $task" >> $log
echo "  Dependencies are $SP_DEPENDENCY_ARG" >> $log

if [ -f $out ]
then
    if [ "$SP_FORCE" = "1" ]
    then
        schedule=1
        echo "  Ouput file $out already exists, but SP_FORCE is 1. Will run." >> $log
    else
        # The output file already exists and we're not using --force, so
        # there's no need to do anything. Just pass along our task name to the
        # next pipeline step.
        schedule=0
        echo "  Ouput file $out already exists and SP_FORCE is 0. Nothing to do." >> $log
    fi
else
    schedule=1
    echo "  Ouput file $out does not exist. Will run." >> $log
fi

if [ $schedule -eq 1 ]
then
    if [ "$SP_SIMULATE" = "1" -o "$SP_SKIP" = "1" ]
    then
        exclusive=
        echo "  Simulating or skipping. Not requesting exclusive node." >> $log
    else
        exclusive=--exclusive
        echo "  Not simulating or skipping. Requesting exclusive node." >> $log
    fi

    jobid=$(sbatch -n 1 $exclusive $SP_DEPENDENCY_ARG $SP_NICE_ARG submit.sh $task | cut -f4 -d' ')
    echo "TASK: $task $jobid"
    echo "  Job id is $jobid" >> $log
else
    echo "TASK: $task"
fi

echo >> $log
