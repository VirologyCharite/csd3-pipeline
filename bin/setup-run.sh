#!/bin/bash

set -Eeuo pipefail

# Script to be run at the top level of the Charite diagnostics tree. Give
# the name (usually YYMMDD) of run directories to set up.

case $# in
    0) echo "Usage: $(basename $0) dir1 [dir2...]"; exit 1;;
esac

TOP=$(/bin/pwd)
MAKEFILE=../csd3-pipeline/Makefile.toplevel

FASTQ_FILENAME_CHECKER=../bih-pipeline/bin/check-fastq-filenames.py

BIH_PIPELINE_DIR=../bih-pipeline

if [ -d $BIH_PIPELINE_DIR ]
then
    cd $BIH_PIPELINE_DIR
    git pull origin master
    cd $TOP
else
    echo "bih-pipeline directory '$BIH_PIPELINE_DIR' does not exist!" >&2
    exit 1
fi


for dir in "$@"
do
    echo "Processing $dir"

    if [ ! -d $dir ]
    then
        # Don't use mkdir -p because we're just trying to set up top-level
        # dirs and we'll make a link to ../csd3-pipeline/Makefile.toplevel
        # which won't exist if $dir has sub dirs.
        mkdir $dir
    fi

    cd $dir

    if [ ! -f $FASTQ_FILENAME_CHECKER ]
    then
        echo "In $(pwd), could not find $FASTQ_FILENAME_CHECKER" >&2
        exit 1
    fi

    if [ -f Makefile ]
    then
        echo "  Makefile already exists."
    else
        if [ -f $MAKEFILE ]
        then
            echo "  Making symbolic link to $MAKEFILE"
            ln -s $MAKEFILE Makefile
        else
            echo "In $(pwd), could not find $MAKEFILE" >&2
            exit 1
        fi
    fi

    # Check the names of all FASTQ files (if any) and move them into
    # sub-directories.
    first=1
    for fastq in [DW]_*.fastq.gz
    do
        if [ $first -eq 1 ]
        then
            # Test all FASTQ filenames. This will exit non-zero if any
            # filenames cannot be parsed properly (maybe that's too strict,
            # but let's see).
            first=0
            $FASTQ_FILENAME_CHECKER [DW]_*.fastq.gz
        fi

        subdir=$(echo $fastq | cut -f1-7 -d_)
        test -d $subdir || mkdir $subdir

        if [ -f $subdir/$fastq ]
        then
            echo "In $(pwd), FASTQ file $fastq is found both in this directory and in $subdir!" >&2
            exit 1
        else
            mv $fastq $subdir
        fi
    done

    cd $TOP
done
