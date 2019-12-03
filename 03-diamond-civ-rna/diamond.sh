#!/bin/bash -e

. ../common.sh

task=$1
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
    echo "  DIAMOND RNA blastx started at $(date)" >> $log
    diamond blastx \
        --threads $(($(nproc --all) - 2)) \
        --query $fastq \
        --db $rnaDiamondDB \
        --outfmt 6 qtitle stitle bitscore evalue qframe qseq qstart qend sseq sstart send slen btop nident pident positive ppos |
    convert-diamond-to-json.py | bzip2 > $out
    echo "  DIAMOND RNA blastx stopped at $(date)" >> $log
}


if [ $SP_SIMULATE = "0" ]
then
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  DIAMOND RNA civ is being skipped on this run." >> $log
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
