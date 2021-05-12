from pathlib import Path


def get_exercise_num_as_string(filename):
    name = Path(filename).name
    ueb = name[3]
    if name[4] != "-":
        ueb += name[4]
    return ueb


def create_ex_name(filename):
    file = Path(filename).name
    name = "Ü-" + file[-6] + file[-5] + "-" + get_exercise_num_as_string(file) + "-"
    return name


def separate_exercises(latex_file, out_folder):
    # takes a latex file and separates the individual exercises into folder out_path
    work_array = []
    ex_count = 0
    with open(latex_file, encoding="utf-8") as input_file:
        stop_string = "aufgabe{"
        for line in input_file:
            if stop_string in line:
                out_name = create_ex_name(latex_file) + str(ex_count)
                ex_count += 1
                # lyx export does not always put \aufgabe in new line
                a = line.split("\\aufgabe")
                a[1] = "\\aufgabe" + a[1]
                work_array.append(a[0])
                with open(
                    out_folder.absolute() / (out_name + ".tex"),
                    "w+",
                    encoding="utf-8",
                ) as output_file:
                    output_file.writelines(work_array)
                work_array = [a[1]]
            elif "\\end{document}" not in line:
                work_array.append(line)
    out_name = create_ex_name(latex_file) + str(ex_count)
    with open(
        out_folder.absolute() / (out_name + ".tex"), "w+", encoding="utf-8"
    ) as output_file:
        output_file.writelines(work_array)
