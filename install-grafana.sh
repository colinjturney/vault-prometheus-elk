#! /bin/bash

sudo useradd grafana --no-create-home

echo "Downlaoding grafana 6.2.1..."
wget -q https://dl.grafana.com/oss/release/grafana-6.2.1.linux-amd64.tar.gz
tar xvfz grafana-*.tar.gz
rm grafana-*.tar.gz

sudo mv grafana-* /etc/grafana
sudo mkdir -p /var/lib/grafana/
sudo chown -R grafana:grafana /etc/grafana
sudo chown -R grafana:grafana /var/lib/grafana

cat > "/etc/systemd/system/grafana.service" <<EOF
[Unit]
Description=Grafana
Wants=network-online.target
After=network-online.target

[Service]
User=grafana
Group=grafana
Type=simple
ExecStart=/etc/grafana/bin/grafana-server -homepath /etc/grafana

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable grafana
sudo systemctl start grafana
sudo systemctl status --no-pager grafana
