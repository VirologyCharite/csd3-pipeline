#!/bin/bash

set -Eeuo pipefail

. ../common.sh

task=$1
log=$logDir/$task.log
bwadb=$root/share/bwa-indices/homo-sapiens
fastq=../007-flash/$task.fastq.gz
out=$task-unmapped.fastq.gz

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq $log

if [ ! -f $bwadb.bwt ]
then
    echo "  BWA database file '$bwadb.bwt' does not exist." >> $log
    logStepStop $log
    exit 1
fi

function skip()
{
    # Copy our input FASTQ to our output unchanged.
    cp $fastq $out
}

function map()
{
    local sam=$task.sam
    local bam=$task.bam
    nproc=$(nproc --all)

    rmFileAndLink $out $sam $bam

    # Map FASTQ to human genome.
    echo "  bwa mem started at $(date)" >> $log
    bwa mem -t $nproc $bwadb $fastq > $sam
    echo "  bwa mem stopped at $(date)" >> $log

    # Convert SAM to BAM.
    echo "  samtools sam -> bam conversion started at $(date)" >> $log
    samtools view --threads $nproc -bS $sam > $bam
    rm $sam
    echo "  samtools sam -> bam conversion stopped at $(date)" >> $log

    # Extract the unmapped reads. Leave one core for the gzip.
    echo "  extract unmapped reads started at $(date)" >> $log
    samtools fastq --threads $((nproc - 1)) -f 4 $bam | gzip > $out
    # Leave the BAM file around.
    # rm $bam
    echo "  extract unmapped reads stopped at $(date)" >> $log
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
