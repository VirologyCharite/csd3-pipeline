#!/bin/bash

set -Eeuo pipefail

# Script to be run at the top level of the Charite diagnostics tree. Give
# the name (usually YYMMDD) of run directories to set up.

case $# in
    0) echo "Usage: $(basename $0) dir1 [dir2...]"; exit 1;;
esac


simulate=0

while [ $# -gt 0 ]
do
    case "$1" in
        -n)
            simulate=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

function run()
{
    if test $simulate -eq 0
    then
        eval "$@"
    else
        echo "    $@"
    fi
}


TOP=$(/bin/pwd)
MAKEFILE=../csd3-pipeline/Makefile.toplevel

FASTQ_FILENAME_CHECKER=../bih-pipeline/bin/check-fastq-filenames.py

BIH_PIPELINE_DIR=bih-pipeline

if [ -d $BIH_PIPELINE_DIR ]
then
    run cd $BIH_PIPELINE_DIR
    run git pull origin master
    run cd $TOP
else
    echo "bih-pipeline directory '$BIH_PIPELINE_DIR' does not exist!" >&2
    exit 1
fi

# Set nullglob so the expansion of [DW]_* etc., results in nothing if no
# files exist (i.e., all have already been moved into their sub-directories.
shopt -s nullglob


for dir in "$@"
do
    echo "Processing $dir"

    if [ ! -d $dir ]
    then
        # Don't use mkdir -p because we're just trying to set up top-level
        # dirs and we'll make a link to ../csd3-pipeline/Makefile.toplevel
        # which won't exist if $dir has sub dirs.
        run mkdir $dir
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
            run ln -s $MAKEFILE Makefile
        else
            echo "In $(pwd), could not find $MAKEFILE" >&2
            exit 1
        fi
    fi

    # The following will result in fastqFiles being empty if there are no
    # FASTQ files due to the nullglob setting above.
    fastqFiles=[DW]_*.fastq.gz

    if [ -z "$fastqFiles" ]
    then
        echo "No FASTQ files were found in $(pwd)." >&2
    else
        # Check the names of all FASTQ files (if any) and move them into
        # sub-directories.

        # Test all FASTQ filenames. This will exit non-zero if any
        # filenames cannot be parsed properly (maybe that's too strict,
        # but let's see).
        #
        # Note that we run this whether or not $simulate is true as it
        # can help to show when this script would fail if run without
        # using -n.
        $FASTQ_FILENAME_CHECKER $fastqFiles

        for fastq in $fastqFiles
        do
            subdir=$(echo $fastq | cut -f1-7 -d_)
            test -d $subdir || run mkdir $subdir

            if [ -f $subdir/$fastq ]
            then
                echo "In $(pwd), FASTQ file $fastq is found both in this directory and in $subdir!" >&2
                exit 1
            fi

            # Move the FASTQ file into the sub-directory. Make sure to deal
            # with symbolic links properly (i.e., so the resulting symlink
            # points to the same file that the current one does).
            if [ -L $fastq ]
            then
                run ln -r -s "$(readlink $fastq)" $subdir/$fastq
                run rm $fastq
            else
                run mv $fastq $subdir
            fi
        done
    fi

    cd $TOP
done
