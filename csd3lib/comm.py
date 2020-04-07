from dark.reads import Reads


def _readOne(fp1, fp2):
    """
    Read one line from C{fp1}.

    @param fp1: An open file.
    @param fp2: An open file.
    @return: The next line from C{fp1} in a 2-tuple (with C{0} as the second
        value). If no line can be read from C{fp1}, return a 2-tuple with
        C{None} as the first value and the C{int} number of lines left in
        C{fp2} as the second item.
    """
    try:
        value = next(fp1)
    except StopIteration:
        count = 0
        for _ in fp2:
            count += 1
        return None, count
    else:
        return value, 0


def countCommon(fp1, fp2):
    """
    Count the number of lines in common in two sorted files.

    @param fp1: An open (sorted) file.
    @param fp2: An open (sorted) file.
    @return: A 3-tuple of C{int}s with the number of lines in C{fp1}, number
        of lines in C{fp2}, and number of lines in common.
    """
    nextFrom = None
    count1 = count2 = common = 0

    while True:
        if nextFrom is None:
            hash1, otherCount = _readOne(fp1, fp2)
            if hash1 is None:
                count2 += otherCount
                break
            else:
                count1 += 1

            hash2, otherCount = _readOne(fp2, fp1)
            if hash2 is None:
                count1 += otherCount
                break
            else:
                count2 += 1

        elif nextFrom == 1:
            hash1, otherCount = _readOne(fp1, fp2)
            if hash1 is None:
                count2 += otherCount
                break
            else:
                count1 += 1

        else:
            hash2, otherCount = _readOne(fp2, fp1)
            if hash2 is None:
                count1 += otherCount
                break
            else:
                count2 += 1

        if hash1 == hash2:
            common += 1
            nextFrom = None
        elif hash1 < hash2:
            nextFrom = 1
        else:
            nextFrom = 2

    return count1, count2, common


def commonReads(fp1, fp2):
    """
    Find the reads ids in common in two sorted files.

    @param fp1: An open (sorted) file of space-separated sequence MD5 sum
        and read id.
    @param fp2: An open (sorted) file of space-separated sequence MD5 sum
        and read id.
    @return: A 2-tuple of C{set}s of C{str} read ids corresponding to the
        sequence MD5 sums that are in common in C{fp1} and C{fp2}.
    """
    nextFrom = None
    ids1 = set()
    ids2 = set()

    try:
        while True:
            if nextFrom is None:
                hash1, id1 = next(fp1).split()
                hash2, id2 = next(fp2).split()
            elif nextFrom == 1:
                hash1, id1 = next(fp1).split()
            else:
                hash2, id2 = next(fp2).split()

            if hash1 == hash2:
                ids1.add(id1)
                ids2.add(id2)
    except StopIteration:
        return ids1, ids2
