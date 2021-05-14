import sys
from .. import Settings
from . import lyx_to_latex, split_all_tex
from .split_all_tex import (
    read_problemset,
    save_header_and_exercises,
    split_problemset_into_header_and_exercises,
)


def main():
    if not lyx_to_latex.check_lyx():
        print("lyx is not installed or not accessible, aborting")
        sys.executable(1)

    paths = [Settings.files / str(i) for i in range(12, 20)]
    for path in paths:
        files = path.glob("*.lyx")
        (path / "comment").mkdir(exist_ok=True)
        (path / "split").mkdir(exist_ok=True)
        for file in files:
            lyx_to_latex.notes_to_comments(file, (path / "comment" / file.name))
            lyx_to_latex.lyx_to_latex(str(path / "comment" / file.name))
            input_path = str(path / "comment" / (file.stem + ".tex"))
            out_folder = path / "split"
            iter_lines = read_problemset(input_path)
            iter_exercises = split_problemset_into_header_and_exercises(iter_lines)
            save_header_and_exercises(input_path, out_folder, iter_exercises)
        print(path)
    # ueb1-ibn-2012.tex is an exception since it already is a tex file
    split_all_tex.separate_exercises(
        str(Settings.files / "12" / "ueb1-ibn-2012.tex"),
        (Settings.files / "12" / "split"),
    )


if __name__ == "__main__":
    main()
