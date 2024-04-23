## install development libraries for Ubuntu
#sudo apt-get install build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libgd-dev libxml2 libxml2-dev uuid-dev libxslt1-dev libgeoip-dev libgoogle-perftools-dev

./configure --prefix=$(pwd)/output \
  --with-pcre  --with-http_ssl_module \
  --with-http_image_filter_module \
  --with-http_v2_module \
  --with-stream \
  --with-http_addition_module \
  --with-http_mp4_module

## For test cases of nginx-tests 
#sudo perl -MCPAN -e "install IO::Socket::SSL"
