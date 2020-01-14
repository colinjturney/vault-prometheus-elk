#!/bin/bash

# Initialise Vault. Store keys locally FOR DEMO PURPOSES ONLY

vault operator init -key-shares=1 -key-threshold=1 > init-output.txt 2>&1

echo "Unseal: "$(grep Unseal init-output.txt | cut -d' ' -f4) >> vault.txt
echo "Token: "$(grep Token init-output.txt | cut -d' ' -f4) >> vault.txt
rm init-output.txt

# Unseal Vault
vault operator unseal $(cat vault.txt | grep Unseal | cut -f2 -d' ')

# Login to Vault
vault login $(cat vault.txt | grep Token | cut -f2 -d' ')

# Configure rsyslog audit device

vault audit enable syslog

# Configure secret backend

vault secrets enable -path=secret/ kv

# Copy over Vault testing scripts to demonstrate storage backend under heavy reads/writes

cp /vagrant/test-put-vault.sh .
cp /vagrant/test-get-vault.sh .

# Create a policy for Jenkins

cat <<EOF >> jenkins_policy.hcl

# Allow Jenkins to read from the secret KV store
path "secret/*" {
  capabilities = ["read", "list"]
}

EOF

vault policy write jenkins jenkins_policy.hcl

# Configure Jenkins AppRole and copy it to /vagrant

vault auth enable approle

# Create the Jenkins AppRole

vault write auth/approle/role/jenkins \
    secret_id_ttl=10m \
    token_num_uses=10 \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=40 \
    token_policies="jenkins"

# Fetch the RoleId of the AppRole

vault read auth/approle/role/jenkins/role-id | grep role_id | cut -f5 -d' ' > /vagrant/jenkins-approle-role-id

# Get a SecretID issued against the AppRole

vault write -f auth/approle/role/jenkins/secret-id | grep secret_id | cut -f5 -d' ' | grep - > /vagrant/jenkins-approle-secret-id
