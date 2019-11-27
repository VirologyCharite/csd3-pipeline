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

clean:
	rm -f \
               */slurm-*.out \
               slurm-pipeline.done \
               slurm-pipeline.error \
               slurm-pipeline.running

clobber: clean
	rm -fr \
               status.json \
               logs \
               01-stats/*.count \
               005-trim/*.gz \
               005-trim/*.out \
               005-trim/*.settings \
               007-flash/*.fastq.gz \
               007-flash/out.* \
               007-flash/flash.std{err,out} \
               008-spades/spades.out \
               008-spades/*.fasta.gz \
               02-map/*.[bs]am \
               02-map/*-unmapped.fastq.gz \
               03-diamond-*/*.json.bz2 \
               04-panel-*/out \
               04-panel-*/summary-{proteins,virus}

