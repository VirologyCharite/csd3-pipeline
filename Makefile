.PHONY: all, run, force, status, cancel, unfinished, clean, clobber
.PHONY: html, html-refseq, html-rvdb, tar, tar-refseq, tar-rvdb

# Any text placed into the file named by PREAMBLE_FILE (if present) will be
# put into the summary HTML generated below by the html-* targets.
# If the file is not present, there will be no preamble in the HTML output.
PREAMBLE_FILE := summary-preamble.html
PREAMBLE := "$(shell test -f $(PREAMBLE_FILE) && cat $(PREAMBLE_FILE))"

CIV_DATE := 20190910

# The following must match the proteinGenomeDB variable in common.sh
PROTEIN_GENOME_DB := /rds/project/djs200/rds-djs200-acorg/bt/root/share/civ/$(CIV_DATE)-protein-genome.db

ENCEPHALITIS_REGEX := "$(shell cat encephalitis-regex.txt)"

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

html: html-civ html-civ-encephalitis
tar: tar-civ tar-civ-encephalitis
clean: clean-civ clean-civ-encephalitis

html-civ:
	proteins-to-pathogens-civ.py \
            --html \
            --proteinGenomeDatabase $(PROTEIN_GENOME_DB) \
            --format fastq \
            --title "Charit&eacute; custom RNA protein database: NCBI Refseq virus genomes, sequences from three Chinese papers, and the RdRp protein (or fragment thereof) from OKIAV genomes." \
            --preamble $(PREAMBLE) \
            --sampleName $(SAMPLE) \
            --pathogenType viral \
            --pathogenPanelFilename virus-civ.png \
            --pathogenDataDir pathogen-data-civ \
            04-panel-civ/summary-proteins \
            > index-civ.html

html-civ-encephalitis:
	proteins-to-pathogens-civ.py \
            --html \
            --proteinGenomeDatabase $(PROTEIN_GENOME_DB) \
            --format fastq \
            --title "Charit&eacute; custom RNA protein database: NCBI Refseq virus genomes, sequences from three Chinese papers, and the RdRp protein (or fragment thereof) from OKIAV genomes, filtered for encephalitis-causing viruses." \
            --preamble $(PREAMBLE) \
            --titleRegex $(ENCEPHALITIS_REGEX) \
            --sampleName $(SAMPLE) \
            --pathogenType viral \
            --pathogenPanelFilename virus-civ-encephalitis.png \
            --pathogenDataDir pathogen-data-civ-encephalitis \
            04-panel-civ-encephalitis/summary-proteins \
            > index-civ-encephalitis.html

tar-civ:
	tar cfj results-civ.tar.bz2 \
            04-panel-civ/out \
            index-civ.html \
            virus-civ.png \
            pathogen-data-civ

tar-civ-encephalitis:
	tar cfj results-civ-encephalitis.tar.bz2 \
            04-panel-civ-encephalitis/out \
            index-civ-encephalitis.html \
            virus-civ-encephalitis.png \
            pathogen-data-civ-encephalitis

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
