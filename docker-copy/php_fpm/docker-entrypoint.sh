#!/bin/sh

[ "$SYMFONY_ENV" = "dev" ] && set -xe || set -e

cp /etc/php7/conf.d/50_php_override.template /etc/php7/conf.d/50_php_override.ini
envsubst '$$OPCACHE_memory_consumption $$OPCACHE_validate_timestamps $$OPCACHE_revalidate_freq $$OPCACHE_enable_cli $$OPCACHE_enable_file_override' < /etc/php7/conf.d/50_opcache_override.template > /etc/php7/conf.d/50_opcache_override.ini

exec "$@"