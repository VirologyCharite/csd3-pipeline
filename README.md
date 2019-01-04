# Lasse requencing initial pipeline spec

This repo contains a
[slurm-pipeline](https://github.com/acorg/slurm-pipeline) specification
file (`specification.json`) and associated scripts for processing Lasse's
capture data.

## Pipeline steps

* `00-start`: Logging. Find input FASTQ files for a sample, check they
  exist, issue a task for each.
* `005-trim`: Run `AdapterRemoval` to trim the FASTQ.
* `01-stats`: Collect statistics on the original (untrimmed) FASTQ files.
* `02-map`: Map reads to the human genome using `bwa`. Find unmapped reads
  for the next stage of processing.
* `03-diamond`: Map the non-human reads to a viral protein database.
* `04-panel`: Make a [dark matter](https://github.com/acorg/dark-matter/) panel of blue plots.
* `05-sample-count`: Count the number of reads per sample (summing the
  sequencing read counts from `01-stats`).
* `06-stop`: Logging. Create `slurm-pipeline.done` in top-level dir.
* `07-error`: Run if an error occurs in earlier steps. Does some cleaning up.

## Output

The scripts in `00-start`, etc. are all submitted by `sbatch` for execution
under [SLURM](http://slurm.schedmd.com/). The final step, `04-panel` leaves
its output in `04-panel/out`.
