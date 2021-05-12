from pathlib import Path
import re


exercise_name_re = re.compile(r"^ueb(\d+)\-([a-z]+)\-(\d{4})\.lyx$")


def create_exercise_out_name(file_path: str, ex_count: int) -> str:
    file_name = Path(file_path).name
    match = exercise_name_re.match(file_name)
    if match is None:
        raise ValueError(f"File name {file_name} does not match exercise name pattern")
    exercise_num = match.group(1)
    year = match.group(3)
    return f"Ü-{year}-{exercise_num}-{ex_count}.tex"


def separate_exercises(latex_file: str, out_folder: Path):
    # takes a latex file and separates the individual exercises into folder out_path
    work_array = []
    ex_count = 0

    with open(latex_file, encoding="utf-8") as input_file:
        stop_string = "aufgabe{"

        for line in input_file:
            if stop_string in line:
                out_name = create_exercise_out_name(latex_file, ex_count)
                ex_count += 1

                # lyx export does not always put \aufgabe in new line
                target = "\\aufgabe"
                target_index = line.find(target)
                if target_index == -1:
                    before_target = line
                    after_target = ""
                else:
                    before_target = line[:target_index]
                    after_target = line[target_index:]

                work_array.append(before_target)
                with open(
                    out_folder.absolute() / out_name,
                    "w+",
                    encoding="utf-8",
                ) as output_file:
                    output_file.writelines(work_array)
                work_array = [after_target]

            elif "\\end{document}" not in line:
                work_array.append(line)

    out_name = create_exercise_out_name(latex_file, ex_count)
    with open(
        out_folder.absolute() / out_name, "w+", encoding="utf-8"
    ) as output_file:
        output_file.writelines(work_array)
