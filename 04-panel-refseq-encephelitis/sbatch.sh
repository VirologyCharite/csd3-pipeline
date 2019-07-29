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

if [ "$SP_FORCE" = "0" -a -f $out ]
then
    # The output file already exists and we're not using --force, so
    # there's no need to do anything. Just pass along our task name to the
    # next pipeline step.
    echo "  Ouput file $out already exists and SP_FORCE is 0. Nothing to do." >> $log
    echo "TASK: panel"
else
    jobid=$(sbatch -n 1 $SP_DEPENDENCY_ARG $SP_NICE_ARG submit.sh $task | cut -f4 -d' ')
    echo "TASK: panel $jobid"
    echo "  Job id is $jobid" >> $log
fi

echo >> $log
