FROM ubuntu:18.04

RUN apt-get update && apt-get -y install curl git

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
