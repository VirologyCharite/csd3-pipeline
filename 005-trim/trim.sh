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

task2=$(mateFile $task)

fastq=$dataDir/$task.fastq.gz
fastq2=$dataDir/$task2.fastq.gz

log=$logDir/$task.log
out=$task.trim.fastq.gz
out2=$task2.trim.fastq.gz
singletons=$task.singletons.fastq.gz

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq $log

function doTrim()
{
    # Remove the output files before doing anything, in case we fail for
    # some reason (e.g., a bad option name or AdapterRemoval not found).
    rm -f $out $out2

    AdapterRemoval --file1 $fastq --file2 $fastq2 --output1 $out --output2 $out2 \
                   --threads $(nproc --all) \
                   --singleton $singletons --gzip --trimns --minlength 30 \
                   --trimqualities --minquality 2 --settings $task.settings \
                   --discarded /dev/null > $task.out 2>&1
}

if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  Trimming is being skipped on this run." >> $log
    elif [ -f $out -a -f $out2 ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output files $out and $out2 exist, but --force was used. Overwriting." >> $log
            doTrim
        else
            echo "  Will not overwrite pre-existing output files $out and $out2. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output files $out and $out2 do not exist. Trimming." >> $log
        doTrim
    fi
fi

logStepStop $log
