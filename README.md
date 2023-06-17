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
```