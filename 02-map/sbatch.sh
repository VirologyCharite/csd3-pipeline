#!/bin/bash

set -Eeuo pipefail

. ../common.sh

task=$1
log=$logDir/sbatch.log
# The following must have the identical value as is set in map.sh
out=$task-unmapped.fastq.gz

echo "$(basename $(pwd)) sbatch.sh running at $(date)" >> $log
echo "  Task is $task" >> $log
echo "  Dependencies are $SP_DEPENDENCY_ARG" >> $log

if [ -f $out ]
then
    if [ "$SP_FORCE" = "1" -a "$SP_SKIP" = "0" -a "$SP_SIMULATE" = "0" ]
    then
        schedule=1
        echo "  Output file $out already exists, but SP_FORCE is 1." >> $log
    else
        # The output file already exists and we're not using --force, so
        # there's no need to do anything. Just pass along our task name to the
        # next pipeline step.
        schedule=0
        echo "  Output file $out already exists and SP_FORCE is 0. Nothing to do." >> $log
    fi
else
    schedule=1
    echo "  Output file $out does not exist. Will run." >> $log
fi

if [ $schedule -eq 1 ]
then
    if [ "$SP_SIMULATE" = "1" -o "$SP_SKIP" = "1" ]
    then
        echo "  Simulating or skipping." >> $log
        ./map.sh $task
        echo "TASK: $task"
    else
        # Request an exclusive machine because map.sh will tell bwa and
        # samtools to use all threads.
        exclusive=--exclusive
        echo "  Not simulating or skipping. Requesting exclusive node." >> $log
        jobid=$(sbatch -n 1 $exclusive $SP_DEPENDENCY_ARG $SP_NICE_ARG submit.sh $task | cut -f4 -d' ')
        echo "TASK: $task $jobid"
        echo "  Job id is $jobid" >> $log
    fi
else
    echo "TASK: $task"
fi

echo >> $log
