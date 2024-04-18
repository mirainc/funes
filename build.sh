set -e

START_DIR=$(pwd)

cd ./extract/openresty-1.25.3.1

./configure --prefix=$START_DIR/build --add-module=$START_DIR/ngx_http_proxy_connect_module --with-http_ssl_module --with-http_slice_module --with-luajit

# Patch nginx
patch -d build/nginx-1.25.3/ -p 1 < $START_DIR/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_102101.patch
patch -d build/nginx-1.25.3/ -p 1 < $START_DIR/patches/allow_options_cache.patch
patch -d build/nginx-1.25.3/ -p 1 < $START_DIR/patches/force_cacheable.patch

make && make install
