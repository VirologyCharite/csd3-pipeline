#!/bin/bash

set -Eeuo pipefail

. ../common.sh

bt2IndexArgs=

case $# in
    0)
        # No args. Figure out the task name and look for the reference in
        # reference.fasta.
        task=$(taskName)
        log=$logDir/$task.log

        if [ -f reference.fasta ]
        then
            hcovReference=reference.fasta
        else
            echo "  $(basename $0) called with no reference and reference.fasta is not present." >> $log
            echo "  Using default $hcovReference as a reference." >> $log
            bt2IndexArgs="--index $hcovReferenceIndex"
        fi
        ;;

    1)
        # If the arg is a file, use it as the reference and figure out the
        # task. Else use it as the task name and look for the reference in
        # reference.fasta.
        if [ -f $1 ]
        then
            hcovReference=$1
            task=$(basename ../005-trim/*_R1_*.trim.fastq.gz | cut -f1 -d.)
            log=$logDir/$task.log
        else
            task=$1
            log=$logDir/$task.log

            # If there is a reference.fasta file here, use it as a reference, else
            # we'll use the pre-set value in $hcovReference set in ../common.sh
            if [ -f reference.fasta ]
            then
                echo "  Using local 'reference.fasta' as a reference." >> $log
                hcovReference=reference.fasta
            else
                echo "  Using default $hcovReference as a reference." >> $log
                bt2IndexArgs="--index $hcovReferenceIndex"
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
            echo "  $(basename $0) called with task ($task) and reference ($2) but reference is not a file." >> $log
            exit 1
        fi
        ;;

    *)
        echo "  $(basename $0): called with args $@" >> $log
        echo "  Usage: $(basename $0) [task] [reference-file.fasta]" >> $log
        exit 1
        ;;
esac

task2=$(mateFile $task)

fastq=../005-trim/$task.trim.fastq.gz
fastq2=../005-trim/$task2.trim.fastq.gz

# Log must have been set in the case statement above. If not, this will
# fail due to the set -u.
echo $log > /dev/null

out=$task.done

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq $log

function hcov()
{
    if [ $sampleType != hcov ]
    then
        echo "  This is not an hcov sample. Taking no action and exiting with status 0." >> $log
        logStepStop $log
        exit 0
    fi

    # Remove any pre-existing hcov output files before doing anything, in
    # case we fail for some reason.
    rm -f $out *.bam *.bam.bai *.vcf.gz *.vcf.gz.tbi
    rm -f *-consensus.fasta *-reference-consensus-comparison.txt *-coverage.txt
    rm -f *-read-count.txt *-alignment.fasta
    rm -fr tmp
    mkdir tmp

    # See if we can find a CSpecVir sample consensus to compare the
    # consensus we just made to. Watch out for spaces in sample id.
    case=$(caseName)
    sampleNum=$(sampleNumber)
    sampleIdNoSpaces="$(sample-id-for-case.py --sampleNumber $sampleNum $case | tr -d ' ')"
    sampleIdNoSpacesNoPassage="$(sample-id-for-case.py --sampleNumber $sampleNum $case | tr -d ' ' | sed -r -e 's/p[0-9]+$//')"
    sampleIdWithSpaces="$(sample-id-for-case.py --sampleNumber $sampleNum $case)"

    case "$sampleIdNoSpaces" in
        CSpecVir*)
            prefix="$(echo $task | cut -f1-7 -d_)-$sampleIdNoSpaces"
        ;;

        *)
            prefix="$(echo $task | cut -f1-7 -d_)"
        ;;
    esac

    echo "  Reference id: $(head -n 1 < $hcovReference | cut -c2-)" >> $log
    hcovReferenceId="$(head -n 1 < $hcovReference | cut -c2- | cut -f1 -d' ')"

    echo "  run-bowtie2.py started at $(date)." >> $log
    run-bowtie2.py \
        $bt2IndexArgs \
        --reference $hcovReference \
        --callHaplotypesBcftools --out $prefix.bam --markDuplicatesGATK \
        --vcfFile $prefix.vcf.gz --fastq1 $fastq --fastq2 $fastq2 \
        --bowtie2Args '--no-unal --local' \
        --removeDuplicates --tempdir tmp --verbose --log 2>> $log
    echo "  run-bowtie2.py stopped at $(date)." >> $log

    echo "  make-consensus.py started at $(date)." >> $log
    make-consensus.py --reference $hcovReference \
        --id "$prefix-consensus" --maskLowCoverage 3 --bam $prefix.bam \
        --vcfFile $prefix.vcf.gz --log > $prefix-consensus.fasta 2>> $log
    echo "  make-consensus.py stopped at $(date)." >> $log

    echo "  compare consensuses started at $(date)." >> $log
    cat $prefix-consensus.fasta $hcovReference |
        compare-sequences.py --align --showDiffs --showAmbiguous \
        --aligner mafft --alignmentFile $prefix-alignment.fasta > \
        $prefix-reference-consensus-comparison.txt 2>> $log
    echo "  compare consensuses stopped at $(date)." >> $log

    # This is too slow to always run by default!
    #
    # echo "  SAM coverage depth started at $(date)." >> $log
    # sam-coverage-depth.py $prefix.bam > $prefix-coverage.txt 2>> $log
    # echo "  SAM coverage depth stopped at $(date)." >> $log

    echo "  SAM read count started at $(date)." >> $log
    samtools view -c $prefix.bam > $prefix-read-count.txt 2>> $log
    echo "  SAM read count stopped at $(date)." >> $log

    case "$sampleIdNoSpaces" in
        CSpecVir*)
            # Look for all CSpecVir sequences to compare the consensus we
            # just made to.
            shopt -s nullglob

            for sequence in $sequencesDir/$sampleIdNoSpacesNoPassage*.fasta
            do
                base=$(basename $sequence | sed -e 's/\.fasta//')

                echo "  compare consensuses against $base started at $(date)." >> $log
                cat $prefix-consensus.fasta $sequence |
                    compare-sequences.py --align --showDiffs --showAmbiguous \
                    --aligner mafft --alignmentFile $prefix-$base-alignment.fasta > \
                    $prefix-$base-reference-consensus-comparison.txt 2>> $log
                echo "  compare consensuses against $base stopped at $(date)." >> $log
            done

            shopt -u nullglob
        ;;

        *)
            echo "Case $case (sample id '$sampleIdWithSpaces') does not correspond to a CSpecVir sample." >> $log
        ;;
    esac

    rm -r tmp
    touch $out
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
