#!/bin/sh

set -e

MAINTENANCE_ENABLED="$SF_APP_CONTAINER_DIR/web/.maintenance.enable"

echo -e "\e[33mWaiting for backend service to be ready\e[0m"
echo -e "\e[33m=======================================================================\e[0m"
sleep 10

while [ -f "$MAINTENANCE_ENABLED" ]
do
  sleep 3
done

exec "$@"