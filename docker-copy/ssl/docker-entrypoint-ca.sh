#!/bin/sh

[ "$SYMFONY_ENV" = "dev" ] && set -xe || set -e

SSL_CA_DIR="$SSL_BASE_DIR/demoCA"
SERVICE_CA_IN_PROGRESS="$SSL_BASE_DIR/.ca-in-progress"
#PFX_FOLDER="$SSL_CA_DIR/pfx_user_certificates"

install -m 777 /dev/null "$SERVICE_CA_IN_PROGRESS"

echo -e "\e[01;37mCreating SSL CA Authority - deleting existing\e[0m"
echo -e "\e[01;37m=======================================================================\e[0m"

rm -fR \
    $SSL_BASE_DIR/*

echo -e "\e[01;37mCreate necessary folders\e[00m"
mkdir -p \
    $SSL_CA_DIR/private \
    $SSL_CA_DIR/newcerts \
    $SSL_CA_DIR/certs \
    $SSL_CA_DIR/crl \
    $SSL_CA_DIR/requests \
    $SSL_CA_DIR/user \
    $SSL_CA_DIR/pfx_user_certificates

cp -p /etc/ssl/openssl.cnf $SSL_BASE_DIR/openssl-custom.cnf

cd $SSL_CA_DIR

echo -e "\e[01;37mCreate some necessary files\e[00m"
touch index.txt
echo '01' > serial

echo -e "\e[01;37mGenerate the CA’s Private Key with data baked in...\e[00m"

# automate input
/usr/bin/expect << EOD
set timeout 5

spawn openssl genrsa -aes256 -out $SSL_CA_DIR/private/cakey.pem 4096 -config $SSL_BASE_DIR/openssl-custom.cnf
expect  "Enter * private/cakey.pem:"
send    "$SSL_CA_PASSWORD\r"

expect  "Verifying * private/cakey.pem:"
send    "$SSL_CA_PASSWORD\r"

expect eof
EOD

echo -e "\e[01;37mCreate the CA Root Certificate\e[00m"

# automate input
/usr/bin/expect << EOD
set timeout 5

spawn openssl req -new -x509 -days $SSL_CA_DAYS_VALID -utf8 -key $SSL_CA_DIR/private/cakey.pem -out $SSL_CA_DIR/cacert.pem -set_serial 0  -config $SSL_BASE_DIR/openssl-custom.cnf

expect "Enter * private/cacert.pem:"
send   "$SSL_CA_PASSWORD\n"

expect "Country Name*:"
send   "$SSL_COUNTRY_CODE\n"

expect "State or Province Name*:"
send   "$SSL_STATE_NAME\n"

expect  "Locality Name*:"
send  	"$SSL_LOCALITY_NAME\n"

expect  "Organization Name*:"
send  	"$SSL_ORGANIZATION_NAME\n"

expect  "Organizational Unit Name*:"
send  	"$SSL_ORGANIZATIONAL_UNIT_NAME\n"

expect  "Common Name*:"
send  	"$SSL_CA_COMMON_NAME\n"

expect	"Email Address*:"
send 	"$SSL_EMAIL_ADDRESS\n"

expect eof
EOD

echo -e "\e[01;37mMaking sure that only root can access the CA folder and especially the private key.\e[00m"
chmod -R 600 $SSL_CA_DIR

echo -e "\e[01;37mCopying authority ca-bundle.crt to webserver folder\e[00m"
cp $SSL_CA_DIR/cacert.pem $SSL_CA_DIR/requests/

rm -f "$SERVICE_CA_IN_PROGRESS"

echo -e "\e[00;32mOK!\e[00m\n"