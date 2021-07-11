
FROM nimlang/nim:1.4.8

RUN apt-get update
RUN apt-get install -y lcov
RUN nimble update
RUN nimble install coco -y
