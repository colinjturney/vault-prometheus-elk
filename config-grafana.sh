#!/bin/bash

echo "Waiting 15 seconds for Grafana to come up..."
sleep 15
echo "Continuing..."

# Add Prometheus Datasource

cat > "grafana-datasources.json" <<EOF
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://localhost:9090",
  "access": "proxy",
  "isDefault": true
}
EOF

curl -X POST -H "Content-Type: application/json" -d @grafana-datasources.json http://admin:admin@localhost:3000/api/datasources >> /var/log/config-grafana.log 2>&1

# Import Grafana Dashboard
sudo cp /vagrant/grafana-dashboard.json .

curl -X POST -H "Content-Type: application/json" -d @grafana-dashboard.json http://admin:admin@localhost:3000/api/dashboards/db >> /var/log/config-grafana.log 2>&1

# Star Dashboard and set as home

cat > "grafana-preferences.json" <<EOF
{
  "theme": "",
  "homeDashboardId":1,
  "timezone":"utc"
}
EOF

curl -X POST http://admin:admin@localhost:3000/api/user/stars/dashboard/1 >> /var/log/config-grafana.log 2>&1

curl -X PUT -H "Content-Type: application/json" -d @grafana-preferences.json http://admin:admin@localhost:3000/api/user/preferences >> /var/log/config-grafana.log 2>&1
