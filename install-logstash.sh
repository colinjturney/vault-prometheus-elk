#!/bin/bash

LOGSTASH_SERVER_IP=${1}

# Install Java

sudo apt-get --assume-yes install openjdk-11-jre

sudo echo 'JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/bin/java"' >> /etc/environment

JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/bin/java"

# Install Logstash

wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/logstash/2.3/debian stable main" | sudo tee -a /etc/apt/sources.list

sudo apt-get --assume-yes update

sudo apt-get --assume-yes install logstash

sudo mkdir -p /etc/logstash/conf.d

sudo cat <<EOF > /etc/logstash/conf.d/logstash.conf
input {
  udp {
    host => "${LOGSTASH_SERVER_IP}"
    port => 10514
    codec => "json"
    type => "rsyslog"
  }
}

# This is an empty filter block.  You can later add other filters here to further process
# your log lines

filter { }

# This output block will send all events of type "rsyslog" to Elasticsearch at the configured
# host and port into daily indices of the pattern, "rsyslog-YYYY.MM.DD"

output {
  if [type] == "rsyslog" {
    elasticsearch {
      hosts => [ "${LOGSTASH_SERVER_IP}:9200" ]
    }
  }
}
EOF

sudo service logstash start
sudo service rsyslog restart
