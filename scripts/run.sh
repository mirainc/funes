#!/bin/bash

set -e

## start local dns server
## this can be used in place of the proxy_connect_address nginx directive
# dnsmasq --port 53 --no-hosts --no-resolv -C "/usr/src/app/dnsmasq.conf"

echo "Generating configuration"
bash ./generate_conf_files.sh

echo "Starting Funes"
# Add the local luajit libraries to shared library paths.
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)/luajit/lib
./bin/openresty -p $(pwd) -g 'daemon off;'
