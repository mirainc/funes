set -e

START_DIR=$(pwd)

cd ./download/nginx-1.12.1

patch -p1 < $START_DIR/ngx_http_proxy_connect_module/proxy_connect_rewrite.patch

touch $START_DIR/patch
