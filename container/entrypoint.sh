#!/bin/bash

PATH=/sbin:/usr/sbin:/bin:/usr/bin

#set -x

start() {
    if [[ ! -f "/container/config/vault/certs/vault.crt" && -n "${VAULT_X509_SUBJECT}" ]]; then
        # Build self-signed Certificate
        chown vault.root /container/config/vault/certs
        cd /container/config/vault/certs
        if [ -n "${VAULT_X509_ALTNAMES}" ]; then
            chpst -u vault openssl req -newkey rsa:4096 -days 1001 -nodes -x509 -subj ${VAULT_X509_SUBJECT} -addext "subjectAltName=${VAULT_X509_ALTNAMES}" -keyout "vault.key" -out "vault.crt"
        else
            chpst -u vault openssl req -newkey rsa:4096 -days 1001 -nodes -x509 -subj ${VAULT_X509_SUBJECT} -keyout "vault.key" -out "vault.crt"
        fi

    fi

    exec runsvdir -P /container/services
}

case "$1" in
start)
    start
    ;;
shell)
    exec "/bin/bash"
    ;;
--)
    start
    ;;
*)
    exec "$@"
    ;;
esac

exit 1
