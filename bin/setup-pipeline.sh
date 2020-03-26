#!/bin/bash

set -Eeuo pipefail

# Script to be run at the top level of the Charite diagnostics tree. Pass
# directory names as arguments and a pipelines/standard directory will be
# created in each of those directories (unless it already exists), with a
# copy of the standard pipeline. This can also be used to update the
# pipeline scripts in each directory.

case $# in
    0) echo "Usage: $(basename $0) dir1 [dir2...]"; exit 1;;
esac

cwd=$(/bin/pwd)

# First make sure all top-level directories exist (otherwise the mkdir -p
# below will create the top-level dir that will hold the pipelines dir,
# which is probably an error).
for dir in "$@"
do
    if [ ! -d $dir ]
    then
        echo "Target directory '$dir' does not exist! Exiting." >&2
        exit 1
    fi
done

for dir in "$@"
do
    echo "Processing $dir"

    if [ -d $dir/pipelines/standard ]
    then
        # echo "  pipelines/standard sub-directory already exists"

        # Get rid of some old directories that are no longer in the
        # 2019-11-27 pipeline.
        for i in 04-panel-civ 04-panel-civ-encephalitis 03-diamond-civ
        do
            olddir="$dir/pipelines/standard/$i"
            test -d "$olddir" && rm -r "$olddir"
        done
    else
        # echo "  Making pipelines/standard sub-directory"
        mkdir -p $dir/pipelines/standard
    fi

    # echo "  Copying pipeline files"
    tar -C csd3-pipeline --exclude-vcs -c -f - . | tar --no-overwrite-dir -C $dir/pipelines/standard -x -f -
done
