import json
from pathlib import Path
import exercise_mgr.database.sqlite_wrapper as s
from exercise_mgr.Settings import Settings


def s_ps_en_from_string(filename):
    banana = filename.split("-")
    return banana[1:4]


def write_all_semester(conn):
    with open(
        Path(__file__).parent / "topics.json", "r", encoding="utf8"
    ) as topics_json:
        topics = json.load(topics_json)
    directories = [Settings.files / str(i) / "split" for i in [12, 19, 20]]
    paths = [f for f_ in [d.glob("*.tex") for d in directories] for f in f_]
    for topic in topics:
        topics[topic].append("")
    for topic in topics:
        if topics[topic][2] == "":
            ef = s.exercise_family_insert(conn, (None, None, None))
            topics[topic][2] = ef
            for other in topics[topic][0]:
                if other in topics and topics[other][2] == "":
                    topics[other][2] = topics[topic][2]
    for topic in topics:
        for topic_id in topics[topic][1]:
            s.exercise_family_to_topic_insert(conn, (topics[topic][2], topic_id))
    exercise_texts = {}
    no_topics = []
    for path in paths:
        if path.stem in topics:
            exercise_texts[path.stem] = [
                path,
                s_ps_en_from_string(path.stem),
                topics[path.stem][2],
            ]
        for topic in topics:
            if path.stem in topics[topic][0]:
                exercise_texts[path.stem] = [
                    path,
                    s_ps_en_from_string(path.stem),
                    topics[topic][2],
                ]
        if s_ps_en_from_string(path.stem)[2] == "0":
            exercise_texts[path.stem] = [path, s_ps_en_from_string(path.stem), 0]
        if path.stem not in exercise_texts:
            no_topics.append(path.stem)
    problem_sets = []
    for exercise_text in exercise_texts:
        if exercise_texts[exercise_text][1][0:2] not in problem_sets:
            problem_sets.append(exercise_texts[exercise_text][1][0:2])
    for problem_set in problem_sets:
        ps = s.problem_set_insert(
            conn, (None, None, None, 1, problem_set[1], problem_set[0])
        )
        problem_set.append(ps)
    for exercise_text in exercise_texts:
        with open(exercise_texts[exercise_text][0], encoding="utf-8") as file:
            content = file.read()
            points = content[(content.find("{") + 1) : content.find("}")]
        et = s.exercise_text_insert(
            conn, (None, exercise_texts[exercise_text][2], exercise_text, content)
        )
        ps = -1
        for problem_set in problem_sets:
            if problem_set[0:2] == exercise_texts[exercise_text][1][0:2]:
                ps = problem_set[2]
        s.exercise_to_problem_set_insert(
            conn, (et, ps, exercise_texts[exercise_text][1][2], points)
        )


def main(database):
    with s.create_connection(database) as conn:
        conn.execute("""DELETE FROM exercise_family_to_topic""")
        conn.execute("""DELETE FROM exercise_to_problem_set""")
        conn.execute("""DELETE FROM exercise_texts""")
        conn.execute("""DELETE FROM exercise_families""")
        conn.execute("""DELETE FROM problem_sets""")
        write_all_semester(conn)


if __name__ == "__main__":
    main(Settings.database)
