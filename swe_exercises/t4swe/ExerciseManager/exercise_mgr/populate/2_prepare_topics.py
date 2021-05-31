import json
import re



def format_topics():
    # topics.csv was created by excel's export ability
    with open("topics.csv", 'r', encoding='utf-8') as file:
        lines = file.readlines()
        b = []
        for line in lines:
            split = line.split(';')
            a = split[0]
            for i in range(1, len(split)-1):
                if 'Ü' in split[i]:
                    a += ' '+split[i].replace('"', '')
                if split[i] == 'X':
                    if i < 4:
                        a += ' '+str(i+14)
                    else:
                        a += ' '+str(i+12)
            if a[0][0] == 'Ü':
                b.append(re.sub(r'\s+', ',', a))
    with open("topics_formatted.csv", 'w+', encoding='utf-8') as outfile:
        for line in b:
            outfile.write(line + '\n')


def topics_to_json():
    with open("topics_formatted.csv", 'r', encoding='utf-8') as file:
        topics = file.readlines()
        a = {}
        for topic in topics:
            topics_split = topic.split(',')
            topics_split[0] = topics_split[0].rstrip()
            b = []
            c = []
            for el in topics_split[:-1]:
                if 'Ü' in el:
                    b.append(el)
                else:
                    c.append(el)
            a[topics_split[0]] = [b, c]
    with open("topics.json", "w+", encoding='utf8') as outfile:
        json.dump(a, outfile, sort_keys=True, indent=4, separators=(',', ': '), ensure_ascii=False)


def main():
    format_topics()
    topics_to_json()


if __name__ == '__main__':
    main()
