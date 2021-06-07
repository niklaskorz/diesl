from typing import Optional
import re


def topic_cross_to_id(line: str) -> Optional[str]:
    split = line.split(";")
    a = split[0]
    for i in range(1, len(split) - 1):
        if "Ü" in split[i]:
            a += " " + split[i].replace('"', "")
        if split[i] == "X":
            if i < 4:
                a += " " + str(i + 14)
            else:
                a += " " + str(i + 12)
    if a[0][0] == "Ü":
        return re.sub(r"\s+", ",", a)
    return None
