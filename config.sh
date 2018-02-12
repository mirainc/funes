set -e

mkdir -p ./build/certs

cp ./conf/nginx.conf ./build/conf/nginx.conf
cp ./conf/nginx.conf.default ./build/conf/nginx.conf.default

cp ./certs/nginx.crt ./build/conf/nginx.crt
cp ./certs/nginx.key ./build/conf/nginx.key
cp ./certs/cacert.pem ./build/conf/cacert.pem

cp ./scripts/run.sh ./build/run.sh
