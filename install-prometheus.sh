#!/bin/bash
set -x

IP_ADDRESS=${1}

sudo useradd prometheus --no-create-home

wget https://github.com/prometheus/prometheus/releases/download/v2.14.0/prometheus-2.14.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
rm prometheus-*.tar.gz

sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus

sudo mv prometheus*/* /etc/prometheus/

sudo mv /etc/prometheus/prometheus /usr/local/bin/

cat > "/etc/prometheus/prometheus.yml" <<EOF
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'vault-server'
    static_configs:
    - targets: ['10.0.0.10:9273']
    scheme: "http"
    tls_config:
      insecure_skip_verify: true
    metrics_path: "/metrics"
    params:
      format: ['prometheus']

  - job_name: 'consul-1-server'
    static_configs:
    - targets: ['10.0.0.11:9273']
    scheme: "http"
    tls_config:
      insecure_skip_verify: true
    metrics_path: "/metrics"
    params:
      format: ['prometheus']

  - job_name: 'consul-2-server'
    static_configs:
    - targets: ['10.0.0.12:9273']
    scheme: "http"
    tls_config:
      insecure_skip_verify: true
    metrics_path: "/metrics"
    params:
      format: ['prometheus']

  - job_name: 'consul-3-server'
    static_configs:
    - targets: ['10.0.0.13:9273']
    scheme: "http"
    tls_config:
      insecure_skip_verify: true
    metrics_path: "/metrics"
    params:
      format: ['prometheus']

EOF


cat > "/etc/systemd/system/prometheus.service" <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
    --web.listen-address=${IP_ADDRESS}:9090

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
systemctl status --no-pager prometheus
