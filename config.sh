set -e

mkdir -p /data
mkdir -p ./build/certs

cp ./conf/nginx.conf ./build/conf
cp ./conf/nginx.conf.server ./build/conf

cp ./certs/nginx.crt ./build/conf
cp ./certs/nginx.key ./build/conf
cp ./certs/cacert.pem ./build/conf

cp ./scripts/*.sh ./build
