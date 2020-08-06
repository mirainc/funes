set -e

START_DIR=$(pwd)

cd ./extract/openresty-1.17.8.2

# patch -p1 < $START_DIR/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1018.patch
# patch -p1 < $START_DIR/allow_options_cache.patch

touch $START_DIR/patch
