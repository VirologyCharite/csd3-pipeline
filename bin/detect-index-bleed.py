#!/usr/bin/env python

import sys
import argparse
from os.path import dirname, exists, join
from collections import defaultdict

from dark.process import Executor

from csd3lib.comm import commonReads


def _key(s):
    return int(s.split('_')[2])


def shortFilename(filename):
    return filename.split('/')[0]


def veryShortFilename(filename):
    return '_'.join(shortFilename(filename).split('_')[2:4])


def filenameLT(f1, f2):
    return _key(f1) < _key(f2)


def checkFastqSuffixes(args):
    for filename in args.fastq:
        if not filename.endswith('.fastq'):
            raise ValueError('Found non-FASTQ filename %r.' % filename)


def getCommonCounts(args):
    duplicates = defaultdict(set)
    counts = defaultdict(dict)
    for filename1 in args.fastq:
        md5Filename1 = filename1[:-len('fastq')] + 'md5'
        for filename2 in args.fastq:
            if filenameLT(filename1, filename2):
                md5Filename2 = filename2[:-len('fastq')] + 'md5'
                if args.dryRun:
                    counts[filename1][filename2] = 0
                else:
                    with open(md5Filename1) as fp1:
                        with open(md5Filename2) as fp2:
                            nonU1, nonU2 = commonReads(fp1, fp2)
                            assert len(nonU1) == len(nonU2)
                            duplicates[filename1].update(nonU1)
                            duplicates[filename2].update(nonU2)
                            counts[filename1][filename2] = len(nonU1)

    return counts, duplicates


def getMd5s(args, ex):
    fastqFilenames = []
    md5Filenames = []

    for filename in args.fastq:

        md5Filename = filename[:-len('fastq')] + 'md5'

        if not exists(md5Filename) or args.force:
            fastqFilenames.append(filename)
            md5Filenames.append(md5Filename)

    if fastqFilenames:
        if args.verbose:
            print('Generating .md5 files for %d FASTQ files:' %
                  len(fastqFilenames), file=sys.stderr)
            for filename in fastqFilenames:
                print('  ', filename, file=sys.stderr)

        ex.execute(
            'parallel "format-fasta.py --fastq --format '
            '\'%%(md5)s %%(id)s\' < {} > {.}.md5" ::: %s' %
            ' '.join("'%s'" % filename for filename in fastqFilenames))

        ex.execute('parallel "sort -o {} {}" ::: %s' %
                   ' '.join("'%s'" % filename for filename in md5Filenames))
    else:
        if args.verbose:
            print('All .md5 files already present. Use --force to overwrite.',
                  file=sys.stderr)


def getReadCounts(args, ex):
    """
    Get the total number of reads in each input file.

    @return: A C{dict} keyed by C{str} filename with C{int} read count values.
    """
    fastqFilenames = []
    countFilenames = []

    for filename in args.fastq:

        countFilename = filename[:-len('fastq')] + 'count'

        if not exists(countFilename) or args.force:
            fastqFilenames.append(filename)
            countFilenames.append(countFilename)

    if fastqFilenames:
        if args.verbose:
            print('Generating .count files for %d FASTQ files:' %
                  len(fastqFilenames), file=sys.stderr)
            for filename in fastqFilenames:
                print('  ', filename, file=sys.stderr)

        ex.execute(
            'parallel "fasta-count.py --fastq < {} > {.}.count" ::: %s' %
            ' '.join("'%s'" % filename for filename in fastqFilenames))
    else:
        if args.verbose:
            print('All .count files already present. Use --force to '
                  'overwrite.', file=sys.stderr)

    counts = {}

    for filename in args.fastq:
        countFilename = filename[:-len('fastq')] + 'count'
        counts[filename] = int(open(countFilename).read())

    return counts


def saveDuplicateIds(args, duplicates):
    fastqFilenames = []
    dupsFilenames = []

    for filename in args.fastq:

        dupsFilename = filename[:-len('fastq')] + 'dups'

        if not exists(dupsFilename) or args.force:
            fastqFilenames.append(filename)
            dupsFilenames.append(dupsFilename)

    if fastqFilenames:
        if args.verbose:
            print('Writing .dups files for %d FASTQ files:' %
                  len(fastqFilenames), file=sys.stderr)
            for filename in fastqFilenames:
                print('  ', filename, file=sys.stderr)

        for fastqFilename, dupsFilename in zip(fastqFilenames, dupsFilenames):
            with open(dupsFilename, 'w') as fp:
                for id_ in sorted(duplicates[fastqFilename]):
                    print(id_, file=fp)
    else:
        if args.verbose:
            print('All .dups files already present. Use --force to '
                  'overwrite.', file=sys.stderr)


def saveCommonCounts(args, commonCounts):
    for filename1 in args.fastq:
        shortFilename1 = shortFilename(filename1)
        for filename2 in args.fastq:
            if filename1 == filename2:
                continue
            shortFilename2 = shortFilename(filename2)
            if filenameLT(filename1, filename2):
                count = commonCounts[filename1][filename2]
            else:
                count = commonCounts[filename2][filename1]

            filename = join(dirname(filename1), '%s-versus-%s.count' %
                            (shortFilename1, shortFilename2))

            if args.dryRun:
                print('Would write count %d to %s' % (count, filename),
                      file=sys.stderr)
            else:
                if exists(filename) and not args.force:
                    print('Common count file %s already exists. Use --force '
                          'to overwrite.' % filename, file=sys.stderr)
                    continue
                with open(filename, 'w') as fp:
                    print(str(count), file=fp)


def saveCommonCountsCsv(args, commonCounts, readsCounts):
    with open(args.csvfile, 'w') as fp:
        # Header.
        print(
            'ID,' +
            ','.join(veryShortFilename(filename)
                     for filename in sorted(args.fastq, key=_key)),
            end=',Count\n', file=fp)

        for filename1 in sorted(args.fastq, key=_key):
            values = [veryShortFilename(filename1)]
            for filename2 in sorted(args.fastq, key=_key):
                if filename1 == filename2:
                    values.append('')
                elif filenameLT(filename1, filename2):
                    values.append(commonCounts[filename1][filename2] or '')
                else:
                    values.append(commonCounts[filename2][filename1] or '')

            values.append(readsCounts[filename1])

            print(','.join(map(str, values)), file=fp)


def main(args):
    ex = Executor(args.dryRun)
    checkFastqSuffixes(args)
    readCounts = getReadCounts(args, ex)
    getMd5s(args, ex)
    commonCounts, duplicates = getCommonCounts(args)
    saveDuplicateIds(args, duplicates)
    saveCommonCounts(args, commonCounts)
    if args.csvfile:
        saveCommonCountsCsv(args, commonCounts, readCounts)

    for filename1 in sorted(commonCounts, key=_key):
        first = True
        for filename2 in sorted(commonCounts[filename1], key=_key):
            common = commonCounts[filename1][filename2]
            if common:
                count1 = readCounts[filename1]
                count2 = readCounts[filename2]
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
        '--csvfile',
        help='A CVS file to write common counts to.')

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
