# IMPORTANT: All (relative) paths in this file are relative to the scripts
# in 00-start, etc. This file is sourced by those scripts.

set -Eeuo pipefail

logDir=../logs
log=$logDir/common.sh.stderr
root=/rds/project/djs200/rds-djs200-acorg/bt/root

if [ ! -d $root ]
then
    echo "  Root directory '$root' does not exist." >> $log
    exit 1
fi

activate=$root/share/virtualenvs/365/bin/activate

if [ ! -f $activate ]
then
    echo "  Virtualenv activation script '$activate' does not exist." >> $log
    exit 1
fi

# The virtualenv activate script uses PS1, which will be unset in a
# non-interactive shell. Temporarily use set +u to make sure we don't exit
# due to the undefined variable.
set +u
. $activate
set -u

dataDir=../../..
doneFile=../slurm-pipeline.done
runningFile=../slurm-pipeline.running
errorFile=../slurm-pipeline.error
sampleLogFile=$logDir/sample.log

# Arg values for alignment-panel-civ.py (used in the various panel.sh
# scripts in 04-panel-*).
blacklistFile=../blacklist
minMatchingReads=2
percentagePositiveCutoff=17.0

civDate=20191204
dnaProteinGenomeDB=$root/share/civ/$civDate-dna-protein-genome.db
dnaDiamondDB=$root/share/civ/$civDate-dna-proteins.dmnd

dnaLargeProteinGenomeDB=$root/share/civ/20200106-dna-large-protein-genome.db
dnaLargeDiamondDB=$root/share/civ/20200106-dna-large-proteins.dmnd

rnaProteinGenomeDB=$root/share/civ/$civDate-rna-protein-genome.db
rnaDiamondDB=$root/share/civ/$civDate-rna-proteins.dmnd

taxonomyDB=$root/share/civ/$civDate-taxonomy.db

if [ ! -f $dnaProteinGenomeDB ]
then
    echo "  DNA protein/genome database file $dnaProteinGenomeDB does not exist!" >> $log
    exit 1
fi

if [ ! -f $dnaDiamondDB ]
then
    echo "  DIAMOND DNA database file $dnaDiamondDB does not exist!" >> $log
    exit 1
fi

if [ ! -f $dnaLargeProteinGenomeDB ]
then
    echo "  DNA large protein/genome database file $dnaLargeProteinGenomeDB does not exist!" >> $log
    exit 1
fi

if [ ! -f $dnaLargeDiamondDB ]
then
    echo "  DIAMOND large DNA database file $dnaLargeDiamondDB does not exist!" >> $log
    exit 1
fi

if [ ! -f $rnaProteinGenomeDB ]
then
    echo "  RNA protein/genome database file $rnaProteinGenomeDB does not exist!" >> $log
    exit 1
fi

if [ ! -f $rnaDiamondDB ]
then
    echo "  DIAMOND RNA database file $rnaDiamondDB does not exist!" >> $log
    exit 1
fi

if [ ! -f $taxonomyDB ]
then
    echo "  Taxonomy database file $taxonomyDB does not exist!" >> $log
    exit 1
fi

# A simple way to set defaults for our SP_* variables, without causing
# problems when e.g., using test, if set -ue is active (causing scripts to
# exit with status 1 and no explanation).
echo ${SP_SIMULATE:=0} ${SP_SKIP:=0} ${SP_FORCE:=0} \
     ${SP_DEPENDENCY_ARG:=''} ${SP_NICE_ARG:='--nice'} \
     ${SLURM_JOB_ID:='None'} >/dev/null

# Regex matching encephalitis-causing viruses. Based on a list Julia
# Schneider sent me (Terry) on Jan 19, 2019.
ENCEPHALITIS_REGEX="$(cat ../encephalitis-regex.txt)"

function mateFile()
{
    echo $1 | sed -e s/_R1_/_R2_/
}

function tasksForSample()
{
    # Emit a task for all sequencing files that correspond to this sample.
    # The task names are the basenames of the FASTQ file names minus the
    # .fastq.gz suffix.
    files=$(ls $dataDir/*_R1_*.fastq.gz | sed -e 's/\.fastq\.gz//')

    if [ -z "$files" ]
    then
        echo "  No FASTQ files found in $dataDir" >> $log
        exit 1
    else
        tasks=
        for file in $files
        do
            tasks="$tasks $(basename $file)"
        done
    fi

    echo $tasks
}

function logStepStart()
{
    # Pass a log file name.

    # SLURM_JOB_ID will not be set if we are running from the command line.
    # So turn off exiting due to unknown variables.
    set +u

    case $# in
        1) echo "$(basename $(pwd)) (SLURM job $SLURM_JOB_ID) started at $(date) on $(hostname)." >> $1;;
        *) echo "logStepStart must be called with 2 arguments." >&2;;
    esac

    set -u
}

function logStepStop()
{
    # Pass a log file name.

    # SLURM_JOB_ID will not be set if we are running from the command line.
    # So turn off exiting due to unknown variables.
    set +u

    case $# in
        1) echo "$(basename $(pwd)) (SLURM job $SLURM_JOB_ID) stopped at $(date)" >> $1; echo >> $1;;
        *) echo "logStepStop must be called with 2 arguments." >&2;;
    esac

    set -u
}

function logTaskToSlurmOutput()
{
    local task=$1
    local log=$2

    # The following will appear in the slurm-*.out (because we don't
    # redirect it to $log). This is useful if there is an error that only
    # appears in the SLURM output, file because it tells us what sample log
    # file to go look at, to re-run, etc.

    # SLURM_JOB_ID will not be set if we are running from the command line.
    # So turn off exiting due to unknown variables.
    set +u
    echo "Task $task (SLURM job $SLURM_JOB_ID) started at $(date)"
    set -u
    echo "Task log file is $log"
}

function checkGzipIntegrity()
{
    local gz=$1
    local log=$2
    local integrity=$gz.ok

    echo "  Checking gzipped file '$gz' for integrity." >> $log

    if [ -f $integrity ]
    then
        echo "  Gzip integrity already tested - skipping check." >> $log
    else
        set +e
        gunzip -t < "$gz" >> $log
        status=$?
        set -e

        if [ $status -ne 0 ]
        then
            echo "  Gzip integrity check failed!" >> $log
            exit 1
        else
            echo "  Gzip integrity check passed." >> $log
            touch $integrity
        fi
    fi
}

function checkFastq()
{
    local fastq=$1
    local log=$2

    echo "  Checking FASTQ file '$fastq'." >> $log

    set +e
    if [ ! -f $fastq ]
    then
        echo "  FASTQ file '$fastq' does not exist, according to test -f." >> $log

        if [ -L $fastq ]
        then
            dest=$(readlink $fastq)
            echo "  $fastq is a symlink to $dest." >> $log

            if [ ! -f $dest ]
            then
                echo "  Linked-to file '$dest' does not exist, according to test -f." >> $log
            fi

            echo "  Attempting to use zcat to read the destination file '$dest'." >> $log
            # zcat $dest | head >/dev/null
            zcat $dest | head >>$log 2>&1
            case $? in
                0) echo "    zcat read succeeded." >> $log;;
                *) echo "    zcat read failed." >> $log;;
            esac

            echo "  Attempting to use zcat to read the link '$fastq'." >> $log
            zcat $fastq | head >>$log 2>&1
            # zcat $fastq | head >/dev/null
            case $? in
                0) echo "    zcat read succeeded." >> $log;;
                *) echo "    zcat read failed." >> $log;;
            esac
        fi

        echo "  Sleeping to see if '$fastq' becomes available." >> $log
        sleep 3

        if [ ! -f $fastq ]
        then
            echo "  FASTQ file '$fastq' still does not exist, according to test -f." >> $log
            logStepStop $log
            exit 1
        fi
    fi
    set -e
}

function rmFileAndLink()
{
    for file in "$@"
    do
        if [ -L $file ]
        then
            rm -f $(readlink $file)
        fi
        rm -f $file
    done
}
