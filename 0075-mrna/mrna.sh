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

fastq=../007-flash/$task.fastq.gz

log=$logDir/$task.log

bwaDatabaseRoot="$root/share/bwa-indices"
bwaDatabaseNames="21-human-HK-transcripts"
outUncompressed=$task.mrna.out
out=$outUncompressed.gz

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq $log

function skip()
{
    # Copy our input FASTQ to our output unchanged.
    cp $fastq $out
}

# Could delete the loops - there is only one database here!
function mrna()
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
    done
}

if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  mRna analysis is being skipped on this run." >> $log
        skip
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            mrna
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Doing mRna analysis." >> $log
        mrna
    fi
fi

logStepStop $log