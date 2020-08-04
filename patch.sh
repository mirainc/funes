set -e

START_DIR=$(pwd)

cd ./extract/nginx-1.18.0

patch -p1 < $START_DIR/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1018.patch

touch $START_DIR/patch
