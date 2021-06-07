import csv

import exercise_mgr.database.sqlite_wrapper as s
from pathlib import Path
from exercise_mgr.Settings import Settings

source_dir = Path(__file__).parent
path_topics = source_dir / "#IBN-Uebungsthemen (2010-2019).csv"
path_topics_names = source_dir / "topic_names.txt"


def split_source_file():
    with path_topics.open("r", encoding="utf-8") as file:
        lines = file.readlines()
        csv_reader = csv.reader(lines[0:2], delimiter=";")
        for n, row in enumerate(csv_reader):
            if n == 0:
                # write parent topics
                topic_names = "\n".join(filter(None, row[6:]))
                # Rechenaufgabe and Programmieraufgabe are exceptions since the filter will need to work differently
                # and they are parent topics without subtopics
                topic_names += "\nProgrammieraufgabe\nRechenaufgabe\n"

                parent_topics = row[6:]
            if n == 1:
                subtopics = row[6:]

        count = 0
        for n in range(len(parent_topics)):
            if parent_topics[n] is not "":
                count += 1
            subtopics[n] += "#" + str(count)
        topic_names += "\n".join(subtopics)
    with path_topics_names.open("w+", encoding="utf-8") as file:
        file.write(topic_names)


def main(database):
    conn = s.create_connection(database)
    with conn:
        conn.execute("""DELETE FROM topics""")
        conn.execute("""DELETE FROM lectures""")
        lecture = s.lecture_insert(conn, (None, "ibn"))
        with path_topics_names.open("r", encoding="utf-8") as file:
            lines = file.read().splitlines()
            topics = []
            for line in lines:
                line = line
                if line.find("#") != -1:
                    (topic_name, parent_topic_id) = line.split("#")
                    parent_topic_id = int(parent_topic_id)
                else:
                    topic_name = line
                    parent_topic_id = None
                topics.append((None, topic_name, parent_topic_id, lecture, None))
            for t in topics:
                s.topic_insert(conn, t)


if __name__ == "__main__":
    split_source_file()
    main(Settings.database)
