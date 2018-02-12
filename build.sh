set -e

START_DIR=$(pwd)

cd ./download/nginx-1.12.1

./configure --prefix=$START_DIR/build --add-module=$START_DIR/ngx_http_proxy_connect_module --with-http_ssl_module --with-http_slice_module

make && make install
