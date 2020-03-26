#!/usr/bin/env python

import sys
import argparse
from os.path import exists, join
from collections import defaultdict

from dark.process import Executor

from csd3lib.comm import countCommon


def _key(s):
    return int(s.split('_')[2])


def shortFilename(filename):
    return filename.split('/')[0]


def filenameLT(f1, f2):
    return _key(f1) < _key(f2)


def checkFastqSuffixes(args):
    for filename in args.fastq:
        if not filename.endswith('.fastq'):
            raise ValueError('Found non-FASTQ filename %r.' % filename)


def getCounts(args):
    counts = defaultdict(dict)
    for filename1 in args.fastq:
        md5Filename1 = filename1[:-len('fastq')] + 'md5'
        for filename2 in args.fastq:
            if filenameLT(filename1, filename2):
                md5Filename2 = filename2[:-len('fastq')] + 'md5'
                with open(md5Filename1) as fp1:
                    with open(md5Filename2) as fp2:
                        counts[filename1][filename2] = countCommon(fp1, fp2)

    return counts


def makeMd5(args, ex):
    noMd5Fastq = []
    md5Filenames = []

    for filename in args.fastq:

        md5Filename = filename[:-len('fastq')] + 'md5'

        if not exists(md5Filename) or args.force:
            noMd5Fastq.append(filename)
            md5Filenames.append(md5Filename)

    if noMd5Fastq:
        if args.verbose:
            print('Generating MD5 files for %d FASTQ files:' % len(noMd5Fastq),
                  file=sys.stderr)
            for filename in noMd5Fastq:
                print('  ', filename, file=sys.stderr)

        ex.execute(
            'parallel "fasta-sequences.py --fastq --md5OneLine < {} > '
            '{.}.md5" ::: %s' %
            ' '.join("'%s'" % filename for filename in noMd5Fastq))

        ex.execute('parallel "sort -o {} {}" ::: %s' %
                   ' '.join("'%s'" % filename for filename in md5Filenames))
    else:
        if args.verbose:
            print('All MD5 files already present. Use --force to overwrite.',
                  file=sys.stderr)


def main(args):
    ex = Executor(args.dryRun)
    checkFastqSuffixes(args)
    makeMd5(args, ex)
    counts = getCounts(args)

    for filename1 in sorted(counts, key=_key):
        first = True
        for filename2 in sorted(counts[filename1], key=_key):
            count1, count2, common = counts[filename1][filename2]
            if first:
                print('%s (%d reads)' % (shortFilename(filename1), count1))
                first = False
            print('   %6d common reads (%5.2f%%, %5.2f%%): %s (%d reads)' %
                  (common, common / count1 * 100.0, common / count2 * 100.0,
                   shortFilename(filename2), count2))

    if args.dryRun:
        print('\n'.join(ex.log))


if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='Detect possible index bleeds between sample FASTQ files.')

    parser.add_argument(
        'fastq', metavar='FASTQ1,FASTQ2,...', nargs='+',
        help='The files to examine for matching sequences.')

    parser.add_argument(
        '--outDir', required=True, default='.',
        help='The directory into which to write FASTQ files of common reads.')

    parser.add_argument(
        '--dryRun', action='store_true', default=False,
        help='Do not execute commands, just show what would be done.')

    parser.add_argument(
        '--verbose', action='store_true', default=False,
        help='Print information about processing.')

    parser.add_argument(
        '--force', action='store_true', default=False,
        help='Overwrite pre-existing output files.')

    args = parser.parse_args()

    main(args)
