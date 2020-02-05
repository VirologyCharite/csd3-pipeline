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

You need to do all the following on the Cambridge cluster.

### Make a subdirectory for the run

```sh
$ mkdir projects/charite/200101
```

### Transfer all Illumina FASTQ files from BIH

Into the `200101` directory you just made. You'll need to know where these
are on the BIH cluster (I think under
`/fast/projects/civ-diagnostics/work/raw` - TODO: check!).

### Setup the run

Note that the following is run in the parent directory of the `200101`
directory (i.e., the top-level `charite` directory):

```sh
$ cd projects/charite
$ ./setup-run.sh 200101
```

The `setup-run.sh` script will make a `Makefile` (symbolic link) in the
`200101` directory and also move all the FASTQ you transferred into
sub-directories, assuming their file names can be parsed.

### Copy the pipeline into each sample sub-directory

Again, in the top-level `charite` directory:

```sh
$ cd projects/charite
$ ./setup-pipeline.sh 200101/[DW]_*
```

### Start the pipeline

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
