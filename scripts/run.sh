set -e

## start local dns server
## this can be used in place of the proxy_connect_address nginx directive
# dnsmasq --port 53 --no-hosts --no-resolv -C "/usr/src/app/dnsmasq.conf"

sh ./generate_conf_files.sh

./sbin/nginx -p $(pwd) -g 'daemon off;'
