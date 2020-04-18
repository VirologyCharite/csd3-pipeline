# Charit&eacute; diagnostic pipeline spec

This repo contains a
[slurm-pipeline](https://github.com/acorg/slurm-pipeline) specification
file (`specification.json`) and associated scripts for processing
Charit&eacute; diagnostic data.

## bih-pipeline metadata

Suppose you have a new run, named `200101` (note that although this looks
like a date, you can actually use a name, like `200101-WURS`). But, there
*must* be a run file in the `data/runs` dir of the
[bih-pipeline](https://github.com/virologycharite/bih-pipeline) repo with a
`runId` matching `200101` (see note on `summarize-run.py` failing below for
the reason why).

## Running on csd3

There are various `make` commands below. It's good to know about the `-n`
option to `make`, which will print out what would be done if you didn't use
`-n`. I (Terry) use `make -n TARGET` often, and so should you!

You need to do all the following on the Cambridge cluster.

### Make a subdirectory for the run

```sh
$ mkdir projects/charite/200101
```

### Transfer all Illumina FASTQ files from BIH

Into the `200101` directory you just made. You'll need to know where these
are on the BIH cluster (I think under
`/fast/projects/civ-diagnostics/work/raw` - TODO: check!). You can remove
the files with names that contain `*_I1_*` and `*_I2_*`, those are the
sequencing files for the indices.

### Setup the run

Note that the following is run in the parent directory of the `200101`
directory (i.e., the top-level `charite` directory):

```sh
$ cd projects/charite
$ ./setup-run.sh 200101
```

The `setup-run.sh` script will put a `Makefile` (which is in fact a
symbolic link to `Makefile.toplevel` in this repo) in the `200101`
directory and also move all the FASTQ you transferred into sub-directories,
assuming their filenames can be parsed.

### Copy the pipeline into each sample sub-directory

Again, in the top-level `charite` directory:

```sh
$ cd projects/charite
$ ./setup-pipeline.sh 200101/[DW]_*
```

### Per-run and/or per-sample settings

You can specify per-run or per-sample settings by making a file
`run-settings.sh` in the top-level directory for the run (e.g., in
`200409-SARS-2/run-settings.sh`) or by putting a `sample-settings.sh` file
into the directory for a sample (e.g., in
`200409-SARS-2/D_200409_3_885_1_swab_RNA/sample-settings.sh`). These files
can be used to override settings in `common.sh`. The variables and
functions defined in these files will be accessible to pipeline scripts
because they all source the `common.sh` file, which in turn sources the
settings files (if they exist).

#### Easy setting of the sample type

As a convenience (and for backwards compatibility) you can use
`./set-sample-type.sh` to set the type of a sample. This just results in
a line being placed in the `sample-settings.sh` file:

This only needs to be done if some of the samples should make a human
coronavirus (SARS-CoV-2) consensus and BAM file and should only match
against one coronavirus sequence. If you don't do this step, the pipeline
will generate many massive FASTQ output files containing essentially the
same reads.

To set a sample run to run the HCoV pipeline:

```sh
$ ./set-sample-type.sh hcov DIRNAME [DIRNAME...]
```

Or to set a sample run to run the standard pipeline:

```sh
$ ./set-sample-type.sh standard DIRNAME [DIRNAME...]
```

As mentioned, `standard` is the default.

You can see the run types for all sub-directories via

```sh
$ make print-standard
$ make print-hcov
```

You should do this to check that the samples you expect to be run using the
hcov pipeline are recognized as such.

### Put reference files in place for HCoV processing

For runs that are of type `hcov`, a reference coronavirus sequence is
needed. By default the sequence in
`/rds/project/djs200/rds-djs200-acorg/bt/root/share/civ/hcov/hcov-reference.fasta`
will be used. This is currently a symbolic link to `EPI_ISL_402125.fasta` file
(sequence id `hCoV-19/Wuhan-Hu-1/2019|EPI_ISL_402125`) in the
[data/sequences](https://github.com/VirologyCharite/2019-nCoV-sequences/tree/master/data/sequences)
directory of the
[2019-nCoV-sequences](https://github.com/VirologyCharite/2019-nCoV-sequences/)
repo.

If you do not want to use this default reference for a sample, you can put
a file (or a symbolic link) called `reference.fasta` into the individual
`006-hcov` directory for that sample. You have to do this for each sample
that should be aligned against a non-default reference. The reference will
be aligned against using Bowtie2 and a consensus will be made based on
this. There is no need to build a Bowtie2 index for your reference, that
will be done automatically. Just put a `reference.fasta` in place.

TODO: improve this by just letting the user give a different value for
`hcovReference` and `hcovReferenceIndex` in `sample-settings.sh`. That will
need a little work in `006-hcov/hcov.sh` and some work on the server to go
find the `reference.fasta` files and put their paths into the settings file.


### Start the pipeline

Once you have set the run types (if any are non-standard) and hcov
reference files, you can run the pipeline:

```sh
$ cd projects/charite/200101
$ make run
```

### Monitoring

Try

```sh
$ cd projects/charite/200101
$ make status
```

to see a list of the `slurm-pipeline.{done,error,running}` files. You're
hoping to see a full set of `.done` files.

### Make HTML and upload it to civnb.info

When the pipeline run is completely done.

```sh
$ make
```

This makes the HTML, tars it up, transfers it to `civnb.info`, and untars
it over there.  This will only work if there is a run file in the
`data/runs` dir of the
[bih-pipeline](https://github.com/virologycharite/bih-pipeline) repo with a
`runId` matching `200101` (in the present example). If there is not, the
`summarize-run.py` call will fail.

You'll need to have ssh'd into Cambridge using the `-A`
argument to `ssh` (and have run `ssh-add` locally to start the ssh agent)
for this to run seamlessly and not ask you for a password.

### View your output

Results are then available at
[https://civnb.info/diagnostics/](https://civnb.info/diagnostics/).

## Making BAM files and consensuses

If you want to make a BAM file and consensus against a specific reference,
you can do this once the trimming of the FASTQ for the sample(s) in question
has completed.

You then `cd` into the `006-hcov` directory of each sample:

```sh
$ cd D_200219_4_555_5_isolate_RNA/pipelines/standard/006-hcov
```

Then run the `hcov.sh` script, giving a reference FASTA file as its only
argument, or put your reference into `reference.fasta` and run with no
arguments. Note that you might want to run this on an exclusive machine
so that the `bowtie2` process (and things it launches) can use 32 cores
and you don't clog up a login machine:

```sh
sbatch-run.py --job hcov --time 00:30:00 --exclusive ./hcov.sh
```

The `hcov.sh` script will create you a BAM and consensus file, and various
others. E.g.:

```
D_200219_4_555_5_isolate_RNA_S4_R1_001-alignment.fasta
D_200219_4_555_5_isolate_RNA_S4_R1_001-consensus.fasta
D_200219_4_555_5_isolate_RNA_S4_R1_001-coverage.txt
D_200219_4_555_5_isolate_RNA_S4_R1_001-read-count.txt
D_200219_4_555_5_isolate_RNA_S4_R1_001-reference-consensus-comparison.txt
D_200219_4_555_5_isolate_RNA_S4_R1_001.bam
D_200219_4_555_5_isolate_RNA_S4_R1_001.bam.bai
D_200219_4_555_5_isolate_RNA_S4_R1_001.vcf.gz
D_200219_4_555_5_isolate_RNA_S4_R1_001.vcf.gz.tbi
```

You can then do whatever you like with those files.

For convenience, if you do the above on several samples, you can then go to
the top level of the run and type

```sh
$ make zip-hcov
```

Which will make you a zip file with a name like
`200220-nCoV-isolates-hcov.zip` (the `200220-nCoV-isolates` here is the run
id) that you can send to someone. This will have the BAM and consensus (and
more, as above) from all the `006-hcov` sub-directories where you made
consensuses.
