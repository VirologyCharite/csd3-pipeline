#!/bin/bash

set -Eeuo pipefail

. ../common.sh

case $# in
    0) task=$(basename ../005-trim/*_R1_*.trim.fastq.gz | cut -f1 -d.);;
    1) task=$1;;
    *) echo "$(basename $0): Unexpectedly called with args $@" >> $log; exit 1;;
esac
          
task2=$(mateFile $task)

fastq=../005-trim/$task.trim.fastq.gz
fastq2=../005-trim/$task2.trim.fastq.gz

log=$logDir/$task.log
out=$task-consensus.fasta

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq $log

function hcov()
{
    # Remove the output file and any other pre-existing hcov output files
    # before doing anything, in case we fail for some reason.
    rm -f $out $task.bam $task.vcf.gz tmp $task-reference-consensus-comparison.txt
    mkdir tmp

    echo "  run-bowtie2.py started at $(date)." >> $log
    run-bowtie2.py \
        --reference $hcovReference \
        --callHaplotypesGATK --out $task.bam --markDuplicatesGATK \
        --vcfFile $task.vcf.gz --fastq1 $fastq --fastq2 $fastq2 \
        --removeDuplicates --tempdir tmp --verbose --log 2>> $log
    echo "  run-bowtie2.py stopped at $(date)." >> $log

    echo "  make-consensus.py started at $(date)." >> $log
    make-consensus.py --reference $hcovReference \
        --id "$task-consensus" \
        --vcfFile $task.vcf.gz --log > $out 2>> $log
    echo "  make-consensus.py stopped at $(date)." >> $log

    echo "  compare consensuses started at $(date)." >> $log
    cat $out $hcovReference |
        compare-sequences.py --align --showDiffs --aligner mafft > \
        $task-reference-consensus-comparison.txt 2>> $log
    echo "  compare consensuses stopped at $(date)." >> $log

    rm -r tmp
}

if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  HCov is being skipped on this run." >> $log
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            hcov
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Running hcov." >> $log
        hcov
    fi
fi

logStepStop $log
