#!/usr/bin/env python

import sys
import argparse
from glob import glob

from dark.utils import parseRangeExpression

parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description=(
        'Find CIV sample directories for a given range of inc numbers and '
        'print their names to standard output. This is designed to help on '
        'the command line, e.g., in a loop such as for i in $(civ-dirs.py '
        '3-12,15); do ...; done.'))

parser.add_argument(
    'range', metavar='NUMBER,RANGE,...',
    help=('The ranges of directory inc numbers that should be printed. E.g., '
          '1-3,5 will output just the 1st, 2nd, 3rd, and 5th directory '
          'names. All others will be omitted. This option can include '
          'parentheses and Python set operators, e.g. '
          '"(3-5 | 10-12) - 5-10".'))

args = parser.parse_args()

result = []
missing = []

for n in parseRangeExpression(args.range):
    files = glob('[DW]_[0-9][0-9][0-9][0-9][0-9][0-9]_%d_*' % n)
    if len(files) == 1:
        result.append(files[0])
    else:
        missing.append(n)

if missing:
    print('Found no matching directories for %s %s.' %
          ('index' if len(missing) == 1 else 'indices',
           ', '.join(map(str, sorted(missing)))),
          file=sys.stderr)
    sys.exit(1)
else:
    print('\n'.join(result))
