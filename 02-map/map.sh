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

log=$logDir/$task.log
bwaDatabaseRoot="$root/share/bwa-indices"
# The following databases are the human genome, human mRNA, human
# mitochondrion, ribosomal RNA, long non-coding (human) RNA, the three
# Norway luteo-like contaminant sequences sent to Terry by Julia on
# 2019-08-21, and the OKIAV680 (picornavirus) contaminant sequence.
bwaDatabaseNames="homo-sapiens 20190806-GRCh38_latest_rna human-mitochondrion rRNA lncRNA luteo OKIAV680"
fastq=../007-flash/$task.fastq.gz
outUncompressed=$task-unmapped.fastq
out=$outUncompressed.gz

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq $log

function skip()
{
    # Copy our input FASTQ to our output unchanged.
    cp $fastq $out
}

function map()
{
    local sam=$task.sam
    nproc=$(nproc --all)

    rmFileAndLink $out $outUncompressed $sam

    # Fail quickly if there is a missing database.
    for bwaDatabaseName in $bwaDatabaseNames
    do
        bwaDatabase=$bwaDatabaseRoot/$bwaDatabaseName.bwt

        if [ ! -f $bwaDatabase ]
        then
            echo "  BWA database file '$bwaDatabase' does not exist." >> $log
            logStepStop $log
            exit 1
        fi
    done

    # Now loop again and do the actual mapping work.
    for bwaDatabaseName in $bwaDatabaseNames
    do
        bwaDatabase=$bwaDatabaseRoot/$bwaDatabaseName

        # Map FASTQ to database.
        echo "  bwa mem (against $bwaDatabaseName) started at $(date)" >> $log
        bwa mem -t $nproc $bwaDatabase $fastq > $sam
        echo "  bwa mem (against $bwaDatabaseName) stopped at $(date)" >> $log

        samtools quickcheck $sam

        # Extract the unmapped reads.
        echo "  extract unmapped reads started at $(date)" >> $log
        samtools fastq --threads $(nproc) -f 4 $sam > $outUncompressed
        rm $sam
        echo "  extract unmapped reads stopped at $(date)" >> $log

        # The following only has an effect on the first time through the
        # loop (because initially the fastq variable is set to
        # ../007-flash/$task.fastq.gz). Be careful, this loop is slightly
        # non-obvious. First time through the loop we read the ../007-flash
        # FASTQ file and write ./$task.fastq. Thereafter we repeatedly read
        # and write ./$task.fastq (due to the assignment in the next line).
        fastq=$outUncompressed
    done

    echo "  compressing reads started at $(date)" >> $log
    gzip $outUncompressed
    echo "  compressing reads stopped at $(date)" >> $log
}


if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  Mapping is being skipped on this run." >> $log
        skip
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            map
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Mapping." >> $log
        map
    fi
fi

logStepStop $log
