#!/bin/bash

set -e

## start local dns server
## this can be used in place of the proxy_connect_address nginx directive
# dnsmasq --port 53 --no-hosts --no-resolv -C "/usr/src/app/dnsmasq.conf"

sh ./generate_conf_files.sh

# create the local data directory.
mkdir -p /data/funes/cert_cache
chown -R www-data:www-data /data/funes

# make sure the root CA certs are present. if not, generate them.
ROOT_CA_CERT=/data/funes/root_ca.crt
ROOT_CA_KEY=/data/funes/root_ca.key
if test -f "$ROOT_CA_CERT" && test -f "$ROOT_CA_KEY"; then
    echo "Root CA files exist"
else
	echo "Root CA files missing, generating..."
	openssl req -x509 -outform PEM -new -nodes -newkey rsa:2048 -days 365 -out $ROOT_CA_CERT -subj "/C=US/ST=California/L=San Francisco/O=Funes Signing Authority/CN=Funes Signing Authority" -keyout $ROOT_CA_KEY
fi

echo "Starting Funes"
./bin/openresty -p $(pwd) -g 'daemon off;'
