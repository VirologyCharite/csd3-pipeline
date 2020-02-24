.PHONY: all run force status cancel unfinished clean clobber

all:
	@echo "There is no default make target. Use 'make run' to run the SLURM pipeline."

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

clean-stats:
	rm -fr \
               01-stats/*.count \
               01-stats/slurm-*.out

clean-trim:
	rm -fr \
               005-trim/*.gz \
               005-trim/*.out \
               005-trim/*.settings \
               005-trim/slurm-*.out

clean-hcov:
	rm -fr \
               006-hcov/*.bam* \
               006-hcov/*.vcf* \
               006-hcov/*-consensus*
               006-hcov/tmp

clean-flash:
	rm -fr \
               007-flash/*.fastq.gz \
               007-flash/*.fastq \
               007-flash/out.* \
               007-flash/flash.std{err,out} \
               007-flash/slurm-*.out

clean-spades:
	rm -fr \
               008-spades/spades.out \
               008-spades/*.fasta.gz \
               008-spades/slurm-*.out

clean-map:
	rm -fr \
               02-map/*.[bs]am \
               02-map/*-unmapped.fastq.gz \
               02-map/slurm-*.out

clean-dedup:
	rm -fr \
               025-dedup/*.fastq.gz \
               025-dedup/slurm-*.out

clean-diamond:
	rm -fr \
               03-diamond-*/*.json.bz2 \
               03-diamond-*/slurm-*.out

clean-panel:
	rm -fr \
               04-panel-*/out \
               04-panel-*/summary-{proteins,virus} \
               04-panel-*/slurm-*.out

clean:
	rm -f \
               status.json \
               slurm-pipeline.done \
               slurm-pipeline.error \
               slurm-pipeline.running

clean-all: clean clean-stats clean-trim clean-flash clean-spades clean-map clean-dedup clean-diamond clean-panel

clobber: clean-all
	rm -fr \
               logs
