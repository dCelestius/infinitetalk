FROM celestius/infinitetalk:0.0.2

COPY *.sh /opt/
WORKDIR /opt

ENTRYPOINT ["/opt/entrypoint.sh"]
