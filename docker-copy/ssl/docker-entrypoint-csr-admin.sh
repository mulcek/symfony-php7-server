#!/bin/sh

[ "$SYMFONY_ENV" = "dev" ] && set -xe || set -e

SSL_CA_DIR="$SSL_BASE_DIR/demoCA"
SERVICE_CA_IN_PROGRESS="$SSL_BASE_DIR/.ca-in-progress"
PFX_FOLDER="$SSL_CA_DIR/pfx_user_certificates"
REQUESTS_FOLDER="$SSL_CA_DIR/requests"
HTTPS_APACHE_DIR="$SSL_CA_DIR/apache_ssl"

echo -e "\e[01;37mWaiting for CA service to stop\e[0m"
echo -e "\e[01;37m=======================================================================\e[0m"

sleep 5

while [ -f "$SERVICE_CA_IN_PROGRESS" ]
do
  sleep 1
done

echo -e "\e[01;37mCreating Admin server CSR SSL certificate...\e[0m"
echo -e "\e[01;37m=======================================================================\e[0m"

cd $SSL_BASE_DIR
cp -p /etc/ssl/openssl.cnf $SSL_BASE_DIR/openssl-custom.cnf

echo -e "\n\e[01;37mCreating CSR private key:\e[00m"

# automate input
/usr/bin/expect << EOD
set timeout 5

spawn openssl genrsa -aes256 -out $REQUESTS_FOLDER/admin.server.csrkey.pem 2048 -config $SSL_BASE_DIR/openssl-custom.cnf

expect "Enter pass phrase *:"
send   "$SSL_CSR_PASSWORD\n"

expect "Verifying - Enter pass phrase *:"
send   "$SSL_CSR_PASSWORD\n"

expect eof
EOD

echo -e "\n\e[01;37mCreating a insecure CSR so password is not needed everytime apache starts:\e[00m"
# automate input
/usr/bin/expect << EOD
set timeout 3

spawn openssl rsa -in $REQUESTS_FOLDER/admin.server.csrkey.pem -out $REQUESTS_FOLDER/admin.server.csr.key

expect "Enter pass phrase * .pem:"
send   "$SSL_CSR_PASSWORD\n"
 
expect eof
EOD

echo -e "\e[00;32mCreating password-less CSR...\e[00m"

# automate input
/usr/bin/expect << EOD
set timeout 3

spawn openssl req -new -days $SSL_CSR_DAYS_VALID -utf8 -key $REQUESTS_FOLDER/admin.server.csr.key -out $REQUESTS_FOLDER/admin.server.csr.unsigned.crt -config $SSL_BASE_DIR/openssl-custom.cnf

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
send  	"$SSL_CSR_COMMON_NAME\n"

expect	"Email Address*:"
send 	"\n"

expect	"A challenge password*:"
send 	".\n"

expect	"An optional company name*:"
send 	".\n"

expect eof
EOD

echo -e "\e[00;32mSigning the CSR:\e[00m"
# automate input
/usr/bin/expect << EOD
set timeout 3

spawn openssl ca -days $SSL_CSR_DAYS_VALID -in $REQUESTS_FOLDER/admin.server.csr.unsigned.crt -out $REQUESTS_FOLDER/admin.server.csr.crt -config $SSL_BASE_DIR/openssl-custom.cnf

expect "Enter pass phrase * cakey.pem:"
send   "$SSL_CA_PASSWORD\r"

expect "y/n*:"
send   "y\n"

expect "y/n*:"
send   "y\n"

expect eof
EOD

chown www-data:www-data \
    $REQUESTS_FOLDER/cacert.pem \
    $REQUESTS_FOLDER/admin.server.csr.crt \
    $REQUESTS_FOLDER/admin.server.csr.key \
    $REQUESTS_FOLDER/cacert.pem

chmod 400  \
    $REQUESTS_FOLDER/cacert.pem \
    $REQUESTS_FOLDER/admin.server.csr.crt \
    $REQUESTS_FOLDER/admin.server.csr.key \
    $REQUESTS_FOLDER/cacert.pem \
    $REQUESTS_FOLDER/admin.server.csrkey.pem \
    $REQUESTS_FOLDER/admin.server.csr.unsigned.crt

echo -e "\e[00;32mOK!\e[00m"