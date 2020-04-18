#!/bin/bash

set -Eeuo pipefail

. ../common.sh

bt2IndexArgs=

case $# in
    0)
        # No args. Figure out the task name.
        task=$(basename ../005-trim/*_R1_*.trim.fastq.gz | cut -f1 -d.)
        log=$logDir/$task.log
        ;;

    1)
        task=$1
        log=$logDir/$task.log
        ;;

    *)
        echo "  $(basename $0): called with args $@" >> $log
        echo "  Usage: $(basename $0) [task]" >> $log
        exit 1
        ;;
esac

# Log must have been set in the case statement above. If not, this will
# fail due to the set -u.
echo $log > /dev/null

out=$task.fastq.gz

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

    echo "  collecting unmapped reads started at $(date)." >> $log

    cat ../03-diamond-civ-dna/$task-unmapped.fastq.gz \
        ../03-diamond-civ-dna-large/$task-unmapped.fastq.gz \
        ../03-diamond-civ-rna/$task-unmapped.fastq.gz | gunzip |
        filter-fasta.py --removeDuplicatesById --quiet --fastq | gzip > $out

    echo "  collecting unmapped reads stopped at $(date)." >> $log
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
