#!/bin/bash

set -Eeuo pipefail

. ../common.sh

log=$sampleLogFile

echo "SLURM pipeline finished at `date`" >> $log

touch $doneFile
rm -f $runningFile
