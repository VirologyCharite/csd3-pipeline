#!/bin/bash

set -Eeuo pipefail

. ../common.sh

# We cannot initially write to a log file because the log directory may not
# exist yet. So write initial errors to stderr.

# Remove the top-level logging directory (with a sanity check on its name).
if [ ! "$logDir" = ../logs ]
then
    # SLURM will catch this output and put it into slurm-N.out where N is
    # out job id.
    echo "$0: logDir variable has unexpected value '$logDir'!" >&2
    exit 1
fi

rm -fr $logDir

mkdir $logDir || {
    # SLURM will catch this output and put it into slurm-N.out where N is
    # out job id.
    echo "$0: Could not create log directory '$logDir'!" >&2
    exit 1
}

# From here on we can write errors to a log file.

log=$sampleLogFile
logStepStart $log

# Remove the marker files that indicate when a job is fully complete or
# that there has been an error and touch the file that shows we're running.
rm -f $doneFile $errorFile
touch $runningFile

echo "  Removing all old slurm-*.out files." >> $log
rm -f ../*/slurm-*.out

tasks=$(tasksForSample)

for task in $tasks
do
    fastq1=$dataDir/$task.fastq.gz
    checkFastq $fastq1 $log
    checkGzipIntegrity $fastq1 $log
    fastq2=$(mateFile $fastq1)
    checkFastq $fastq2 $log
    checkGzipIntegrity $fastq2 $log
    echo "  task $task, FASTQ1 $fastq1" >> $log
    echo "  task $task, FASTQ2 $fastq2" >> $log
done

for task in $tasks
do
    # Emit task names (without job ids as this step does not start any
    # SLURM jobs).
    echo "TASK: $task"
done

logStepStop $log
