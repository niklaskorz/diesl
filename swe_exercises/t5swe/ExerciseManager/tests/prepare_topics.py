import unittest
from exercise_mgr.populate.split_topic import split_topic


class TestPrepareTopics(unittest.TestCase):
    def test_split_topic(self):
        fixture = "Ü-12-1-5,Ü-13-1-6,25,26"
        exercises, topic_ids = split_topic(fixture)
        self.assertEqual(exercises, ["Ü-12-1-5", "Ü-13-1-6"])
        self.assertEqual(topic_ids, ["25", "26"])


if __name__ == "__main__":
    unittest.main()
