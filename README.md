symfony-php7-server
============
PHP Symfony webserver and backend. Created with docker-compose services (PHP7, PHP-fpm, MariaDB, Apache 2.4) using Alpine as base OS for minimum image sizes (except MariaDB).

Prerequisites
------------

Install docker, python-pip and docker compose. For details take a look at vendors web site.

* apt install docker python-pip
* pip install docker-compose

Host preparation
------------

Create project folder at path:

    mkdir -p ~/Development/todo-app/
    cd ~/Development/todo-app/
    git clone https://github.com/mulcek/symfony-php7-server.git .


Create user specific settings folder at path (use folder template from repository):

    cp ~/Development/todo-app/host-settings-example ~/
    mv ~/host-settings-example ~/todo-app
    cd ~/todo-app/

Update config files, especialy .env at ~/todo-app/. You can leave it as is just to start demo. For certificate validation you should add 'todo.docker' to /etc/hosts at localhost ip.


Build SSL certificates for HTTPS to work:
------------

    cd ~/todo-app/
    docker-compose -f ssl.yml up --build ca
    docker-compose -f ssl.yml up --build admin_csr


Starting services:
------------

    cd ~/todo-app/
    docker-compose -f app.yml up -d --build

Stopping services:
------------

    cd ~/todo-app/
    docker-compose -f app.yml down

Logs of services:
------------

    cd ~/todo-app/
    docker-compose -f app.yml logs -f

Open app in a browser:
------------
Make sure you give services a minute to start up. First time run needs a lot more time, since it builds  database. Point your browser to:

    https://todo.docker/task/

APP functional tests:
------------
First you have to enter backend services CLI, to be able to use Symfony console and run tests. There will be some deprecation warnings, but that is normal, since for demo we can't really fix vendor bundles.

    cd ~/todo-app/
    docker-compose -f app.yml exec backend sh
    ./vendor/bin/phpunit

Removing all:
------------
You have to go through:

* stop services
* remove docker images
* remove docker volumes
* remove ~/todo-app/ and ~/Development/todo-app/


