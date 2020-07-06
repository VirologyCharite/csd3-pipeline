#!/usr/bin/env python

import sys
import argparse
import pysam

from dark.fastq import FastqReads

parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description='Extracting information from a samFile of a mapping against'
                ' rRNA.')

parser.add_argument(
    '--sortedbam', required=True, metavar='FILENAME',
    help='The filename of fastq reads that mapped against rRNA.')

#parser.add_argument(
#    '--unmappedFile', required=True, metavar='FILENAME',
#    help='The filename of fastq reads that did not map against rRNA.')

#parser.add_argument(
#    '--coverageDepth', required=True, metavar='FILENAME',
#    help='The filename of the output of sam-coverage-depth.py, inputting the'
#         ' sorted and indexed bam file given by bwa mapping against rRNA.')

#parser.add_argument(
#    '--outFile', required=True, metavar='FILENAME',
#    help='The filename the output will be written to.')

args = parser.parse_args()

sortedbam = args.sortedbam

# mRNA exon borders
mRNA = {
    'HEBP2': [(134, 135), (270, 271), (451, 452)],
    'POLR2H': [(72, 73), (156, 157), (250, 251), (334, 335)],
    'CRELD2': [(128, 129), (211, 212), (322, 323), (414, 415), (591, 592), (738, 739), (834, 835), (918, 919), (1014, 1015), (1155, 1156)],
    'MRPS24': [(38, 39), (107, 108), (219, 220)],
    'CIAO2B': [(141, 142), (221, 222), (347, 348), (393, 394), ],
    'NDUFS3': [(66, 67), (132, 133), (130, 231), (380, 381), (506, 507), (626, 627), ],
    'GTF3A': [(200, 201), (301, 302), (398, 399), (487, 488), (561, 562), (642, 643), (872, 873), (932, 933)],
    'PPIA': [(68, 69), (99, 100), (188, 189), (361, 362)],
    'B2M': [(66, 67), (345, 346)],
    'GAPDH': [(28, 29), (128, 129), (235, 236), (326, 327), (442, 443), (524, 525), (937, 938)],
    'ACTB': [(122, 123), (362, 363), (801, 802), (983, 984)],
    'RPL13': [(103, 104), (245, 246), (419, 420), (476, 477)],
    'PGK1': [(64, 65), (115, 116), (271, 272), (416, 417), (520, 521), (640, 641), (755, 756), (935, 936), (1113, 1114), (1212, 1213)],
    'HPRT1': [(26, 27), (133, 134), (317, 318), (383, 384), (401, 402), (484, 485), (531, 532), (608, 609)],
    'AMZ2': [(282, 283), (456, 457), (585, 586), (749, 750), (926, 927)],
    'POMP': [(2, 3), (100, 101), (161, 162), (263, 264), (357, 358)],
    'POLR2I': [(58, 59), (113, 114), (187, 188), (262, 263), (314, 315)],
    'GSTO1': [(33, 34), (142, 143), (365, 366), (464, 465), (571, 572)],
    'NDUFB4': [(179, 180) , (326, 327)],
    'NDUFB1': [(139, 140)],
    'NDUFA3': [(9, 10), (108, 109), (186, 187)],
}

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



with open(outfile, 'w') as fp:
    fp.write('xxx\n')
