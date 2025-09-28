FROM ubuntu:22.04

COPY setup.sh /opt/setup.sh
COPY entrypoint.sh /opt/entrypoint.sh
WORKDIR /opt

RUN bash setup.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
