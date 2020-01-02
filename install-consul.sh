#!/bin/bash
# This script can be used to install Consul as per the deployment guide:
# https://learn.hashicorp.com/consul/datacenter-deploy/deployment-guide

readonly DEFAULT_INSTALL_PATH="/usr/local/bin/consul"
readonly DEFAULT_CONSUL_USER="consul"
readonly DEFAULT_CONSUL_PATH="/etc/consul.d"
readonly DEFAULT_CONSUL_AGENT_CONFIG="consul.hcl"
readonly DEFAULT_CONSUL_SERVER_CONFIG="server.hcl"
readonly DEFAULT_CONSUL_SERVICE_NAME="consul"
readonly DEFAULT_CONSUL_DATA_DIR="/opt/consul"
readonly CONSUL_BIN="consul"
readonly DEFAULT_CONSUL_SERVICE="/etc/systemd/system/consul.service"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TMP_DIR="/tmp/install"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SUPPLIED_CONSUL_BIN="consul"
readonly ADVERTISE_ADDRESS="${1}"
readonly RETRY_JOIN="${2}"
readonly DATACENTER="${3}"
readonly BOOTSTRAP_EXPECT=${4}
readonly IS_CONSUL_SERVER=${5}

function print_usage {
  echo
  echo "Usage: install-consul [OPTIONS]"
  echo "Options:"
  echo "This script can be used to install Consul and its dependencies."
  echo

}

function log {
  local -r level="$1"
  local -r func="$2"
  local -r message="$3"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [${SCRIPT_NAME}:${func}] ${message}"
}

function assert_not_empty {
  local func="assert_not_empty"
  local -r arg_name="$1"
  local -r arg_value="$2"

  if [[ -z "${arg_value}" ]]; then
    log "ERROR" ${func} "The value for '${arg_name}' cannot be empty"
    print_usage
    exit 1
  fi
}

function has_apt_get {
  [ -n "$(command -v apt-get)" ]
}

function has_yum {
  [ -n "$(command -v yum)" ]
}

function install_dependencies {
  local func="install_dependencies"
  log "INFO" ${func} "Installing dependencies"

  if has_apt_get; then
    sudo apt-get update -y
    sudo apt-get install -y curl unzip jq
  elif has_yum; then
    sudo yum update -y
    sudo yum install -y curl unzip jq
  else
    log "ERROR" ${func} "Could not find apt-get or yum. Cannot install dependencies on this OS."
    exit 1
  fi
}

function user_exists {
  local -r username="$1"
  id "${username}" >/dev/null 2>&1
}

function create_user {
  local func="create_consul_user"
  local -r username="$1"

  if user_exists "${username}"; then
    log "INFO" ${func} "User ${username} already exists. Will not create again."
  else
    log "INFO" ${func} "Creating user named ${username}"
    sudo useradd --system --home /etc/consul.d --shell /bin/false "${username}"
  fi
}

function install_consul {
  local func="install_consul"
  local -r install_bin="$1"
  local -r tmp="$2"
  local -r bin="$3"

  log "INFO" ${func} "Installing Consul"

  curl -s -o consul.zip https://releases.hashicorp.com/consul/1.6.2/consul_1.6.2_linux_amd64.zip
  unzip consul.zip

  sudo chown root:root ${bin}
  sudo mv $bin "${install_bin}"
  sudo setcap cap_ipc_lock=+ep "${install_bin}"
  rm consul.zip
}

function create_consul_install_paths {
  local func="create_consul_install_paths"
  local -r path="$1"
  local -r username="$2"
  local -r client_config="$3"
  local -r server_config="$4"
  local adv_adr="${5}"
  local rtj=${6}
  local dc="${7}"
  local data_dir="${8}"
  local bs_expect=${9}
  local is_consul_server=${10}

  log "INFO" ${func} "Creating install dirs for consul at ${path}"
  log "INFO" ${func} "username = ${username}, config = ${client_config}"
  sudo mkdir -p "${path}"

  cat << EOF | sudo tee ${path}/${client_config}

advertise_addr = "${adv_adr}"
datacenter = "${dc}"
data_dir = "${data_dir}"
retry_join = [${rtj}]

performance {
  raft_multiplier = 1
}
addresses {
  http = "0.0.0.0"
}
ports {
  dns = 7600
  http = 7500
  serf_lan = 7301
  serf_wan = 7302
  server = 7300
}
bind_addr = "0.0.0.0"

telemetry {
  dogstatsd_addr = "localhost:8125"
  disable_hostname = false
}

EOF



  if [[ -n "${is_consul_server}" ]]; then
    sudo echo "server = ${is_consul_server}" >> ${path}/${server_config}
    sudo echo "ui = true" >> ${path}/${server_config}
  fi


  if [[ "${bs_expect}" == "3" ]]; then
    sudo echo "bootstrap_expect = ${bs_expect}" >> ${path}/${server_config}
  fi

  sudo chmod 640 ${path}/${server_config}
  log "INFO" ${func} "Changing ownership of ${path} to ${username}"
  sudo chown -R "${username}:${username}" "${path}"

  log "INFO" ${func} "Creating data dir for consul at path ${data_dir}"
  log "INFO" ${func} "username = ${username}"
  sudo mkdir -p "${data_dir}"

  sudo chmod 740 ${data_dir}
  log "INFO" ${func} "Changing ownership of ${data_dir} to ${username}"
  sudo chown -R "${username}:${username}" "${data_dir}"
}

function create_consul_service {
  local func="create_consul_service"
  local -r service="$1"

  log "INFO" ${func} "Creating Consul service"
  cat <<EOF > /tmp/install/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

  sudo cp ${TMP_DIR}/consul.service "${service}"
  sudo systemctl enable consul

}

function setup_bash_profile {
  cat <<EOF >> /etc/bash.bashrc

export CONSUL_HTTP_ADDR=http://127.0.0.1:7500
EOF
}

function main {
  local func="main"

  if [ -e ${TMP_DIR} ]; then
    sudo rm -rf "${TMP_DIR}"
  fi
  sudo mkdir -p "${TMP_DIR}"
  log "INFO" "${func}" $(ls -l ${TMP_DIR})
  log "INFO" "${func}" "Starting Consul install"
  install_dependencies
  create_user "${DEFAULT_CONSUL_USER}"
  install_consul "${DEFAULT_INSTALL_PATH}" "${TMP_DIR}" "${SUPPLIED_CONSUL_BIN}"
  create_consul_install_paths "${DEFAULT_CONSUL_PATH}" "${DEFAULT_CONSUL_USER}" "${DEFAULT_CONSUL_AGENT_CONFIG}" "${DEFAULT_CONSUL_SERVER_CONFIG}"  "${ADVERTISE_ADDRESS}" "${RETRY_JOIN}" "${DATACENTER}" "${DEFAULT_CONSUL_DATA_DIR}" "${BOOTSTRAP_EXPECT}" ${IS_CONSUL_SERVER}
  create_consul_service "${DEFAULT_CONSUL_SERVICE}"
  log "INFO" "${func}" "Consul install complete!"
  sudo rm -rf "${TMP_DIR}"
  systemctl start consul
  setup_bash_profile
}

main "$@"
