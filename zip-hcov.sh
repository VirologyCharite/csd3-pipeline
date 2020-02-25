#!/bin/bash

set -Eeuo pipefail

tmpdir=$(mktemp -d)
here=$(/bin/pwd)
zipbase=$(basename $here)-hcov

mkdir $tmpdir/$zipbase

for i in [DW]_*/pipelines/standard/006-hcov
do
    sample=$(echo $i | cut -f1 -d/)
    mkdir $tmpdir/$zipbase/$sample
    cp $i/*.{bam,vcf}* $i/*-consensus.fasta $i/*.txt $tmpdir/$zipbase/$sample
done

cd $tmpdir
zip -r $here/$zipbase.zip .
rm -r $tmpdir
