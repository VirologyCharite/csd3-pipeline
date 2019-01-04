#!/bin/bash

set -Eeuo pipefail

. ../common.sh

task=$1
log=$logDir/$task.log
out=$task.count

logStepStart $log
logTaskToSlurmOutput $task $log

function stats()
{
    # Remove the output file before doing anything, in case we fail for
    # some reason.
    rm -f $out

    # Get read count from output of the trim step.  AdapterRemoval prints
    # carriage returns in its output, which we first convert to newlines.
    tr '\r' '\n' <  ../005-trim/$task.out | tail -n 1 | cut -f5 -d ' ' | tr -d , > $out
}

if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  Stats is being skipped on this run." >> $log
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            stats
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Collecting stats." >> $log
        stats
    fi
fi

logStepStop $log
