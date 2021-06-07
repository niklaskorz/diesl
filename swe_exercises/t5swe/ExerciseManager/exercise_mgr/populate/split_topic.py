from typing import Tuple, List


def split_topic(topic: str) -> Tuple[List[str], List[str]]:
    topics_split = topic.split(",")
    topics_split[0] = topics_split[0].rstrip()
    exercises = []
    topic_ids = []
    for el in topics_split[:-1]:
        if "Ü" in el:
            exercises.append(el)
        else:
            topic_ids.append(el)
    return exercises, topic_ids
