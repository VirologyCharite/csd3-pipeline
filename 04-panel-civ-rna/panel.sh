#!/bin/bash

set -Eeuo pipefail

. ../common.sh

# The log file is the top-level sample log file, seeing as this step is a
# 'collect' step that is only run once.
log=$sampleLogFile
out=summary-virus

case $# in
    0) tasks=$(taskName);;
    *) tasks="$@";;
esac

logStepStart $log
logTaskToSlurmOutput panel $log

function skip()
{
    # We're being skipped. Make an empty output file, if one doesn't
    # already exist. There's nothing much else we can do and there's no
    # later steps to worry about.
    [ -f $out ] || touch $out
}

function panel()
{
    if [ $sampleType = hcov ]
    then
        echo "  This is an hcov sample. Taking no action and exiting with status 0." >> $log
        logStepStop $log
        exit 0
    fi

    echo "  alignment-panel-civ.py started at $(date)" >> $log

    allJSON=
    allFASTQ=
    for task in $tasks
    do
        echo "  Task (i.e., sequencing run) $task" >> $log

        JSON=../03-diamond-civ-rna/$task.json.bz2
        test -f $JSON || {
            echo "JSON file $JSON does not exist." >> $log
            exit 1
        }

        FASTQ=../025-dedup/$task.fastq.gz
        test -f $FASTQ || {
            echo "FASTQ file $FASTQ does not exist." >> $log
            exit 1
        }

        allJSON="$allJSON $JSON"
        allFASTQ="$allFASTQ $FASTQ"
    done

    local outputDir=out

    # Remove the output directory because it could be a pre-existing
    # symlink to (slow) cold storage. We'll write to fast disk and sometime
    # later we can archive it if we want. Make sure to remove the
    # destination of the link, if it's a link. Use -f in the rm because
    # although the output file might be a symlink the destination file may
    # be in cold storage and therefore not visible from the compute node.
    if [ -L $outputDir ]
    then
        rm -fr $(readlink $outputDir)
    fi
    rm -fr $outputDir summary-proteins $out

    alignment-panel-civ.py \
      --proteinGenomeDatabase $rnaProteinGenomeDB \
      --json $allJSON \
      --fastq $allFASTQ \
      --matcher diamond \
      --outputDir $outputDir \
      --maxTitles 150 \
      --minMatchingReads $minMatchingReads \
      --percentagePositiveCutoff $percentagePositiveCutoff \
      --blacklistFile $blacklistFile \
      --negativeTitleRegex phage > summary-proteins
    echo "  alignment-panel-civ.py stopped at $(date)" >> $log

    echo "  proteins-to-pathogens-civ.py started at $(date)" >> $log
    echo summary-proteins | \
        proteins-to-pathogens-civ.py \
            --proteinGenomeDatabase $rnaProteinGenomeDB \
            --taxonomyDatabase $taxonomyDB \
            > $out
    echo "  proteins-to-pathogens-civ.py stopped at $(date)" >> $log
}


if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  Panel civ is being skipped on this run." >> $log
        skip
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            panel
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Making panel." >> $log
        panel
    fi
fi

logStepStop $log
