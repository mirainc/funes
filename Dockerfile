FROM ubuntu:16.04

RUN mkdir -p /usr/src/app

# Install Nginx + proxy connect
RUN apt-get update
RUN apt-get -y install wget patch build-essential libpcre3 libpcre3-dev
RUN apt-get -y install zlib1g-dev
RUN apt-get -y install libssl-dev


RUN mkdir -p /usr/tmp
WORKDIR /usr/tmp

COPY ngx_http_proxy_connect_module ./ngx_http_proxy_connect_module
RUN wget http://nginx.org/download/nginx-1.12.1.tar.gz
RUN tar -xzvf nginx-1.12.1.tar.gz
WORKDIR /usr/tmp/nginx-1.12.1

## Use this instead of proxy_connect_rewrite if don't want to use proxy_connect_address directive
# RUN patch -p1 < /usr/tmp/ngx_http_proxy_connect_module/proxy_connect.patch
RUN patch -p1 < /usr/tmp/ngx_http_proxy_connect_module/proxy_connect_rewrite.patch

RUN ./configure --add-module=/usr/tmp/ngx_http_proxy_connect_module --with-http_ssl_module --with-http_slice_module
RUN make && make install

# Install dnsmasq. Only required if not using proxy_connect_rewrite
# RUN apt-get -y install dnsmasq

# Install debugging tools
# RUN apt-get -y install dnsutils curl vim

RUN mkdir -p /usr/local/nginx/logs/

EXPOSE 80 443

WORKDIR /usr/src/app

CMD ["sh", "./start.sh"]
