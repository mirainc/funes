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

mkdir -p ./build/conf/restrict_local
if [ -z "${RESTRICT_LOCAL}" ]; then
    rm -rf ./build/conf/restrict_local/*
else
    cp ./conf/restrict_local/*.conf ./build/conf/restrict_local
fi

cp ./certs/nginx.crt ./build/conf
cp ./certs/nginx.key ./build/conf
cp ./certs/cacert.pem ./build/conf

cp ./scripts/*.sh ./build
