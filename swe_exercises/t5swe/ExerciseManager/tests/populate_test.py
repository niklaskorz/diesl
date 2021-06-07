import unittest
from exercise_mgr.populate.split_topic import split_topic
from exercise_mgr.populate.topic_cross_to_id import topic_cross_to_id


class PopulateTest(unittest.TestCase):
    def test_split_topic(self):
        topic = "Ü-12-1-5,Ü-13-1-6,25,26"
        exercises, topic_ids = split_topic(topic)
        self.assertEqual(exercises, ["Ü-12-1-5", "Ü-13-1-6"])
        self.assertEqual(topic_ids, ["25", "26"])

    def test_topic_cross_to_id(self):
        line1 = "Ü-12-2-3;1;;;;Allgemein BS;;;;;;;;;;X;;;X;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
        result1 = topic_cross_to_id(line1)
        self.assertEqual(result1, "Ü-12-2-3,27,30")

        line2 = 'Ü-12-3-1;3;;;"Ü-15-2-2; Ü-19-2-2";;;;;;;;;;;;;;X;;X;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'
        result2 = topic_cross_to_id(line2)
        self.assertEqual(result2, "Ü-12-3-1,Ü-15-2-2,Ü-19-2-2,30,32")


if __name__ == "__main__":
    unittest.main()
