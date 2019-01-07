set -e

mkdir -p /data
mkdir -p ./build/certs

cp ./conf/nginx.conf.template ./build/conf
cp ./conf/nginx.conf.server.template ./build/conf

# Enable transparent mode if not explicitly disabled
mkdir -p ./build/conf/transparent_proxy
if [ -z "${DISABLE_TRANSPARENT_PROXY}" ]; then
    cp ./conf/transparent_proxy/*.conf ./build/conf/transparent_proxy
else
    rm -rf ./build/conf/transparent_proxy/*
fi

cp ./certs/nginx.crt ./build/conf
cp ./certs/nginx.key ./build/conf
cp ./certs/cacert.pem ./build/conf

cp ./scripts/*.sh ./build
