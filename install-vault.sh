#!/bin/bash
# This script can be used to install Vault as per the deployment guide:
# https://www.vaultproject.io/guides/operations/deployment-guide.html

# takes a supplied vault bin and installs and configures

readonly DEFAULT_INSTALL_PATH="/usr/local/bin/vault"
readonly DEFAULT_VAULT_USER="vault"
readonly DEFAULT_VAULT_PATH="/etc/vault.d/"
readonly VAULT_BIN="vault"
readonly DEFAULT_VAULT_CONFIG="vault.hcl"
readonly DEFAULT_VAULT_SERVICE="/etc/systemd/system/vault.service"
readonly DEFAULT_VAULT_CERTS="/etc/vault.d/certs"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TMP_DIR="/tmp/install"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SUPPLIED_VAULT_BIN="vault"
readonly HOST_IP_ADDRESS=${1}

readonly VAULT_VERSION="1.1.3"

function print_usage {
  echo
  echo "Usage: install-vault [OPTIONS]"
  echo "Options:"
  echo "This script can be used to install Vault and its dependencies. This script has been tested with Ubuntu 18.04 and Centos 7."
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

function has_setcap {
  [ -n "$(command -v setcap)" ]
}

function install_dependencies {
  local func="install_dependencies"
  log "INFO" ${func} "Installing dependencies"

  if has_apt_get; then
    sudo apt-get update -y
    sudo apt-get install -y curl unzip jq libcap2-bin
  else
    log "ERROR" ${func} "Could not find apt-get or yum. Cannot install dependencies on this OS."
    exit 1
  fi
}

function user_exists {
  local -r username="$1"
  id "${username}" >/dev/null 2>&1
}

function create_vault_user {
  local func="create_vault_user"
  local -r username="$1"

  if user_exists "${username}"; then
    log "INFO" ${func} "User ${username} already exists. Will not create again."
  else
    log "INFO" ${func} "Creating user named ${username}"
    sudo useradd --system --home /etc/vault.d --shell /bin/false "${username}"
  fi
}

function install_vault {
  local func="install_vault"
  local -r install_bin="$1"
  local -r tmp="$2"
  local -r bin="$3"


  log "INFO" ${func} "Installing Vault"

  curl -s -o vault.zip https://releases.hashicorp.com/vault/1.3.0/vault_1.3.0_linux_amd64.zip

  unzip vault.zip
  sudo chown root:root ${bin}
  sudo mv $bin "${install_bin}"
  if has_setcap; then
    sudo setcap cap_ipc_lock=+ep "${install_bin}"
  else
    log "ERROR" ${func} "Could not find setcap.  Please resolve this dependency before continuing"
    exit 1
  fi
  rm vault.zip
}

function create_vault_install_paths {
  local func="create_vault_install_paths"
  local -r path="$1"
  local -r username="$2"
  local -r config="$3"
  local -r ip_addr=${4}

  log "INFO" ${func} "Creating install dirs for Vault at ${path}"
  log "INFO" ${func} "username = ${username}, config = ${config}"
  sudo mkdir -p "${path}"
  cat << EOF | sudo tee ${TMP_DIR}/outy
listener "tcp" {
  address         = "127.0.0.1:8200"
  cluster_address = "127.0.0.1:8201"
  tls_disable     = "true"
}
storage "consul" {
  address = "127.0.0.1:7500"
  path = "vault/"
  service = "vault"
}
ui = true
telemetry {
  dogstatsd_addr = "localhost:8125"
  disable_hostname = true
}
api_addr = "http://${ip_addr}:8200"
cluster_addr = "https://${ip_addr}:8201"
EOF

  sudo cp ${TMP_DIR}/outy ${path}${config}
  sudo chmod 640 ${path}${config}
  log "INFO" ${func} "Changing ownership of ${path} to ${username}"
  sudo chown -R "${username}:${username}" "${path}"
}

function create_vault_service {
  local func="create_vault_service"
  local -r service="$1"

  log "INFO" ${func} "Creating Vault service"
  cat <<EOF > /tmp/outy
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitIntervalSec=60
StartLimitBurst=3
[Install]
WantedBy=multi-user.target
EOF

  sudo cp /tmp/outy "${service}"
  sudo systemctl enable vault

}

function setup_bash_profile {
  cat <<EOF >> /etc/bash.bashrc
export VAULT_ADDR=http://127.0.0.1:8200
EOF
}

function main {
  local func="main"
  if [ -e ${TMP_DIR} ]; then
    rm -rf "${TMP_DIR}"
  fi
  mkdir "${TMP_DIR}"

  log "INFO" "${func}" "Starting Vault install"
  install_dependencies
  create_vault_user "${DEFAULT_VAULT_USER}"
  install_vault "${DEFAULT_INSTALL_PATH}" "${TMP_DIR}" "$SUPPLIED_VAULT_BIN"
  create_vault_install_paths "${DEFAULT_VAULT_PATH}" "${DEFAULT_VAULT_USER}" "${DEFAULT_VAULT_CONFIG}" "${HOST_IP_ADDRESS}"
  create_vault_service "${DEFAULT_VAULT_SERVICE}"
  log "INFO" "${func}" "Vault install complete!"
  sudo rm -rf "${TMP_DIR}"
  sudo systemctl start vault
  setup_bash_profile
}

main "$@"
