from unittest import TestCase
from io import StringIO

from csd3lib.comm import countCommon


def lines(s=''):
    """
    Make some lines of input by splitting C{s}.
    """
    return StringIO('\n'.join(s.split()) + '\n' if s else '')


class TestCountCommon(TestCase):
    """
    Test the countCommon function.
    """
    def testBothEmpty(self):
        """
        If both files are empty, (0, 0, 0) must be returned.
        """
        self.assertEqual((0, 0, 0), countCommon(lines(), lines()))

    def testFirstEmpty(self):
        """
        If the first file is empty, (0, n, 0) must be returned where
        n is the number of lines in the second file.
        """
        self.assertEqual((0, 2, 0),
                         countCommon(lines(),
                                     lines('hey you')))

    def testSecondEmpty(self):
        """
        If the second file is empty, (n, 0, 0) must be returned where
        n is the number of lines in the first file.
        """
        self.assertEqual((2, 0, 0),
                         countCommon(lines('hey you'),
                                     lines()))

    def testSameLengths(self):
        """
        If both files have the same number of lines but nothing in common,
        (n, n, 0) must be returned, where n is the number of lines.
        """
        self.assertEqual((2, 2, 0),
                         countCommon(lines('ABC DEF'),
                                     lines('1234 5678')))

    def testFirstShorterNothingInCommon(self):
        """
        If the first file is shorter than the second and nothing is in common,
        (n, m, 0) must be returned where n is the number of lines in the first
        file and m is the number in the second file.
        """
        self.assertEqual((2, 4, 0),
                         countCommon(lines('1 2'),
                                     lines('A B C D')))

    def testSecondShorterNothingInCommon(self):
        """
        If the second file is shorter than the first and nothing is in common,
        (n, m, 0) must be returned where n is the number of lines in the first
        file and m is the number in the second file.
        """
        self.assertEqual((4, 2, 0),
                         countCommon(lines('A B C D'),
                                     lines('1 2')))

    def testFirstShorterSomethingInCommon(self):
        """
        If the first file is shorter than the second and there is something in
        common, (n, m, c) must be returned where n is the number of lines in
        the first file, m is the number in the second file, and c is the
        number in common.
        """
        self.assertEqual((7, 4, 2),
                         countCommon(lines('1 2 A B 3 4 5'),
                                     lines('A B C D')))

    def testSecondShorterSomethingInCommon(self):
        """
        If the second file is shorter than the first and there is something in
        common, (n, m, c) must be returned where n is the number of lines in
        the first file, m is the number in the second file, and c is the
        number in common.
        """
        self.assertEqual((4, 7, 2),
                         countCommon(lines('A B C D'),
                                     lines('1 2 A B 3 4 5')))
