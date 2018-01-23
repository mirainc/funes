cp ./nginx.conf /etc/nginx/nginx.conf
cp ./default.conf /etc/nginx/conf.d

nginx -g 'daemon off;'
