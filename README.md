# Charit&eacute; diagnostic pipeline spec

This repo contains a
[slurm-pipeline](https://github.com/acorg/slurm-pipeline) specification
file (`specification.json`) and associated scripts for processing
Charit&eacute; diagnostic data.

## Running on csd3

Suppose you have a new run, dated `200101`:

```sh
$ cd ~/1/projects/charite
$ setup-run.sh 200101
# transfer all Illumina sample dirs into 200101
$ setup-pipeline.sh 200101/[DW]_*
$ cd 200101
$ make run
# Wait until run is done (try make status)
$ make
```

The final `make` makes the HTML, tars it up, transfers it to `civnb.info`,
and untars it over there.

Results are then available at
[https://civnb.info/diagnostics/](https://civnb.info/diagnostics/).
