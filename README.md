# Promtail Syslog Receiver

The purpose of this container is to run a remote syslog server which will send to Grafana Loki that can be used for routers, switches and other hardware that allows sending logs to remote syslog and not install and configure promtail directly.

## Rsyslog & Grafana

Alpine based image with rsyslog in front of promtail as recommended by Grafana (see https://grafana.com/docs/loki/latest/clients/promtail/scraping/#rsyslog-output-configuration) which forwards all logs through to Loki instance via promtail.

Ports `514/udp`, `514/tcp` and `9080/tcp` are exposed while both `rsyslog.conf` and `promtail.yaml` content are hard coded.

## Configuration

The Loki client URL is currently configured via the env var `CLIENT_URL` with no default.

`rsyslog.conf`

```
global(processInternalMessages="on")

#module(load="imtcp" StreamDriver.AuthMode="anon" StreamDriver.Mode="1")
module(load="impstats") # config.enabled=`echo $ENABLE_STATISTICS`)
module(load="imptcp")
module(load="imudp" TimeRequery="500")
module(load="mmjsonparse")
module(load="mmutf8fix")

input(type="imptcp" port="514")
input(type="imudp" port="514")

#################### default ruleset begins ####################

# we emit our own messages to docker console:
*.* action(type="omfwd" protocol="tcp" target="localhost" port="1514" Template="RSYSLOG_SyslogProtocol23Format" TCP_Framing="octet-counted" KeepAlive="on")
```

`promtail.yaml`

```
server:
  http_listen_port: 9080
  grpc_listen_port: 0
positions:
  filename: /etc/promtail/positions.yaml
clients:
  - url: ${CLIENT_URL}
scrape_configs:
  - job_name: syslog
    syslog:
      listen_address: 0.0.0.0:1514
      listen_protocol: tcp
      idle_timeout: 60s
      label_structured_data: yes
      labels:
        job: "syslog"
    relabel_configs:
      - source_labels: ['__syslog_message_hostname']
        target_label: 'host'
      - source_labels: ['__syslog_message_hostname']
        target_label: 'hostname'
      - source_labels: ['__syslog_message_severity']
        target_label: 'severity'
      - source_labels: ['__syslog_message_app_name']
        target_label: 'appname'
      - source_labels: ['__syslog_message_facility']
        target_label: 'facility'

```

## Testing

Build with docker eg `docker build -t 'testing' .` then start a container with the image specifing the outside ports as well as your Loki `CLIENT_URL`.

With Linux test messages can be sent using `logger` eg `logger -p 0 -d -P 1514 -n 127.0.0.1 -t 'Ubuntu' 'UDP Test message'` will test via UDP port `1514` on `127.0.0.1` with the tag `Ubuntu`.

The message should be visible in Loki:

| Timestamp                 | Labels                | Message          |
| ------------------------- | --------------------- | ---------------- |
| `2024-11-15 19:55:26.941` | `appname=Ubuntu`      | UDP Test message |
|                           | `facility=user`       |                  |
|                           | `hostname=TESTING`    |                  |
|                           | `appname=Ubuntu`      |                  |
|                           | `service_name=syslog` |                  |
|                           | `severity=emergency`  |                  |

## Troubleshooting

The container will have problems if `CLIENT_URL` isn't configured corretly.

If you are seeing log messages as below, double check the environment variable for `CLIENT_URL` is set correctly.

```log
2023-12-28 05:22:30,586 INFO supervisord started with pid 1
2023-12-28 05:22:31,588 INFO spawned: 'rsyslogd' with pid 7
2023-12-28 05:22:31,592 INFO spawned: 'promtail' with pid 8
2023-12-28 05:22:31,753 WARN exited: promtail (exit status 1; not expected)
2023-12-28 05:22:32,755 INFO success: rsyslogd entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2023-12-28 05:22:32,758 INFO spawned: 'promtail' with pid 26
2023-12-28 05:22:32,810 WARN exited: promtail (exit status 1; not expected)
2023-12-28 05:22:34,814 INFO spawned: 'promtail' with pid 39
2023-12-28 05:22:34,875 WARN exited: promtail (exit status 1; not expected)
2023-12-28 05:22:37,881 INFO spawned: 'promtail' with pid 51
2023-12-28 05:22:37,934 WARN exited: promtail (exit status 1; not expected)
2023-12-28 05:22:38,936 INFO gave up: promtail entered FATAL state, too many start retries too quickly
```
