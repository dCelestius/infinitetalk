FROM ubuntu:22.04

COPY *.sh /opt/
WORKDIR /opt

RUN bash setup.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
