#!/bin/sh

[ "$SYMFONY_ENV" = "dev" ] && set -xe || set -e

MAINTENANCE_ENABLED="$SF_APP_CONTAINER_DIR/web/.maintenance.enable"
MAINTENANCE_WEB="$SF_APP_CONTAINER_DIR/web/.maintenance.web"

COMPOSER_PARAM="--no-dev"

if [ "$SYMFONY_ENV" = "dev" ]; then
    COMPOSER_PARAM=
fi

echo -e "\e[33mWaiting for web service to be ready\e[0m"
echo -e "\e[33m=======================================================================\e[0m"
sleep 10

while [ -f "$MAINTENANCE_WEB" ]
do
  sleep 3
done

envsubst '$$SYMFONY__DATABASE__HOST $$SYMFONY__DATABASE__PORT $$SYMFONY__DATABASE__NAME $$SYMFONY__DATABASE__USER $$SYMFONY__DATABASE__PASSWORD $$SYMFONY__MAILER_TRANSPORT $$SYMFONY__MAILER_HOST $$SYMFONY__MAILER_PORT $$SYMFONY__MAILER_USER $$SYMFONY__MAILER_PASSWORD $$SYMFONY__DELIVERY_ADDRESS $$SYMFONY__LOCALE $$SYMFONY__SECRET $$SYMFONY__USER_COMPANY $$SYMFONY__REDIS__DEFAULT__DSN' < $SF_APP_CONTAINER_DIR/app/config/parameters.yml.dist > $SF_APP_CONTAINER_DIR/app/config/parameters.yml

cd $SF_APP_CONTAINER_DIR

echo -e "\e[33mInstalling vendors\e[0m"
composer install --optimize-autoloader --prefer-dist --no-interaction $COMPOSER_PARAM

echo -e "\e[33mWarming cache\e[0m"
php bin/console cache:warm

if [ "$WEBPREPARE" != "false" ] ; then
    
    echo -e "\e[33mDumping assets\e[0m"
    php bin/console assetic:dump

    echo -e "\e[33mCopy assets, that can't be dumped by assetic, but needed by wkhtmlto\e[0m"
    php bin/console mopa:bootstrap:install:font

    mkdir -p \
        web/fonts \
        web/images

    find $SF_APP_CONTAINER_DIR/vendor/components/font-awesome/fonts -type f -exec basename "{}" \;|xargs -I{} ln -fs $SF_APP_CONTAINER_DIR/vendor/components/font-awesome/fonts/"{}" $SF_APP_CONTAINER_DIR/web/fonts/"{}"

    find $SF_APP_CONTAINER_DIR/vendor/components/jqueryui/themes/cupertino/images -type f -exec basename "{}" \;| xargs -I{} ln -fs $SF_APP_CONTAINER_DIR/vendor/components/jqueryui/themes/cupertino/images/"{}" $SF_APP_CONTAINER_DIR/web/images/"{}"
fi

#if [ "$DBMIGRATE" != "false" ] ; then
#    echo -e "\e[33mDatabase migration\e[0m"
#    php bin/console doctrine:migrations:migrate --no-interaction
#fi

#disable maintenance mode
rm -f "$MAINTENANCE_ENABLED"

# run as different user
#exec su-exec $USER "$@"
exec "$@"