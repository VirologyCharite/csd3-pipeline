#!/bin/bash

set -Eeuo pipefail

# Script to be run at the top level of the Charite diagnostics tree. Give
# the name (usually YYMMDD) of run directories to set up.

case $# in
    0) echo "Usage: $(basename $0) dir1 [dir2...]"; exit 1;;
esac

TOP=$(/bin/pwd)
MAKEFILE=../csd3-pipeline/Makefile.toplevel

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

    if [ -f Makefile ]
    then
        echo "  Makefile already exists."
    else
        if [ ! -f $MAKEFILE ]
        then
            echo "In $(pwd), could not find $MAKEFILE" >&2
            exit 1
        else
            echo "  Making symbolic link to $MAKEFILE"
            ln -s $MAKEFILE Makefile
        fi
    fi

    cd $TOP
done
