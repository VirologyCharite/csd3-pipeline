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
trimmed=$task.trimmed.fastq.gz

log=$logDir/$task.log

cat $fastq >> $trimmed
cat $fastq2 >> $trimmed
cat $singletons >> $trimmed

bwaDatabaseRoot="$root/share/bwa-indices"
bwaDatabaseNames="45srRNA"
outUncompressed=$task.rrna.out
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
function rrna()
{
	local sam=$task.sam
	local bam=$task.bam
    local sortedbam=$task.sorted.bam
    local coveragedepth=$task.coveragedepth
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

        # Convert sam file to bam file, sort, index.
        samtools view -S -b $sam > $bam
        samtools sort $bam > $sortedbam
        samtools index $sortedbam

        # Extract mapped and unmapped from samfile.
        samtools fastq -f 4 $sam > $task.unmapped
        samtools fastq -F 4 $sam > $task.mapped

        # Try sam-coverage-depth.py
        sam-coverage-depth.py $sortedbam > $coveragedepth

        # Calculate percentage mapped.
        rrna.py --mappedFile $task.mapped --unmappedFile $task.unmapped \
                --outFile $outUncompressed --coverageDepth $coveragedepth
    done
}

if [ $SP_SIMULATE = "1" ]
then
    echo "  This is a simulation." >> $log
else
    echo "  This is not a simulation." >> $log
    if [ $SP_SKIP = "1" ]
    then
        echo "  rRna analysis is being skipped on this run." >> $log
        skip
    elif [ -f $out ]
    then
        if [ $SP_FORCE = "1" ]
        then
            echo "  Pre-existing output file $out exists, but --force was used. Overwriting." >> $log
            rrna
        else
            echo "  Will not overwrite pre-existing output file $out. Use --force to make me." >> $log
        fi
    else
        echo "  Pre-existing output file $out does not exist. Doing rRna analysis." >> $log
        rrna
    fi
fi

logStepStop $log