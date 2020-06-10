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
    '--coverageDepth', required=True, metavar='FILENAME',
    help='The filename of the output of sam-coverage-depth.py, inputting the'
    	 ' sorted and indexed bam file given by bwa mapping against rRNA.')

parser.add_argument(
    '--outFile', required=True, metavar='FILENAME',
    help='The filename the output will be written to.')

args = parser.parse_args()

mappedReads = FastqReads(args.mappedFile)
unmappedReads = FastqReads(args.unmappedFile)
coverageDepth = args.coverageDepth
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


def calcPercent(partial, total):
	"""
	Given two numbers, give the percentage.

	@param partial: Number of to divide.
	@param total: Number of.total.
	@return: A C{float} giving the %.
	"""
	return partial / total * 100

def extractMappingCoverage(coverageDepth, region):
	"""
	Given an outputfile from sam-coverage-depth.py and a list of regions, give
	the average coverage-depth over those regions.

	@param coverageDepth: sam-coverage-depth outfile.
	@param region: a C{tuples} with a range of interest.
	@return: A C{float} giving the average coverage depth across the range.
	"""
	with open(coverageDepth) as cd:
		depthList = []
		for line in cd:
			for index in range(region[0], region[1]):
				if str(index) in line:
					depthList.append(int(line.split()[1]))

		averageCoverage = sum(depthList) / len(depthList)
		return averageCoverage

nbMapped = countReads(mappedReads)
nbAll = nbMapped + countReads(unmappedReads)

with open(outfile, 'w') as fp:
	fp.write(str(calcPercent(nbMapped, nbAll)) + '%\n')
	for rRNA in sRna45:
		fp.write(str(extractMappingCoverage(coverageDepth, rRNA) + rRNA + '\n')
	for rDNA in sDna45:
		fp.write(str(extractMappingCoverage(coverageDepth, rDNA) + rDNA + '\n')
