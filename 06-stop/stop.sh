#!/bin/bash -e

. ../common.sh

log=$sampleLogFile

echo "SLURM pipeline finished at `date`" >> $log

touch $doneFile
rm -f $runningFile
