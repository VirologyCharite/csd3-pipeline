#!/bin/bash

set -Eeuo pipefail

top=$(/bin/pwd)
zipbase=$(basename $top)-hcov

tmpdir=$(mktemp -d)
mkdir $tmpdir/$zipbase

for i in [DW]_*/pipelines/standard/006-hcov
do
    sample=$(echo $i | cut -f1 -d/)

    # Check to see if there are any BAM files in the 006-hcov directory,
    # and if so add them to the dir that we will zip up.
    if ls $i/*.bam >/dev/null 2>&1
    then
        mkdir $tmpdir/$zipbase/$sample
        cp $i/*.{bam,vcf}* $i/*.txt $i/*.fasta $tmpdir/$zipbase/$sample
    fi
done

cd $tmpdir
zip -r $top/$zipbase.zip .
rm -r $tmpdir
