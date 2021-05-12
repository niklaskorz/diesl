import os


def notes_to_comments(infile, outfile):
    with open(infile, "r", encoding="utf-8") as f:
        lines = f.read()
        lines = lines.replace("Note Note", "Note Comment")
    with open(outfile, "w+", encoding="utf-8") as out:
        out.write(lines)


def lyx_to_latex(lyxfile):
    os.system("lyx -e pdflatex " + lyxfile)
