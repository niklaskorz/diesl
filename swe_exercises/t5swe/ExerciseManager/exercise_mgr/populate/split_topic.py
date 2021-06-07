from typing import Tuple, List


def split_topic(topic: str) -> Tuple[List[str], List[str]]:
    topics_split = topic.split(",")
    exercises = []
    topic_ids = []
    for el in topics_split:
        if "Ü" in el:
            exercises.append(el.strip())
        else:
            topic_ids.append(el.strip())
    return exercises, topic_ids
