#!/usr/bin/env python

import argparse
import pysam

from dark.fastq import FastqReads

parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description='Extracting information from a samFile of a mapping against'
    			' rRNA.')

parser.add_argument(
    '--mappedFile', required=True, metavar='FILENAME',
    help='The filename of fastq reads that mapped against rRNA.')

parser.add_argument(
    '--unmappedFile', required=True, metavar='FILENAME',
    help='The filename of fastq reads that did not map against rRNA.')

parser.add_argument(
    '--bamFile', required=True, metavar='FILENAME',
    help='The filename of the sorted and indexed bam file given by bwa mapping'
    	 ' against rRNA.')

parser.add_argument(
    '--outFile', required=True, metavar='FILENAME',
    help='The filename the output will be written to.')

args = parser.parse_args()

mappedReads = FastqReads(args.mappedFile)
unmappedReads = FastqReads(args.unmappedFile)
samfile = args.bamFile
outfile = args.outFile

# The Lengths below are measured in bp, taken from NR_146117 genbank annotation
sExonLength45 = 13502
sRrnaLength18 = 1872
sRrnaLength5 = 156
sRrnaLength28 = 5195
sDnaLength45 = sExonLength45 - sRrnaLength18 - sRrnaLength5 - sRrnaLength28

# These are the positions, 0-based
sRrna18 = (3659, 5531)
sRrna5 = (6615, 6771)
sRrna28 = (7942, 13137)
sRna45 = [sRrna18, sRrna5, sRrna28]
sDna45 = [(0,3659), (5531, 6615), (6771, 7942), (13137, 13502)]


def countReads(reads):
	"""
	Given a reads instance, count the number of reads.

	@param reads: A darkmatter reads instance.
	@return: A C{float} of the number of reads.
	"""
	count = 0
	for read in reads:
		count += 1

	return count


def calcPercent(number1, number2):
	"""
	Given two numbers, give the percentage.

	@param number1: Number of to divide.
	@param number2: Number of.total.
	@return: A C{float} giving the %.
	"""
	return number1 / number2 * 100

def extractMappingCoverage(samfile, region):
	"""
	Given a samfile and a list of regions, give the average (depth) coverage
	over those regions.

	@param samfile: samfile as opened with pysam.
	@param region: a C{list} with C{tuples} of ranges of interest.
	@return: A C{float} giving the average coverage depth.
	"""
	return None

nbMapped = countReads(mappedReads)
nbAll = nbMapped + countReads(unmappedReads)

with open(outfile, 'w') as fp:
	fp.write(str(calcPercent(nbMapped, nbAll)) + '%\n')
