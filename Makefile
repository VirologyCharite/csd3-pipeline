.PHONY: all run force status cancel unfinished clean clean-all clobber

all:
	@echo "There is no default make target. Use 'make run' to run the SLURM pipeline."

run:
	slurm-pipeline.py --specification specification.json > status.json

force:
	slurm-pipeline.py --specification specification.json --force > status.json

status:
	@slurm-pipeline-status.py --specification status.json

cancel:
	@jobs=$$(slurm-pipeline-status.py --specification status.json --printUnfinished); \
        if [ -z "$$jobs" ]; \
        then \
            echo "No unfinished jobs."; \
        else \
            echo "Canceling $$(echo $$jobs | tr '\012' ' ')"; \
            scancel $$jobs; \
        fi

unfinished:
	@slurm-pipeline-status.py --specification status.json --printUnfinished

clean-stats:
	make -C 01-stats clean

clean-trim:
	make -C 005-trim clean

clean-hcov:
	make -C 006-hcov clean

clean-flash:
	make -C 007-flash clean

clean-spades:
	make -C 008-spades clean

clean-map:
	make -C 02-map clean

clean-dedup:
	make -C 025-dedup clean

clean-diamond:
	for i in 03-diamond-*; \
        do \
            make -C $$i clean; \
        done

clean-panel:
	for i in 04-panel-*; \
        do \
            make -C $$i clean; \
        done

clean:
	rm -fr \
               status.json \
               slurm-pipeline.done \
               slurm-pipeline.error \
               slurm-pipeline.running \
               csd3lib/__pycache__ \
               test/__pycache__

clean-all: clean clean-stats clean-trim clean-hcov clean-flash clean-spades clean-map clean-dedup clean-diamond clean-panel

clobber: clean-all
	rm -fr logs

pytest:
	env PYTHONPATH=. pytest

discover:
	env PYTHONPATH=. python -m discover -v

tcheck:
	env PYTHONPATH=. trial --rterrors test
