FROM alpine:latest

# Install Apline packages and setup rsyslogd
RUN apk update \
    && apk add \
        rsyslog \
        supervisor \
        unzip
COPY rsyslog.conf /etc/rsyslog.conf

# Install promtail
RUN apk add gcompat \
    && wget -q "https://github.com/grafana/loki/releases/download/v2.8.2/promtail-linux-amd64.zip" -O /tmp/promtail.zip \
    && unzip /tmp/promtail.zip -d /tmp/ \
    && mv /tmp/promtail-linux-amd64 /opt/promtail \
    && chmod a+x /opt/promtail
COPY promtail.yaml /etc/promtail.yaml

# Clean up
RUN rm /tmp/promtail.zip \
    && rm -rf /var/cache/apk/* 


# Setup Supervisord
COPY supervisord.conf /etc/supervisord.conf

# Container setup
EXPOSE 514/udp 514/tcp 9080/tcp
CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]