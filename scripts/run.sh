#!/bin/bash

set -e

## start local dns server
## this can be used in place of the proxy_connect_address nginx directive
# dnsmasq --port 53 --no-hosts --no-resolv -C "/usr/src/app/dnsmasq.conf"

echo "Generating configuration"
bash ./generate_conf_files.sh

# create the local data directory.
mkdir -p /data/funes/cert_cache
chown -R www-data:www-data /data/funes

echo "Starting Funes"
./bin/openresty -p $(pwd) -g 'daemon off;'
