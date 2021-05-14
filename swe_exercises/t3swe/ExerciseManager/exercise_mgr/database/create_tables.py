from sqlite3 import Error


def table_attachments(conn):
    try:
        sql = '''
        CREATE TABLE IF NOT EXISTS attachments(
            attachment_id integer,
            content blob,
            attachment_type text,
            PRIMARY KEY (attachment_id)
        );'''
        c = conn.cursor()
        c.execute(sql)
    except Error as e:
        print(e)


def table_lectures(conn):
    try:
        sql = '''
        CREATE TABLE IF NOT EXISTS lectures(
            lecture_id integer,
            lecture_name text,
            PRIMARY KEY (lecture_id)
        );'''
        c = conn.cursor()
        c.execute(sql)
    except Error as e:
        print(e)


def table_topics(conn):
    try:
        sql = '''
        CREATE TABLE IF NOT EXISTS topics(
            topic_id integer,
            topic_name text,
            parent_topic_id integer,
            lecture_id integer,
            tag text,
            PRIMARY KEY (topic_id),
            FOREIGN KEY (lecture_id) REFERENCES lectures(lecture_id),
            FOREIGN KEY (parent_topic_id) REFERENCES topics(topic_id)
        );'''
        c = conn.cursor()
        c.execute(sql)
    except Error as e:
        print(e)


def table_problem_sets(conn):
    try:
        sql = '''
        CREATE TABLE IF NOT EXISTS problem_sets(
            problem_set_id integer,
            points_total integer,
            deadline date,
            lecture_id integer,
            problem_set_num int,
            semester text,
            PRIMARY KEY (problem_set_id),
            FOREIGN KEY (lecture_id) REFERENCES lectures(lecture_id)
        );'''
        c = conn.cursor()
        c.execute(sql)
    except Error as e:
        print(e)


def table_exercise_families(conn):
    try:
        sql = '''
        CREATE TABLE IF NOT EXISTS exercise_families(
            exercise_family_id integer,
            last_used date,
            parent_exercise_family_id integer,
            PRIMARY KEY (exercise_family_id),
            FOREIGN KEY (parent_exercise_family_id) REFERENCES exercise_families(exercise_family_id)
        );'''
        c = conn.cursor()
        c.execute(sql)
    except Error as e:
        print(e)


def table_exercise_texts(conn):
    try:
        sql = '''
        CREATE TABLE IF NOT EXISTS exercise_texts(
            exercise_text_id integer,
            exercise_family_id integer,
            exercise_name text,
            content blob,
            PRIMARY KEY (exercise_text_id),
            FOREIGN KEY (exercise_family_id) REFERENCES exercise_families(exercise_family_id)
        );'''
        c = conn.cursor()
        c.execute(sql)
    except Error as e:
        print(e)


def table_attachment_to_exercise(conn):
    try:
        sql = '''
        CREATE TABLE IF NOT EXISTS attachment_to_exercise(
            exercise_text_id integer,
            attachment_id integer,
            PRIMARY KEY (exercise_text_id, attachment_id),
            FOREIGN KEY (exercise_text_id) REFERENCES exercise_texts(exercise_text_id)
                ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY (attachment_id) REFERENCES attachments(attachment_id)
                ON DELETE CASCADE ON UPDATE CASCADE
        );'''
        c = conn.cursor()
        c.execute(sql)
    except Error as e:
        print(e)


def table_exercise_to_problem_set(conn):
    try:
        sql = '''
        CREATE TABLE IF NOT EXISTS exercise_to_problem_set(
            exercise_text_id integer,
            problem_set_id integer,
            exercise_num integer,
            points integer,
            PRIMARY KEY (exercise_text_id, problem_set_id),
            FOREIGN KEY (exercise_text_id) REFERENCES exercise_texts(exercise_text_id)
                ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY (problem_set_id) REFERENCES problem_sets(problem_set_id)
                ON DELETE CASCADE ON UPDATE CASCADE
        );'''
        c = conn.cursor()
        c.execute(sql)
    except Error as e:
        print(e)


def table_exercise_family_to_topic(conn):
    try:
        sql = '''
        CREATE TABLE IF NOT EXISTS exercise_family_to_topic(
            exercise_family_id integer,
            topic_id integer,
            PRIMARY KEY (exercise_family_id, topic_id),
            FOREIGN KEY (exercise_family_id) REFERENCES exercise_families(exercise_family_id)
                ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY (topic_id) REFERENCES topics(topic_id)
                ON DELETE CASCADE ON UPDATE CASCADE
        );'''
        c = conn.cursor()
        c.execute(sql)
    except Error as e:
        print(e)


def create_all_tables(conn):
    table_attachments(conn)
    table_lectures(conn)
    table_topics(conn)
    table_problem_sets(conn)
    table_exercise_families(conn)
    table_exercise_texts(conn)
    table_attachment_to_exercise(conn)
    table_exercise_to_problem_set(conn)
    table_exercise_family_to_topic(conn)
