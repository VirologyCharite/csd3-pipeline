#!/bin/bash

set -Eeuo pipefail

. ../common.sh

# Note that the command line will contain multiple arguments. One for each
# FASTQ that was originally processed for this sample.
task="$@"

log=$logDir/sbatch.log
# The following must have the identical value as is set in panel.sh
out=summary-virus

echo "$(basename $(pwd)) sbatch.sh running at $(date)" >> $log
echo "  Task is $task" >> $log
echo "  Dependencies are $SP_DEPENDENCY_ARG" >> $log

if [ $sampleType != hcov ]
then
    echo "  This is not an hcov sample. Taking no action." >> $log
    schedule=0
elif [ -f $out ]
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
        ./panel.sh "$@"
        echo "TASK: $task"
    else
        # Try setting exclusive=--exclusive if the panel runs out of memory.
        exclusive=--exclusive
        echo "  Not simulating or skipping. Not requesting exclusive node." >> $log
        jobid=$(sbatch -n 1 $exclusive $SP_DEPENDENCY_ARG $SP_NICE_ARG submit.sh $task | cut -f4 -d' ')
        echo "TASK: panel $jobid"
        echo "  Job id is $jobid" >> $log
    fi
else
    echo "TASK: panel"
fi

echo >> $log
