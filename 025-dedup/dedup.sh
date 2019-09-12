#!/bin/bash

set -Eeuo pipefail

. ../common.sh

task=$1
log=$logDir/$task.log
fastq=../02-map/$task-unmapped.fastq.gz
outUncompressed=$task.fastq.gz

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq $log

function skip()
{
    # Link our input FASTQ to our output.
    test -f $out || ln -s $fastq $out
}

function dedup()
{
    rmFileAndLink $out

    # Remove duplicates by sequence (use MD5 sums of sequences to save RAM).
    echo "  removing duplicate reads by (MD5) sequence started at $(date)" >> $log
    gunzip -c < $fastq | \
    filter-fasta.py --fastq --removeDuplicates --removeDuplicatesUseMD5 | \
    gzip -c > $out
    echo "  removing duplicate reads by (MD5) sequence stopped at $(date)" >> $log
}


if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  De-duplication is being skipped on this run." >> $log
        skip
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            dedup
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Mapping." >> $log
        dedup
    fi
fi

logStepStop $log
