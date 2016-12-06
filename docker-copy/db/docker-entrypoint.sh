#!/bin/bash

set -e

_datadir() {
    "$@" --verbose --help --log-bin-index="$(mktemp -u)" 2>/dev/null | awk '$1 == "datadir" { print $2; exit }'
}

DATADIR="$(_datadir "mysqld")"
MAINTENANCE_ENABLED="$DATADIR/.db-upgrade-in-progress"


echo -e "\e[33mWaiting for db-upgrade service to stop\e[0m"
echo -e "\e[33m=======================================================================\e[0m"

sleep 5

while [ -f "$MAINTENANCE_ENABLED" ]
do
  sleep 1
done

#add some hidden file that marks that db upgrade service is running for next time
touch "$MAINTENANCE_ENABLED"

echo -e "\e[33mDB upgrade complete. Starting DB service\e[0m"
echo -e "\e[33m=======================================================================\e[0m"

exec docker-entrypoint.sh "$@"