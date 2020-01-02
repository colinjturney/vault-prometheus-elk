# Vault Monitoring and Logging Demo

The code in this demo will build a local Consul cluster with a single Vault server along with a Prometheus/Grafana server and an ELK (Elasticsearch, Logstash, Kibana) server too. The aim of all of this is to demonstrate how you could collect metrics from Vault and Consul (and which metrics are most important) and also how to collect audit logs from Vault and ship them to an ELK stack.

## Important Notes

1. **Note:** As of 2nd January 2019, there is an incompatibility between Vagrant 2.2.6 and Virtualbox 6.1.X. Until this incompatibility is fixed, it is recommended to run Vagrant with Virtualbox 6.0.14 instead.

2. **Note:** This demo aims to demonstrate how telemetry metrics and audit logs can be enabled and collected with Vault and Consul. It does **not** intend to demonstrate how to build a Vault and Consul deployment according to any recommended architecture, nor does it intend to demonstrate any form of best practice. Amongst many other things, you should always enable ACLs, configure TLS and never store your Vault unseal keys or tokens on your Vault server!

## Requirements
* The VMs created by the demo will consume a total of 5GB memory.
* The demo was tested using Vagrant 2.2.6 and Virtualbox 6.0.14

## What is built?

The demo will build the following Virtual Machines:
* **vault-server**: A single Vault server
* **consul-{1-3}-server**: A cluster of 3 Consul servers within a single Datacenter
* **prometheus**: A single server running Prometheus
* **elasticsearch**: A single server running an ELK stack.

## Provisioning scripts
The following provisioning scripts will be run by Vagrant:
* config-grafana.sh: Automatically configures Prometheus as the datasource for Grafana on the prometheus VM, deploys a dashboard onto Grafana and sets that dashboard as the home dashboard.
* install-consul.sh: Automatically installs and configures Consul 1.6.2 (open source) on each of the consul-{1-3}-server VMs. A flag allows it to configure a consul client on the Vault VM too.
* install-elasticsearch.sh: Automatically installs and configures the latest version of elasticsearch on the elasticsearch VM.
* install-grafana.sh: Automatically installs Grafana onto the prometheus VM.
* install-kibana.sh: Automatically installs Kibana onto the elasticsearch VM and configures it to search on the local Elasticsearch server.
* install-logstash.sh: Automatically installs Logstash onto the elasticsearch VM and configures it to output to the local Elasticsearch server.
* install-prometheus.sh: Automatically installs Prometheus onto the Prometheus VM and configures it to scrape metrics from all consul and vault servers.
* install-rsyslog-client.sh: Configures an rsyslog client on each of the consul and vault servers to forward to the rsyslog server (which is co-located on the elasticsearch server)
* install-rsyslog-server.sh: Configures an rsyslog server on the elasticsearch server to collect logs sent from the rsyslog clients and to forward them to logstash running on the same Elasticsearch server in JSON format.
* install-telegraf.sh: Installs and configures telegraf on each of the consul and vault servers. This collects system and application metrics and publishes them on an endpoint that Prometheus can scrape from.
* install-vault.sh: Automatically installs and configures Vault (open source) on the Vault server.

## Additional files
The following additional files are also included:
* grafana-dashboard.json: Stores the grafana dashboard configuration. Used by config-grafana.sh
* init-vault.sh: Needs to be run as a manual step to initialise and unseal Vault, logging in using the root token and configuring audit logging.
* test-put-vault.sh: Puts 10000 unique secrets into Vault in order to demonstrate the effect of a large number of Vault writes on Vault and Consul (Should be run before test-get-vault.sh)
* test-get-vault.sh: Gets 10000 secrets from Vault in order to demonstrate the effect of a large number of Vault reads on Vault and Consul (Should be run after test-put-vault.sh)

## How to get started
Once Vagrant and Virtualbox are installed, to get started just run the following command within the code directory:
```
vagrant up
```
Once vagrant has completely finished, run the following to SSH onto the vault server
```
vagrant ssh vault-server
```
Once SSH'd onto vault-server, run the following commands in sequence:
```
cp /vagrant/init-vault.sh ~ ;
chmod 744 init-vault.sh ;
./init-vault.sh ;
chmod 744 test-{get,put}-vault.sh
```
This will create a file called vault.txt in the directory you run the script in. The file contains a single Vault unseal key and root token, in case you wish to seal or unseal vault in the future. Of course, in a real-life scenario these files should not be generated automatically and not be stored on the vault server.

Once everything is built, you should be able to access the following UIs at the following addresses:

* Consul UI: http://10.0.0.11:7500/ui/
* Grafana UI: http://10.0.0.14:3000
* Prometheus UI: http://10.0.0.14:9090
* Kibana UI: http://10.0.0.15:9601

If you're having problems, then check your Virtualbox networking configurations. They should be set to the default of NAT. If problems still persist then you might be able to access the UIs via the port forwarding that has been set up- check the Vagrantfile for these ports.

## Support
No support or guarantees are offered with this code. It is purely a demo.

## Future Improvements
* Use Docker containers instead of VMs.
* More effective load testing instead of simple bash scripts.
* Other suggested future improvements very welcome.
