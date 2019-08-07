#!/bin/bash

set -Eeuo pipefail

. ../common.sh

task=$1

fastqContigs=../007-flash/out.extendedFrags.fastq.gz
fastq1=../007-flash/out.notCombined_1.fastq.gz
fastq2=../007-flash/out.notCombined_2.fastq.gz

log=$logDir/$task.log
outUncompressed=$task-contigs.fasta
out=$outUncompressed.gz
outDir=spades.out

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq1 $log
checkFastq $fastq2 $log

function skip()
{
    if [ ! -f $out ]
    then
        cat $fastqContigs $fastq1 $fastq2 > $out
    fi
}

function doSpades()
{
    # Remove the output file and any other pre-existing spades output files
    # before doing anything, in case we fail for some reason.
    rm -f -r $out $outUncompressed $outDir

    spades.py -o $outDir -s $fastqContigs -1 $fastq1 -2 $fastq2 --threads $(nproc --all)

    mv $outDir/contigs.fasta $outUncompressed
    gzip $outUncompressed
}

if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  Spades is being skipped on this run." >> $log
        skip
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            doSpades
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Running flash." >> $log
        doSpades
    fi
fi

logStepStop $log
