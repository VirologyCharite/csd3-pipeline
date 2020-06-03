#!/usr/bin/env python

import argparse
import pysam

parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description='Extracting information from a samFile of a mapping against'
    			' rRNA.')

parser.add_argument(
    '--samFile', required=True, metavar='FILENAME',
    help='The filename of the samfile given by bwa mapping against rRNA.')

parser.add_argument(
    '--outFile', required=True, metavar='FILENAME',
    help='The filename the output will be written to.')

args = parser.parse_args()

samfile = pysam.AlignmentFile(args.samFile, 'r')
outfile = args.outFile

# The Lengths below are measured in bp, taken from NR_146117 genbank annotation
#45sExonLength = 13502
#18sRrnaLength = 1872
#5sRrnaLength = 156
#28sRrnaLength = 5195
#45sDnaLength = 45sExonLength - 18sRrnaLength - 5sRrnaLength - 28sRrnaLength

# These are the positions, 0-based
18sRrna = (3659, 5531)
5sRrna = (6615, 6771)
28sRrna = (7942, 13137)
45sRna = [18sRrna, 5sRrna, 28sRrna]
45sDna = [(0,3659), (5531, 6615), (6771, 7942), (13137, 13502)]

def percentMapped(samfile):
	"""
	Given a sam file, calculate the percentage of reads that mapped overall.

	@param samfile: A sam file given by bwa.
	@return: A C{float} of the mapped read percentage. 
	"""
	mapped, unmapped, total = samfile.get_index_statistics()
	percentage = mapped / total * 100

	return mapped, unmapped, total

with open(outfile) as fp:
	fp.write(percentMapped(samfile))

#def calculateAvgCoverage(alignment, region):
	"""
	Given an alignment and certain regions within the alignment,
	this function gives back a float with one decimal position describing
	the average coverage across that region or these regions.

	@param
	@param
	@return
	"""

	# how to do this?



#rDNAcoverage = calculateAvgCoverage(alignment, 45sDna)
#rRNAcoverage = calculateAvgCoverage(alignment, 45sRna)

#rRNA = (rDNAcoverage - rRNAcoverage)
