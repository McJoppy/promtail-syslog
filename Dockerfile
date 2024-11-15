FROM alpine:latest

# Install Apline packages and setup rsyslogd
RUN apk update \
    && apk add \
        rsyslog \
        rsyslog-mmutf8fix \
        rsyslog-mmjsonparse \
        supervisor \
        unzip
COPY rsyslog.conf /etc/rsyslog.conf

# Setup system user
RUN addgroup -S promtail && adduser -S promtail -G promtail -h /opt/loki

# Install promtail
RUN apk add gcompat \
    && arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) \
    && wget -q "https://github.com/grafana/loki/releases/download/v3.2.1/promtail-linux-${arch}.zip" -O /tmp/promtail.zip \
    && unzip /tmp/promtail.zip -d /tmp/ \
    && cp -rp "/tmp/promtail-linux-${arch}" /opt/loki/promtail \
    && chmod a+x /opt/loki/promtail \
    && chown -R promtail:promtail /opt/loki/promtail
COPY promtail.yaml /etc/promtail.yaml

# Clean up
RUN rm /tmp/promtail.zip \
    && rm -rf "/tmp/promtail-linux-${arch}" \
    && rm -rf /var/cache/apk/*

# Setup Supervisord
COPY supervisord.conf /etc/supervisord.conf

# Container setup
EXPOSE 514/udp 514/tcp 9080/tcp
CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
