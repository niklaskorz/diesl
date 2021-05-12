from pathlib import Path

from exercise_mgr.Settings import Settings
from exercise_mgr.populate import lyx_to_latex, split_all_tex


def main():
    paths = [Settings.files / str(i) for i in range(12, 20)]
    for path in paths:
        files = path.glob("*.lyx")
        (path / "comment").mkdir(exist_ok=True)
        (path / "split").mkdir(exist_ok=True)
        for file in files:
            lyx_to_latex.notes_to_comments(file, (path / "comment" / file.name))
            lyx_to_latex.lyx_to_latex(str(path / "comment" / file.name))
            split_all_tex.separate_exercises(
                str(path / "comment" / (file.stem + ".tex")), (path / "split")
            )
        print(path)
    # ueb1-ibn-2012.tex is an exception since it already is a tex file
    split_all_tex.separate_exercises(
        str(Settings.files / "12" / "ueb1-ibn-2012.tex"),
        (Settings.files / "12" / "split"),
    )


if __name__ == "__main__":
    main()
