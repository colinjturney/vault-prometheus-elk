RSYSLOG_SERVER_IP=${1}

echo "*.* @${RSYSLOG_SERVER_IP}:514" | cat - /etc/rsyslog.d/50-default.conf > temp && mv temp /etc/rsyslog.d/50-default.conf

sudo service rsyslog restart
