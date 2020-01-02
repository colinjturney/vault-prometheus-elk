#!/bin/bash

DATACENTER=${1}
ROLE=${2}

# Add the influxdata signing key
curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -

# Configure a package repo
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

# Install Telegraf
sudo apt-get update && sudo apt-get install telegraf

# Configure Telegraf
cat > "/etc/telegraf/telegraf.conf" <<EOF
# Vault Config
[agent]
  interval = "10s"
  flush_interval = "10s"
  omit_hostname = false

[global_tags]
  role = "${ROLE}"
  datacenter = "${DATACENTER}"

[[inputs.statsd]]
   protocol = "udp"
   service_address = ":8125"
   delete_gauges = true
   delete_counters = true
   delete_sets = true
   delete_timings = true
   percentiles = [90]
   metric_separator = "_"
   parse_data_dog_tags = true
   allowed_pending_messages = 10000
   percentile_limit = 1000

 [[inputs.cpu]]
    percpu = true
    totalcpu = true
    collect_cpu_time = false
 [[inputs.disk]]
    # mount_points = ["/"]
    # ignore_fs = ["tmpfs", "devtmpfs"]
 [[inputs.diskio]]
    # devices = ["sda", "sdb"]
    # skip_serial_number = false
 [[inputs.kernel]]
    # no configuration
 [[inputs.linux_sysctl_fs]]
    # no configuration
 [[inputs.mem]]
    # no configuration
 [[inputs.net]]
    interfaces = ["eth1"]
 [[inputs.netstat]]
    # no configuration
 [[inputs.processes]]
    # no configuration
 [[inputs.procstat]]
    pattern = "(consul|vault)"
 [[inputs.swap]]
    # no configuration
 [[inputs.system]]
    # no configuration
 [[inputs.consul]]
    address="localhost:7500"
    scheme="http"

[[outputs.prometheus_client]]
   ## Address to listen on.
   listen = ":9273"

EOF

# Start the daemon

sudo systemctl enable telegraf
sudo systemctl restart telegraf
