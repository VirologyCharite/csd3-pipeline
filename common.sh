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
# non-interactive shell.
set +u
. $activate
set -u

dataDir=../../..
doneFile=../slurm-pipeline.done
runningFile=../slurm-pipeline.running
errorFile=../slurm-pipeline.error
sampleLogFile=$logDir/sample.log

# A simple way to set defaults for our SP_* variables, without causing
# problems when e.g., using test, if set -ue is active (causing scripts to
# exit with status 1 and no explanation).
echo ${SP_SIMULATE:=0} ${SP_SKIP:=0} ${SP_FORCE:=0} \
     ${SP_DEPENDENCY_ARG:=''} ${SP_NICE_ARG:='--nice'} \
     ${SLURM_JOB_ID:='None'} >/dev/null

# Regex matching encephalitis-causing viruses. From a list Julia Schneider
# sent me (Terry) on Jan 19, 2019.
ENCEPHALITIS_REGEX="encephalitis|dengue|west nile|powassan|kunjin|usutu|louping|kyasanur|rocio|alkhurma|ilheus|zika|hepatitis c|everglades|sindbis|chikungunya|semliki forest|rubella|human astrovirus|hepatits e|norovirus|polio|coxsackievirus a|entero 71|human parechovirus|human immunodeficiency|hiv|human t-lymphotropic|htlv-1|human coronavirus oc43|rotavirus|eyach|colorado tick fever|banna|liao ning|kemerovo|mumps|measles|human respiratory syncytial|hendra|nipah|parainfluenzavirus 2|human metapneumovirus|rabies|le dantec|chandipura|variegated squirrel bornavirus 1|snow-shoe-hare|snow shoe|cache-valley|jamestown canyon|rift valley|sandfly fever|heartlandvirus|severe fever with thrombocytopenia syndrome bunyavirus|toscana|puumalavirus|andesvirus|hantaanvirus |influenza a|influenza b|dhori|lymphocyctic choriomeningitis|lassavirus|parvovirus|human parvovirus 4|human bocavirus|adenovirus type 3|adenovirus type 7|adenovirus type 11 |bkpyv|jcpyv|herpes simplex|varicella zoster|cytomegalievirus|hhv-6a|hhv-6b|hhv-7|epstein-barr|kaposi sarcoma-associated herpesvirus|cyclovirus|gemycircularvirus|human papilloma|hepatitis b|oropuchovirus|bunyamwera|ross river|junin|rio bravo|batai|inkoo|coxsackie-virus"

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

    echo "  Checking gzipped file '$gz' for integrity." >> $log

    set +e
    gunzip -t < "$gz" >> $log
    status=$?
    set -e

    if [ $status -ne 0 ]
    then
        echo "Gzip integrity check failed!" >> $log
        exit 1
    else
        echo "Gzip integrity check passed." >> $log
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
