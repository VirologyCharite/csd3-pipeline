#!/bin/bash

set -Eeuo pipefail

# Put a run-type file (containing $1) into the given directories.

case $# in
    0|1) echo "Usage: $(basename $0) run-type dir1 [dir2...]"; exit 1;;
    *) runtype=$1; shift;;
esac

case $runtype in
    hcov|standard) ;;
    *) echo "Unknown run type '$runtype'. Known are 'hcov' and 'standard'." >&2; exit 1;;
esac

for dir in "$@"
do
    if [ -d $dir ]
    then
        echo $runtype > $dir/run-type
    else
        echo "Target directory '$dir' does not exist! Exiting." >&2
        exit 1
    fi
done
