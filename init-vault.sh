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
