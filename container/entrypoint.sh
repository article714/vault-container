#!/bin/bash

PATH=/sbin:/usr/sbin:/bin:/usr/bin

#set -x

start() {
    if [ ! -f "/container/config/vault/certs/fullchain.pem" ]; then
        # Build self-signed Certificate
        cd /container/config/vault/certs
        chpst -u vault openssl req -newkey rsa:4096 -days 1001 -nodes -x509 -subj ${VAULT_X509_SUBJECT} -keyout "vault.key" -out "vault.crt"
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
