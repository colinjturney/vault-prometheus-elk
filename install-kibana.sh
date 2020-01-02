#!/bin/bash

ELASTICSEARCH_IP=${1}

sudo apt-get --assume-yes install kibana

sudo cat<<EOF > /etc/kibana/kibana.yml
server.host: "${ELASTICSEARCH_IP}"
elasticsearch.hosts: ["http://${ELASTICSEARCH_IP}:9200"]
EOF

service kibana enable
service kibana restart
