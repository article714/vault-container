#!/bin/bash

PATH=/sbin:/usr/sbin:/bin:/usr/bin

#set -x

start() {
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
