#!/bin/bash

set -Eeuo pipefail

. ../common.sh

log=$sampleLogFile

logStepStart $log
logTaskToSlurmOutput error $log

echo "  ERROR!! SLURM pipeline finished at $(date)" >> $log

echo "  Creating $errorFile." >> $log
touch $errorFile

echo "  Removing $runningFile and $doneFile." >> $log
rm -f $runningFile $doneFile

logStepStop $log
