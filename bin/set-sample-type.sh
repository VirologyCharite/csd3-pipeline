#!/bin/bash

set -Eeuo pipefail

# Set the sampleType variable (containing the value of $1) into the
# sample-settings.sh file for the sample.

case $# in
    0|1) echo "Usage: $(basename $0) sample-type dir1 [dir2...]"; exit 1;;
    *) sampletype=$1; shift;;
esac

case $sampletype in
    hcov|standard|medmuseum) ;;
    *) echo "Unknown sample type '$sampletype'. Known are 'hcov', standard' and"\
            "medmuseum'." >&2; exit 1;;
esac

for dir in "$@"
do
    if [ -d $dir ]
    then
        settings=$dir/sample-settings.sh

        if [ -f $settings ]
        then
            tmp=$(mktemp)
            set +e
            egrep -v '^sampleType=' < $settings > $tmp
            set -e
            mv $tmp $settings
            chmod g+rw $settings
        fi

        echo "sampleType=$sampletype" >> $settings
    else
        echo "Target directory '$dir' does not exist! Exiting." >&2
        exit 1
    fi
done
