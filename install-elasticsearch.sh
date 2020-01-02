#!/bin/bash

BIND_ADDRESS=${1}

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

sudo apt-get install apt-transport-https

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

sudo apt-get update && sudo apt-get install elasticsearch

sudo cat <<EOF > /etc/elasticsearch/elasticsearch.yml
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: "${BIND_ADDRESS}"
cluster.initial_master_nodes: ["${BIND_ADDRESS}"]
EOF

sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
