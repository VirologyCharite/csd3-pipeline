#!/usr/bin/env python

import argparse

parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description='xxxx')

parser.add_argument(
    '--trimmedReads', required=True, metavar='FILENAME',
    help='The trimmed reads to be mapped against rRNA.'
    	 'Usind bwa mem? Index 45s rRNA.')

args = parser.parse_args()

reads = FastaReads(args.alignFile)

# The Lengths below are measured in bp, taken from NR_146117 genbank annotation
45sExonLength = 13502
18sRrnaLength = 1872
5sRrnaLength = 156
28sRrnaLength = 5195
45sDnaLength = 45sExonLength - 18sRrnaLength - 5sRrnaLength - 28sRrnaLength

# These are the positions, 0-based
18sRrna = (3659, 5531)
5sRrna = (6615, 6771)
28sRrna = (7942, 13137)
45sRNA = [18sRrna, 5sRrna, 28sRrna]
45sDna = [(0,3659), (5531, 6615), (6771, 7942), (13137, 13502)]

def calculateAvgCoverage(alignment, region):
	"""
	Given an alignment and certain regions within the alignment,
	this function gives back a float with one decimal position describing
	the average coverage across that region or these regions.

	@param
	@param
	@return
	"""

	# how to do this?

calculateAvgCoverage(alignment, )