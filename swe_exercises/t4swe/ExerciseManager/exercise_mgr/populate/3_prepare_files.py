import sys
from ..Settings import settings
from . import lyx_to_latex, split_all_tex
from .split_all_tex import (
    read_problemset,
    save_header_and_exercises,
    split_problemset_into_header_and_exercises,
)


def main():
    if not lyx_to_latex.check_lyx():
        print("lyx is not installed or not accessible, aborting")
        sys.exit(1)

    paths = [settings.files / str(i) for i in range(19, 21)]
    for path in paths:
        files = path.glob("*.lyx")
        (path / "comment").mkdir(exist_ok=True)
        (path / "split").mkdir(exist_ok=True)
        for file in files:
            lyx_to_latex.notes_to_comments(file, (path / "comment" / file.name))
            lyx_to_latex.lyx_to_latex(str(path / "comment" / file.name))
            input_path = str(path / "comment" / (file.stem + ".tex"))
            out_path = path / "split" / (file.stem + ".tex")
            iter_lines = read_problemset(input_path)
            iter_exercises = split_problemset_into_header_and_exercises(iter_lines)
            save_header_and_exercises(input_path, out_path, iter_exercises)
        print(path)


if __name__ == "__main__":
    main()
