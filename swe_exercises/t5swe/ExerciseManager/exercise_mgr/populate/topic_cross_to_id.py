from typing import Iterator
import re
import csv


def topic_cross_to_id(lines: Iterator[str]) -> Iterator[str]:
    reader = csv.reader(lines, delimiter=";", quotechar='"')
    for row in reader:
        a = row[0]
        for i, col in enumerate(row[1:]):
            if "Ü" in col:
                # If more than one related exercise is included,
                # they are wrapped in quotation marks and separated
                # by semicolons internally
                a += " " + col.replace('"', "").replace(";", " ")
            if col == "X":
                i += 1
                if i < 4:
                    a += " " + str(i + 14)
                else:
                    a += " " + str(i + 12)
        if a[0][0] == "Ü":
            yield re.sub(r"\s+", ",", a)
