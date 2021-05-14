from pathlib import Path
import re


def detect_attachments(latexfile):
    with open(latexfile, 'r', encoding='utf-8')as f:
        lines = f.readlines()
        attachments = []
        for line in lines:
            if "includegraphics" in line:
                attachment = re.findall('{([^{}]*)}', line)
                attachments.append(attachment[0])
        return attachments


def main():
    """
    the attachment autodetect still has problems, if you execute this file you will find that one of the attachments is
    not saved inside the data bundle but in a different directory
    """
    file = Path('.') / 'ueb12-ibn-2016.tex'
    print(detect_attachments(file))


if __name__ == '__main__':
    main()
