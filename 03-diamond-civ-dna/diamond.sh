#!/bin/bash -e

. ../common.sh

case $# in
    0) task=$(taskName);;
    1) task=$1;;
    *) echo "  $(basename $0): called with args '$@'" >&2
       echo "  Usage: $(basename $0) [task]" >&2
       exit 1;;
esac

log=$logDir/$task.log
fastq=../025-dedup/$task.fastq.gz
out=$task.json.bz2

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq $log

function skip()
{
    # Make it look like we ran and produced no output.
    echo "  Creating no-results output file due to skipping." >> $log
    bzip2 < header.json > $out
}

function run_diamond()
{
    if [ $collectUnmapped -eq 1 ]
    then
        echo "  We are collecting unmapped reads." >> $log
        unmappedArgs="--un $task-unmapped.fastq --unfmt fastq"
    else
        echo "  We are not collecting unmapped reads." >> $log
        unmappedArgs=
    fi

    echo "  DIAMOND DNA blastx started at $(date)" >> $log
    diamond blastx \
        --threads $(($(nproc --all) - 2)) \
        --query $fastq \
        --db $dnaDiamondDB \
        $unmappedArgs \
        --outfmt 6 qtitle stitle bitscore evalue qframe qseq qstart qend sseq sstart send slen btop nident pident positive ppos |
    convert-diamond-to-json.py | bzip2 > $out
    echo "  DIAMOND DNA blastx stopped at $(date)" >> $log

    if [ $collectUnmapped -eq 1 ]
    then
        echo "  Compressing unmapped reads started at $(date)." >> $log
        gzip $task-unmapped.fastq
        echo "  Compressing unmapped reads stopped at $(date)." >> $log
    fi
}


if [ $SP_SIMULATE = "0" ]
then
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  DIAMOND DNA civ is being skipped on this run." >> $log
        skip
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            run_diamond
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Mapping." >> $log
        run_diamond
    fi
else
    echo "  This is a simulation." >> $log
fi

logStepStop $log
