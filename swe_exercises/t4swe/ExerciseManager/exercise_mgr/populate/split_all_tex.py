from typing import Tuple, Iterator
from pathlib import Path
import re


exercise_name_re = re.compile(r"^[a-z]+(\d+)\-([a-z]+)\-(\d{4})\.(.*)$")


def extract_year_and_problem_set_number(file_path: str) -> Tuple[str, str]:
    file_name = Path(file_path).name
    match = exercise_name_re.match(file_name)
    if match is None:
        raise ValueError(f"File name {file_name} does not match exercise name pattern")
    exercise_num = match.group(1)
    year = match.group(3)
    return year, exercise_num


def create_exercise_out_comment(file_path: str, ex_count: int) -> str:
    year, exercise_num = extract_year_and_problem_set_number(file_path)
    return f"% ---new_exercise year:{year}, ps:{exercise_num}, exnum:{ex_count}"


def read_problemset(file_path: str) -> Iterator[str]:
    with open(file_path, encoding="utf-8") as f:
        for line in f:
            yield line


def save_header_and_exercises(
    input_path: str, out_path: Path, exercises: Iterator[Tuple[int, str]]
):
    with out_path.open(mode="w", encoding="utf-8") as output_file:
        for ex_count, text in exercises:
            out_comment = create_exercise_out_comment(input_path, ex_count)
            output_file.write(out_comment + "\n")
            output_file.write(text)


def split_problemset_into_header_and_exercises(
    lines: Iterator[str],
) -> Iterator[Tuple[int, str]]:
    # takes a latex file and separates the individual exercises into folder out_path
    buffer = ""
    ex_count = 0
    stop_string = "aufgabe{"

    for line in lines:
        if stop_string in line:
            # lyx export does not always put \aufgabe in new line
            target = "\\aufgabe"
            target_index = line.find(target)
            if target_index == -1:
                before_target = line
                after_target = ""
            else:
                before_target = line[:target_index]
                after_target = line[target_index:]

            buffer += before_target
            yield ex_count, buffer

            ex_count += 1
            buffer = after_target
            if not buffer.endswith("\n"):
                buffer += "\n"

        elif "\\end{document}" not in line:
            buffer += line
            if not buffer.endswith("\n"):
                buffer += "\n"

    yield ex_count, buffer
