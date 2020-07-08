#!/bin/bash

export LANG=en_US.utf8

# Add Vault user
groupadd vault
adduser --no-create-home --disabled-password --shell /usr/sbin/nologin --gecos "" --ingroup vault vault

# install gnupg to enable adding of hashicorp keys
apt-get update
apt-get install -qy --no-install-recommends gnupg gnupg-agent curl software-properties-common

# Install Vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update
apt-get install -yq vault

# setup privileges for vault
setcap cap_ipc_lock=+ep /usr/bin/vault

#--
# Cleaning
apt-get -yq clean
apt-get -yq remove software-properties-common
apt-get -yq autoremove
rm -rf /var/lib/apt/lists/*
# cleanup useless cron jobs
rm -f /etc/cron.daily/passwd /etc/cron.daily/dpkg /etc/cron.daily/apt-compat
# truncate logs
truncate --size 0 /var/log/lastlog
truncate --size 0 /var/log/faillog
truncate --size 0 /var/log/dpkg.log
truncate --size 0 /var/log/syslog
