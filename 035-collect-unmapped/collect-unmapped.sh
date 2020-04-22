#!/bin/bash

set -Eeuo pipefail

. ../common.sh

case $# in
    0) task=$(taskName);;
    1) task=$1;;
    *) echo "  $(basename $0): called with args '$@'" >&2
       echo "  Usage: $(basename $0) [task]" >&2
       exit 1;;
esac

out=$task.fastq.gz
log=$logDir/$task.log
logStepStart $log
logTaskToSlurmOutput $task $log

function collectUnmapped()
{
    if [ $collectUnmapped -ne 1 ]
    then
        echo "  We are not collecting unmapped reads. Taking no action and exiting with status 0." >> $log
        logStepStop $log
        exit 0
    fi

    # Remove the pre-existing output file before doing anything, in case
    # we fail for some reason.
    rm -f $out

    echo "  Collecting unmapped reads started at $(date)." >> $log

    allFastq=
    missing=0

    for dir in 03-diamond-civ-dna 03-diamond-civ-dna-large 03-diamond-civ-rna
    do
        fastq=../$dir/$task-unmapped.fastq.gz
        if [ -f $fastq ]
        then
            allFastq="$allFastq $fastq"
        else
            echo "  Required FASTQ file '$fastq' not found." >> $log
            missing=1
        fi
    done

    test $missing -eq 0 || {
        logStepStop $log
        exit 1
    }

    cat $allFastq | gunzip | filter-fasta.py --removeDuplicatesById --quiet --fastq | gzip > $out

    echo "  Collecting unmapped reads stopped at $(date)." >> $log
}

if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  Collection of unmapped reads is being skipped on this run." >> $log
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            collectUnmapped
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Running collectUnmapped." >> $log
        collectUnmapped
    fi
fi

logStepStop $log
