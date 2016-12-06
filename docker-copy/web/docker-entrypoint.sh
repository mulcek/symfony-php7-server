#!/bin/sh

set -xe

MAINTENANCE_ENABLED="$SF_APP_CONTAINER_DIR/web/.maintenance.enable"
MAINTENANCE_WEB="$SF_APP_CONTAINER_DIR/web/.maintenance.web"

#enable maintenance mode
install -m 777 /dev/null "$MAINTENANCE_ENABLED"
install -m 777 /dev/null "$MAINTENANCE_WEB"

envsubst '$$HTTPDUSER' < /usr/local/apache2/conf/httpd.template > /usr/local/apache2/conf/httpd.conf
envsubst '$$SERVER_NAME $$SERVER_ADMIN $$APP_WEB_DIR $$PHP_FPM_URL $$SF_APP_ENV_INDEX' < /usr/local/apache2/conf/extra/httpd-ssl.template > /usr/local/apache2/conf/extra/httpd-ssl.conf

# fix folder permissions - default
# use sync between chmod or FS permission change won't keep up
chmod -R 644 $SF_APP_CONTAINER_DIR
sync

find $SF_APP_CONTAINER_DIR -type d|xargs -I{} chmod 755 "{}"
sync

# add apache2 writable parameters.yml
install -m 644 -o $HTTPDUSER -g $HTTPDUSER /dev/null $SF_APP_CONTAINER_DIR/app/config/parameters.yml
sync

mkdir -p \
    $SF_APP_CONTAINER_DIR/bin \
    $SF_APP_CONTAINER_DIR/vendor

#for developer mounted folders
if [ "$SYMFONY_ENV" = "dev" ] || [ "$SYMFONY_ENV" = "test" ] ; then
    chmod -R 777 \
        $SF_APP_CONTAINER_DIR/app/config \
        $SF_APP_CONTAINER_DIR/bin \
        $SF_APP_CONTAINER_DIR/composer.* \
        $SF_APP_CONTAINER_DIR/var \
        $SF_APP_CONTAINER_DIR/vendor \
        $SF_APP_CONTAINER_DIR/web
    sync
    chmod -R 666 \
        $SF_APP_CONTAINER_DIR/app/config/*.yml \
        $SF_APP_CONTAINER_DIR/app/config/*.dist \
        $SF_APP_CONTAINER_DIR/web/config.php
    sync
    chown -R $HTTPDUSER:$HTTPDUSER \
        $SF_APP_CONTAINER_DIR/app/config \
        $SF_APP_CONTAINER_DIR/bin \
        $SF_APP_CONTAINER_DIR/composer.* \
        $SF_APP_CONTAINER_DIR/var \
        $SF_APP_CONTAINER_DIR/vendor \
        $SF_APP_CONTAINER_DIR/web
else
    chown -R $HTTPDUSER.$HTTPDUSER $SF_APP_CONTAINER_DIR
    sync
    chmod -R a+x \
        $SF_APP_CONTAINER_DIR/bin
fi
sync

#disable web maintenance mode
rm -f "$MAINTENANCE_WEB"

# run as different user
#exec su-exec $USER "$@"
exec "$@"