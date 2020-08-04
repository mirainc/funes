set -e

START_DIR=$(pwd)

cd ./extract/nginx-1.18.0

./configure --prefix=$START_DIR/build --add-module=$START_DIR/ngx_http_proxy_connect_module --with-http_ssl_module --with-http_slice_module

make && make install
