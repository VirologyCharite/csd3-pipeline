#!/bin/bash

set -Eeuo pipefail

. ../common.sh

case $# in
    0)
        # No args. Figure out the task name and look for the reference in
        # reference.fasta.
        task=$(basename ../005-trim/*_R1_*.trim.fastq.gz | cut -f1 -d.)
        log=$logDir/$task.log

        if [ -f reference.fasta ]
        then
            hcovReference=reference.fasta
        else
            echo "$(basename $0) called with no reference and reference.fasta is not present." >> $log
            echo "Usage: $(basename $0) [task] [reference-file.fasta]" >> $log
            exit 1
        fi
        ;;

    1)
        # If the arg is a file, use it as the reference and figure out the
        # task. Else use it as the task and look for the reference in
        # reference.fasta.
        if [ -f $1 ]
        then
            hcovReference=$1
            task=$(basename ../005-trim/*_R1_*.trim.fastq.gz | cut -f1 -d.)
        else
            task=$1
            log=$logDir/$task.log

            if [ -f reference.fasta ]
            then
                hcovReference=reference.fasta
            else
                echo "$(basename $0) called with no reference and reference.fasta is not present." >> $log
                echo "Usage: $(basename $0) [task] [reference-file.fasta]" >> $log
                exit 1
            fi
        fi
        ;;

    2)
        # Assume $1 is the task, $2 is the reference, and check that the
        # latter exists (as a file).
        task=$1
        log=$logDir/$task.log

        if [ -f $2 ]
        then
            hcovReference=$2
        else
            echo "$(basename $0) called with task ($task) and reference ($2) but reference is not a file." >> $log
            exit 1
        fi
        ;;

    *)
        echo "$(basename $0): called with args $@" >> $log
        echo "Usage: $(basename $0) [task] [reference-file.fasta]" >> $log
        exit 1
        ;;
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
    rm -f $out $task.bam $task.bam.bai $task.vcf.gz $task.vcf.gz.tbi
    rm -f $task-reference-consensus-comparison.txt $task-coverage.txt
    rm -f $task-read-count.txt $task-alignment.fasta
    rm -fr tmp
    mkdir tmp

    echo "  run-bowtie2.py started at $(date)." >> $log
    run-bowtie2.py \
        --reference $hcovReference \
        --callHaplotypesGATK --out $task.bam --markDuplicatesGATK \
        --vcfFile $task.vcf.gz --fastq1 $fastq --fastq2 $fastq2 \
        --bowtie2Args '--no-unal --local' \
        --removeDuplicates --tempdir tmp --verbose --log 2>> $log
    echo "  run-bowtie2.py stopped at $(date)." >> $log

    echo "  make-consensus.py started at $(date)." >> $log
    make-consensus.py --reference $hcovReference \
        --id "$task-consensus" \
        --vcfFile $task.vcf.gz --log > $out 2>> $log
    echo "  make-consensus.py stopped at $(date)." >> $log

    echo "  compare consensuses started at $(date)." >> $log
    cat $out $hcovReference |
        compare-sequences.py --align --showDiffs --aligner mafft \
        --alignmentFile $task-alignment.fasta > \
        $task-reference-consensus-comparison.txt 2>> $log
    echo "  compare consensuses stopped at $(date)." >> $log

    echo "  SAM coverage depth started at $(date)." >> $log
    sam-coverage-depth.py $task.bam > $task-coverage.txt 2>> $log
    echo "  SAM coverage depth stopped at $(date)." >> $log

    echo "  SAM read count started at $(date)." >> $log
    samtools view -c $task.bam > $task-read-count.txt 2>> $log
    echo "  SAM read cound stopped at $(date)." >> $log

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
