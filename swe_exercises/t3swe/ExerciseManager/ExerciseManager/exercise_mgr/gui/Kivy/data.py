class Exercise:

    def __init__(self, exercise):
        self.exercise_text_id = exercise[0]
        self.exercise_family_id = exercise[1]
        self.exercise_name = exercise[2]
        self.content = exercise[3]
        self.topic_names = [exercise[4]]
        self.semester = exercise[5]
        self.summary = "".join(self.content.splitlines()[:3:])

    def get_exercise_text_id(self):
        return self.exercise_text_id

    def get_exercise_family_id(self):
        return self.exercise_family_id

    def get_exercise_name(self):
        return self.exercise_name

    def get_exercise_content(self):
        return self.content

    def get_exercise_summary(self):
        self.summary = "".join(self.content.splitlines()[:3:])
        return self.summary

    def set_exercise_content(self, new_content):
        self.content = new_content

    def get_topic(self):
        return self.topic_names

    def add_topic(self, topic):
        self.topic_names.append(topic)

    def __repr__(self):
        return self.exercise_name
