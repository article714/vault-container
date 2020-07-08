#!/bin/bash

apt-get update
apt-get upgrade -yq
apt-get install -y locales
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
localedef -i fr_FR -c -f UTF-8 -A /usr/share/locale/locale.alias fr_FR.UTF-8

export LANG=en_US.utf8

# Install needed basic packages
LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends runit rsyslog logrotate \
    curl

# Add Syslog user
groupadd -g 110 syslog
adduser --no-create-home --disabled-password --shell /usr/sbin/nologin --gecos "" --uid 104 --gid 110 syslog

chgrp syslog /var/log
chmod 775 /var/log

# Add Vault user
groupadd vault
adduser --no-create-home --disabled-password --shell /usr/sbin/nologin --gecos "" vault vault

# Install Vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update && sudo apt-get install vault
apt-get install vault

# Set up certificates, our base tools, and Vault.
RUN set -eux
apk add --no-cache ca-certificates gnupg openssl libcap su-exec dumb-init tzdata &&
    apkArch="$(apk --print-arch)"
case "$apkArch" in
armhf) ARCH='arm' ;;
aarch64) ARCH='arm64' ;;
x86_64) ARCH='amd64' ;;
x86) ARCH='386' ;;
*)
    echo >&2 "error: unsupported architecture: $apkArch"
    exit 1
    ;;
esac &&
    VAULT_GPGKEY=91A6E7F85D05C65630BEF18951852D87348FFC4C
found=''
for server in \
    hkp://p80.pool.sks-keyservers.net:80 \
    hkp://keyserver.ubuntu.com:80 \
    hkp://pgp.mit.edu:80; do
    echo "Fetching GPG key $VAULT_GPGKEY from $server"
    gpg --batch --keyserver "$server" --recv-keys "$VAULT_GPGKEY" && found=yes && break
done
test -z "$found" && echo >&2 "error: failed to fetch GPG key $VAULT_GPGKEY" && exit 1
mkdir -p /tmp/build &&
    cd /tmp/build &&
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip &&
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS &&
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig &&
    gpg --batch --verify vault_${VAULT_VERSION}_SHA256SUMS.sig vault_${VAULT_VERSION}_SHA256SUMS &&
    grep vault_${VAULT_VERSION}_linux_${ARCH}.zip vault_${VAULT_VERSION}_SHA256SUMS | sha256sum -c &&
    unzip -d /bin vault_${VAULT_VERSION}_linux_${ARCH}.zip &&
    cd /tmp &&
    rm -rf /tmp/build &&
    gpgconf --kill dirmngr &&
    gpgconf --kill gpg-agent &&
    apk del gnupg openssl &&
    rm -rf /root/.gnupg

#--
# config files redirection

rm -f /etc/rsyslog.conf
ln -s /container/config/rsyslog.conf /etc/rsyslog.conf

rm -f /etc/logrotate.conf
ln -s /container/config/logrotate.conf /etc/logrotate.conf

rm -rf /etc/crontab /etc/cron.d
ln -s /container/config/crontab /etc/crontab
ln -s /container/config/cron.d /etc/cron.d

#--
# Cleaning
apt-get -yq clean
apt-get -yq autoremove
rm -rf /var/lib/apt/lists/*
# remove default Ldap DB
rm -rf /var/lib/ldap /etc/ldap/slapd.d
# cleanup useless cron jobs
rm -f /etc/cron.daily/passwd /etc/cron.daily/dpkg /etc/cron.daily/apt-compat
# truncate logs
truncate --size 0 /var/log/lastlog
truncate --size 0 /var/log/faillog
truncate --size 0 /var/log/dpkg.log
truncate --size 0 /var/log/syslog
