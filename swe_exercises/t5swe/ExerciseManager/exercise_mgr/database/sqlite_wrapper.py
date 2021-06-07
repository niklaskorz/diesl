import sqlite3
from exercise_mgr.gui.Kivy.data import Exercise


def create_connection(db_file):
    conn = None
    try:
        conn = sqlite3.connect(db_file)
    except sqlite3.Error as e:
        print(e)
    return conn


def topic_insert(conn, topic):
    sql = ''' INSERT INTO topics(topic_id, topic_name, parent_topic_id, lecture_id, tag) VALUES(?,?,?,?,?) '''
    c = conn.cursor()
    c.execute(sql, topic)
    return c.lastrowid


# TODO make to create new exercise with all needed things
def save_as_new_instance_of_exercise_family(conn, exercise_family_id, content, exercise_name):
    exercise_name = "test_create_new"
    content = "some content"
    create_new_exercise(conn, [exercise_name, content], exercise_family_id)
    id_sql = '''    select MAX(exercise_text_id)
                    from exercise_texts'''
    c = conn.cursor()
    c.execute(id_sql)
    new_id = c.fetchone()
    new_id = new_id[0] + 1
    exercise = (new_id, exercise_family_id, exercise_name, content)
    exercise_text_insert(conn, exercise)
    conn.commit()
    conn.close()


def create_new_exercise(conn, exercise, exercise_fam_id, problem_set_id=None, attachement_id=None):
    """

    :param conn: connection to database
    :param exercise: [exercise_name, exercise_content]  -> exercise_id will be created
    :param exercise_fam_id: int
    :param problem_set_id: int
    :param attachement_id: int
    :return:
    """
    exercise = [None, exercise_fam_id, exercise[0], exercise[1]]

    sql = '''INSERT INTO exercise_texts(exercise_text_id, exercise_family_id, exercise_name, content) VALUES(?,?,?,?)'''
    c = conn.cursor()
    c.execute(sql, exercise)

    last_row_id = c.lastrowid
    sql = '''INSERT INTO exercise_to_problem_set(exercise_text_id, problem_set_id) VALUES(?,?)'''
    c = conn.cursor()
    c.execute(sql, [last_row_id, problem_set_id])

    sql = '''INSERT INTO attachment_to_exercise(exercise_text_id, attachment_id) VALUES(?,?)'''
    c = conn.cursor()
    c.execute(sql, [last_row_id, attachement_id])




def exercise_text_insert(conn, exercise):
    sql = '''INSERT INTO exercise_texts(exercise_text_id, exercise_family_id, exercise_name, content) VALUES(?,?,?,?)'''
    c = conn.cursor()
    c.execute(sql, exercise)
    return c.lastrowid


def attachment_insert(conn, attachment):
    sql = '''INSERT INTO attachments(attachment_id, content, attachment_type) VALUES(?,?,?)'''
    c = conn.cursor()
    c.execute(sql, attachment)
    return c.lastrowid


def lecture_insert(conn, lecture):
    sql = '''INSERT INTO lectures(lecture_id, lecture_name) VALUES(?,?)'''
    c = conn.cursor()
    c.execute(sql, lecture)
    return c.lastrowid


def exercise_to_problem_set_insert(conn, exercise_to_problem_set):
    sql = '''INSERT INTO exercise_to_problem_set(exercise_text_id, problem_set_id, exercise_num, points)
    VALUES(?,?,?,?) '''
    c = conn.cursor()
    c.execute(sql, exercise_to_problem_set)
    return c.lastrowid


def problem_set_insert(conn, problem_set):
    sql = '''INSERT INTO problem_sets(problem_set_id, points_total, deadline, lecture_id, problem_set_num, semester)
    VALUES(?,?,?,?,?,?)'''
    c = conn.cursor()
    c.execute(sql, problem_set)
    return c.lastrowid


def exercise_family_to_topic_insert(conn, exercise_family_to_topic):
    sql = '''INSERT INTO exercise_family_to_topic(exercise_family_id, topic_id) VALUES(?,?)'''
    c = conn.cursor()
    c.execute(sql, exercise_family_to_topic)
    return c.lastrowid


def attachment_to_exercise_insert(conn, attachment_to_exercise):
    sql = '''INSERT INTO attachment_to_exercise(exercise_text_id, attachment_id) VALUES(?,?)'''
    c = conn.cursor()
    c.execute(sql, attachment_to_exercise)
    return c.lastrowid


def exercise_family_insert(conn, exercise_family):
    sql = '''INSERT INTO exercise_families(exercise_family_id, last_used, parent_exercise_family_id) VALUES(?,?,?)'''
    c = conn.cursor()
    c.execute(sql, exercise_family)
    return c.lastrowid


def exercise_texts_overwrite(conn, exercise_id, text):
    sql = '''UPDATE exercise_texts 
             set content = ?
             where exercise_text_id = ?'''
    c = conn.cursor()
    c.execute(sql, (text, exercise_id))
    conn.commit()
    conn.close()


def save_new_empty_header(conn):
    """
    if there is no header left this function will be called to create a dummy header that you can edit afterwards
    :param conn:
    :return:
    """
    exercise = (-1, -1, "header", "please paste your header here and overwrite")
    exercise_text_insert(conn, exercise)
    conn.commit()
    conn.close()


def get_topic_id_by_name(conn, topic_name):
    sql = '''select topic_id
             from topics
             where topic_name = ?'''
    c = conn.cursor()
    c.execute(sql, [topic_name])
    topic_id = c.fetchall()
    copy = list(topic_id[0])
    return copy


def get_descriptive_filteroption_of_exercise_fam(conn, exercise_fam_id):
    sql = '''select topic_name
             from exercise_family_to_topic, topics
             where exercise_family_id = ?
             and topics.topic_id = exercise_family_to_topic.topic_id
             and topics.parent_topic_id is NULL'''
    c = conn.cursor()
    c.execute(sql, [exercise_fam_id])
    fetchall = c.fetchall()
    temp = []
    for item in fetchall:
        temp.append(item[0])
    return temp


def get_topics_of_exercise_fam(conn, exercise_fam_id):
    sql = '''select topic_name
             from exercise_family_to_topic, topics
             where exercise_family_id = ?
             and topics.topic_id = exercise_family_to_topic.topic_id
             and topics.parent_topic_id is not NULL'''
    c = conn.cursor()
    c.execute(sql, [exercise_fam_id])
    fetchall = c.fetchall()
    temp = []
    for item in fetchall:
        temp.append(item[0])
    return temp


def remove_all_exercise_fam_to_topic_relation(conn, exercise_fam_id):
    sql = '''Delete 
             from exercise_family_to_topic
             where exercise_family_id = ?'''
    c = conn.cursor()
    c.execute(sql, (exercise_fam_id,))
    conn.commit()


def update_via_popup(exercise_fam_id, selected_topics, selected_subscriptive_filteroptions, conn):
    """
    updates the database based on the selections made in EditPopup
    :param exercise_fam_id: (int)
    :param selected_topics: (list)
    :param selected_subscriptive_filteroptions: (list)
    :param conn:
    :return:
    """
    remove_all_exercise_fam_to_topic_relation(conn, exercise_fam_id)
    for topic in selected_topics:
        topic_id = get_topic_id_by_name(conn, topic)
        exercise_family_to_topic_insert(conn, (exercise_fam_id, topic_id[0]))
    for descriptive_filteroption in selected_subscriptive_filteroptions:
        descriptive_filteroption_id = get_topic_id_by_name(conn, descriptive_filteroption)
        exercise_family_to_topic_insert(conn, (exercise_fam_id, descriptive_filteroption_id[0]))
    conn.commit()
    conn.close()


def delete_by_id_from_exercise_texts(conn, exercise_text_id):
    sql = '''   DELETE FROM exercise_texts
                where exercise_text_id = ?'''
    with conn:
        c = conn.cursor()
        c.execute(sql, (exercise_text_id,))


def get_filter_matching_exercises(conn, filter):
    """
returns all exercises matching the filter
    @param conn: connection to database
    @param filter: filter[0] is selected topics in an array
                   filter[1] is selected year as int (e.g 2016)
                   filter[2] is selected exercise descriptive filter options (e.g Rechenaufgabe, Programmieraufgabe)
    @return: list of exercise-instances
    """
    with conn:
        #  get all exercises that have never been used -> no semester
        sql = '''select et.exercise_text_id, et.exercise_family_id, exercise_name, content, topic_name
                     from exercise_to_problem_set, exercise_texts et, topics t, exercise_family_to_topic eft
                     where et.exercise_text_id = exercise_to_problem_set.exercise_text_id
                     and et.exercise_family_id = eft.exercise_family_id
                     and t.topic_id = eft.topic_id
                     and problem_set_id is NULL'''

        c = conn.cursor()
        c.execute(sql)
        exercises_no_semester = list(c.fetchall())
        #  adjust them so they have values for semester/last used
        for index, exercise_no_sem in enumerate(exercises_no_semester):
            exercises_no_semester[index] = list(exercise_no_sem) + [None]


        #  NOTE that semester is filtered in sql but not the other filters because sqlite does not support array operations
        sql = '''   SELECT e.exercise_text_id, e.exercise_family_id, exercise_name, content, t.topic_name, ps.semester
                    FROM 'topics' t, 'exercise_family_to_topic' eft, 'exercise_texts' e, 'exercise_families' ef, 
                    'exercise_to_problem_set' etps, 'problem_sets' ps 
                    where e.exercise_family_id = eft.exercise_family_id
                    and eft.topic_id = t.topic_id
                    and ef.exercise_family_id = e.exercise_family_id
                    and etps.exercise_text_id = e.exercise_text_id
                    and etps.problem_set_id = ps.problem_set_id
                    and ps.semester <= ?
                    order by e.exercise_text_id DESC'''
        c = conn.cursor()
        semester = filter[1]
        semester = int(semester[-2::])
        c.execute(sql, (semester,))
        exercises_with_semester = list(c.fetchall())

        # add exercises with last used semester and those exercises that have never been used (e.g new ones) and sort by
        # exercise_text_id
        all_exercises = exercises_no_semester + exercises_with_semester
        all_exercises.sort(key=lambda item: item[0], reverse=True)

        """
        exercise = (0:exercise_text_id, 1:exercise_family_id, 2:exercise_name, 3:content, 4:topic_name, 5:semester) 
        """
        exercises = []
        last_id = -2
        #  creates Exercise classes, stores exercises with several topics in 1 instance, works because array is sorted
        for exercise_index in range(len(all_exercises)):
            if last_id == all_exercises[exercise_index][0]:
                exercises[-1].add_topic(all_exercises[exercise_index][4])
            else:
                exercises.append(Exercise(all_exercises[exercise_index]))
                last_id = exercises[-1].get_exercise_text_id()

        #  filters topics and exercise descriptive filter options (e.g. Rechenaufgabe), semester is already filtered in sql
        filtered = []
        for exercise in exercises:
            filter_satisfied = [0, 0]
            for topic in exercise.get_topic():
                if topic in filter[0]:
                    filter_satisfied[0] = 1
                if not filter[2]:
                    filter_satisfied[1] = 1  # if this filteroption is not selected it shouldn't influence the outcome
                if topic in filter[2]:
                    filter_satisfied[0] = 1  # some exercises are ONLY "Rechenaufgabe", they would never show otherwise
                    filter_satisfied[1] = 1
            if filter_satisfied == [1, 1]:
                filtered.append(exercise)

        fam_id_added_execises = []
        array_exercise_families = []
        array_exercise_families_indexes = []
        # groups exercise families in an array and append them to data-array that will be returned
        for exercise in filtered:
            if exercise.get_exercise_family_id() not in fam_id_added_execises:
                fam_id_added_execises.append(exercise.get_exercise_family_id())
                add_array = [exercise]
                array_exercise_families_indexes.append(exercise.get_exercise_family_id())
                array_exercise_families.append(add_array)
            else:
                index = array_exercise_families_indexes.index(exercise.get_exercise_family_id())
                array_exercise_families[index].append(exercise)
        all_exercises = array_exercise_families
    return all_exercises


def get_exercise_id(conn, semester, problem_set_number, exercise_number):
    sql = '''   SELECT * FROM exercise_to_problem_set as e,problem_sets as ps
                WHERE ps.semester=? AND ps.problem_set_num=? AND e.exercise_num=?'''
    c = conn.cursor()
    c.execute(sql, (semester, (semester, problem_set_number, exercise_number)))
    return c.lastrowid


def get_my_header(conn):
    sql = '''   SELECT * 
                FROM exercise_texts
                WHERE exercise_family_id = 0 order by  exercise_text_id desc'''
    c = conn.cursor()
    c.execute(sql)
    res = c.fetchall()
    conn.close()
    return res


def get_topics(conn):
    with conn:
        conn.row_factory = lambda cursor, row: row[0]
        c = conn.cursor()
        c.execute("""select topic_name from topics where parent_topic_id IS NOT NULL""")
        array = c.fetchall()
        return array


def get_parent_topics(conn):
    pass


def get_exercise_describtive_filteroptions(conn):
    sql = '''select topic_name
             from topics t
             where t.parent_topic_id is NULL
             and not exists( select *
                             from topics
                             where parent_topic_id = t.topic_id)'''
    with conn:
        c = conn.cursor()
        c.execute(sql)
        temp = []
        for item in c.fetchall():
            temp.append(item[0])
        return temp


def get_parent_topics(conn):
    sql = '''select topic_name
             from topics t
             where t.parent_topic_id is NULL
             and exists( select *
                         from topics
                         where parent_topic_id = t.topic_id)'''
    with conn:
        c = conn.cursor()
        c.execute(sql)
        temp = []
        for item in c.fetchall():
            temp.append(item[0])
        return temp


def get_subtopics(conn):
    with conn:
        c = conn.cursor()
        c.execute("""select topic_name, parent_topic_id from topics""")
        a = c.fetchall()
        b = {}
        c = []
        for i, item in enumerate(a):
            if item[1] is None:
                c.append(i)
        for val in c:
            d = []
            for item in a:
                if item[1] == val + 1:
                    d.append(item[0])
            b[a[val][0]] = d
        return b


def get_exercise_count(conn):
    with conn:
        c = conn.cursor()
        c.execute("""select * from main.exercise_texts""")
        return len(c.fetchall())
