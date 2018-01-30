set -e

# sleep infinity

cp ./nginx.conf /usr/local/nginx/conf/nginx.conf
cp ./default.conf /usr/local/nginx/conf/nginx.conf.default

cp ./certs/nginx.crt /usr/local/nginx/nginx.crt
cp ./certs/nginx.key /usr/local/nginx/nginx.key

# start local dns server
dnsmasq --port 53 --no-hosts --no-resolv -C "/usr/src/app/dnsmasq.conf"

/usr/local/nginx/sbin/nginx -g 'daemon off;'
