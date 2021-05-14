import importlib
import os
from pathlib import Path
import unittest
import exercise_mgr.database.sqlite_wrapper as s


class TestDatabaseFunctionality(unittest.TestCase):
    def setUp(self):
        database = Path(__file__).parent / "testdata" / "test.sqlite"
        create_database = importlib.import_module(".0_create_database", "exercise_mgr.populate")
        populate_topics = importlib.import_module(".1_populate_topics", "exercise_mgr.populate")
        populate_files = importlib.import_module(".4_populate_files", "exercise_mgr.populate")
        create_database.main(database)
        populate_topics.main(database)
        populate_files.main(database)

    def test1(self):
        database = Path(__file__).parent / "testdata" / "test.sqlite"
        conn = s.create_connection(database)
        self.assertEqual(len(s.get_subtopics(conn)), 16)
        self.assertEqual(len(s.get_topics(conn)), 81)
        self.assertEqual(s.get_exercise_count(conn), 690)

    def test2(self):
        database = Path(__file__).parent / "testdata" / "test.sqlite"
        conn = s.create_connection(database)
        temp_exercise = s.exercise_text_insert(conn, (None, None, None, "test"))
        self.assertEqual(temp_exercise, 691)
        s.delete_by_id_from_exercise_texts(conn, temp_exercise)
        self.assertEqual(s.get_exercise_count(conn), 690)

    def tearDown(self):
        os.remove(Path(__file__).parent / "testdata" / "test.sqlite")


class TestDatabaseSetup(unittest.TestCase):
    def test1(self):
        database = Path(__file__).parent / "testdata" / "test.sqlite"
        create_database = importlib.import_module(".0_create_database", "exercise_mgr.populate")
        populate_topics = importlib.import_module(".1_populate_topics", "exercise_mgr.populate")
        populate_files = importlib.import_module(".4_populate_files", "exercise_mgr.populate")
        create_database.main(database)
        assert(database.is_file())
        populate_topics.main(database)
        populate_files.main(database)
        os.remove(Path(__file__).parent / "testdata" / "test.sqlite")


if __name__ == '__main__':
    unittest.main()
