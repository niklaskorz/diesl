import subprocess


def notes_to_comments(infile: str, outfile: str):
    with open(infile, "r", encoding="utf-8") as f:
        lines = f.read()
        lines = lines.replace("Note Note", "Note Comment")
    with open(outfile, "w+", encoding="utf-8") as out:
        out.write(lines)


def lyx_to_latex(lyxfile: str):
    # check=True raises a CalledProcessError exception if the program
    # exits with a non-zero exit code.
    # The raised exception includes the stdout and stderr logs.
    subprocess.run(["lyx", "-e", "pdflatex", lyxfile], check=True)


def check_lyx() -> bool:
    """
    Checks if lyx is installed and executable.
    """
    try:
        subprocess.run(["lyx", "--version"], check=True)
    except subprocess.CalledProcessError:
        return False
    return True
