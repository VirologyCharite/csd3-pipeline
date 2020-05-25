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
bwaDatabaseNames="yyy"
outUncompressed=$task.rrna.out
out=$outUncompressed.gz

logStepStart $log
logTaskToSlurmOutput $task $log
checkFastq $fastq $log

function rrna()
{
	local sam=$task.sam
    nproc=$(nproc --all)

    rmFileAndLink $out $outUncompressed $sam
}