.PHONY: all, run, force, status, cancel, unfinished, clean, clobber
.PHONY: html, html-refseq, html-rvdb, tar, tar-refseq, tar-rvdb

REFSEQ_DB := /rds/project/djs200/rds-djs200-acorg/bt/root/share/ncbi/viral-refseq/viral-protein-20180717/viral.protein.fasta
RVDB_DB :=   /rds/project/djs200/rds-djs200-acorg/bt/root/share/rvdb/U-RVDBv14.0-prot.fasta

SAMPLE=$(shell echo $$(basename $$(dirname $$(dirname $$(pwd)))) | cut -f1,2 -d_)

all:
	@echo "There is no default make target. Use 'make run' to run the SLURM pipeline, or make html, or make tar."

run:
	slurm-pipeline.py --specification specification.json > status.json

force:
	slurm-pipeline.py --specification specification.json --force > status.json

status:
	@slurm-pipeline-status.py --specification status.json

cancel:
	@jobs=$$(slurm-pipeline-status.py --specification status.json --printUnfinished); if [ -z "$$jobs" ]; then echo "No unfinished jobs."; else echo "Canceling $$(echo $$jobs | tr '\012' ' ')"; scancel $$jobs; fi

unfinished:
	@slurm-pipeline-status.py --specification status.json --printUnfinished

html: html-refseq html-rvdb

html-refseq:
	proteins-to-pathogens.py \
            --format fastq \
            --html \
            --sampleName $(SAMPLE) \
            --pathogenType viral \
            --proteinFastaFilename $(REFSEQ_DB) \
            --pathogenPanelFilename virus-refseq.png \
            --sampleIndexFilename samples-refseq.index \
            --pathogenIndexFilename pathogens-refseq.index \
            04-panel-refseq/summary-proteins \
            > index-refseq.html

html-rvdb:
	proteins-to-pathogens.py \
            --format fastq \
            --html \
            --sampleName $(SAMPLE) \
            --pathogenType viral \
            --proteinFastaFilename $(RVDB_DB) \
            --pathogenPanelFilename virus-rvdb.png \
            --sampleIndexFilename samples-rvdb.index \
            --pathogenIndexFilename pathogens-rvdb.index \
            04-panel-rvdb/summary-proteins \
            > index-rvdb.html

tar: tar-refseq tar-rvdb

tar-refseq:
	tar cfvj results-refseq.tar.bz2 04-panel-refseq/out index-refseq.html virus-refseq.png {samples,pathogens}-refseq.index

tar-rvdb:
	tar cfvj results-rvdb.tar.bz2 04-panel-rvdb/out index-rvdb.html virus-rvdb.png {samples,pathogens}-rvdb.index

clean:
	rm -f \
               */slurm-*.out \
               slurm-pipeline.done \
               slurm-pipeline.error \
               slurm-pipeline.running

clobber: clean
	rm -fr \
               logs \
               01-stats/*.count \
               005-trim/*.gz \
               005-trim/*.out \
               005-trim/*.settings \
               007-flash/*.fastq.gz \
               007-flash/out.* \
               008-spades/spades.out \
               008-spades/*.fasta.gz \
               02-map/*.[bs]am \
               02-map/*-unmapped.fastq.gz \
               03-diamond-{refseq,rvdb}/*.json.bz2 \
               04-panel-{refseq,rvdb}/out \
               04-panel-{refseq,rvdb}/summary-proteins \
               04-panel-{refseq,rvdb}/summary-virus \
               05-sample-count/*.count \
               status.json
