from pathlib import Path
import json

from .topic_cross_to_id import topic_cross_to_id
from .split_topic import split_topic


source_dir = Path(__file__).parent
path_topics = source_dir / "topics.csv"
path_topics_formatted = source_dir / "topics_formatted.csv"
path_topics_json = source_dir / "topics.json"


def format_topics():
    # topics.csv was created by excel's export ability
    with path_topics.open("r", encoding="utf-8") as file:
        b = list(topic_cross_to_id(file))
    with path_topics_formatted.open("w+", encoding="utf-8") as outfile:
        for line in b:
            outfile.write(line + "\n")


def topics_to_json():
    with path_topics_formatted.open("r", encoding="utf-8") as file:
        topics = file.readlines()
        a = {}
        for topic in topics:
            exercises, topic_ids = split_topic(topic)
            a[exercises[0]] = [exercises, topic_ids]
    with path_topics_json.open("w+", encoding="utf8") as outfile:
        json.dump(
            a,
            outfile,
            sort_keys=True,
            indent=4,
            separators=(",", ": "),
            ensure_ascii=False,
        )


def main():
    format_topics()
    topics_to_json()


if __name__ == "__main__":
    main()
