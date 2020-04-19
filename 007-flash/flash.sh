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

fastq=../005-trim/$task.trim.fastq.gz
fastq2=../005-trim/$task2.trim.fastq.gz
singletons=../005-trim/$task.singletons.fastq.gz

log=$logDir/$task.log
outUncompressed=$task.fastq
out=$outUncompressed.gz

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq $log

function doFlash()
{
    # Remove the output file and any other pre-existing flash output files
    # before doing anything, in case we fail for some reason.
    rm -f $out out.* flash.std{out,err}

    # The 300 in the below is actually the number of Illumina cycles (i.e.,
    # maximum read length). I set the maximum considered overlap to 300 for
    # flash because with a target fragment size of 500 (in Charite sample
    # preparation) using a lower number (like 275) causes flash to warn
    # that a high fraction of overlaps are longer than the max-overlap
    # number and so are not being fully considered as to whether they are
    # valid (for merging).
    echo "  Running flash at $(date)." >> $log
    flash --max-overlap 300 $fastq $fastq2 > flash.stdout 2> flash.stderr

    # Collect all the combined and uncombined reads together into
    # $outUncompressed. 
    echo "  Collecting all FASTQ into $outUncompressed at $(date)." >> $log
    mv out.extendedFrags.fastq $outUncompressed
    for i in 1 2
    do
        # Add a -1 and -2 to the read ids of the uncombined pairs so their
        # reads don't have identical ids. Note that we can't add a
        # character that is illegal in a query id in SAM because it will be
        # stripped out (e.g., by bwa) and cause problems downstream. So we
        # cannot add /1 and /2, for example. See section 1.4 of
        # https://samtools.github.io/hts-specs/SAMv1.pdf for the QNAME
        # regex template (currently [!-?A-~]{1,254}).
        echo "  Adding -$i to unmerged reads at $(date)." >> $log
        filter-fasta.py --quiet --fastq \
                        --idLambda 'lambda r: "-'$i' ".join(r.split(None, 1))' < \
                        out.notCombined_$i.fastq >> $outUncompressed
        rm out.notCombined_$i.fastq
    done

    echo "  Compressing combined FASTQ into $out at $(date)." >> $log
    gzip $outUncompressed

    # Add useful reads for which the mate pair was discarded by
    # AdapterRemoval to the fastq.gz output, if there are any such reads.
    test -f $singletons && cat $singletons >> $out
}

if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  Flash is being skipped on this run." >> $log
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            doFlash
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Running flash." >> $log
        doFlash
    fi
fi

logStepStop $log
