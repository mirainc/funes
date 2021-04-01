set -e

mkdir -p ./build/certs
mkdir -p ./build/logs

# Copy Openresty Nginx conf to current dir.
rm -rf ./build/conf
cp -r ./build/nginx/conf ./build

cp ./conf/nginx.conf.template ./build/conf
cp ./conf/nginx.conf.server.template ./build/conf
cp ./conf/*.lua ./build/conf

# Enable transparent mode if not explicitly disabled
mkdir -p ./build/conf/transparent_proxy
if [ -z "${DISABLE_TRANSPARENT_PROXY}" ]; then
    cp ./conf/transparent_proxy/*.conf ./build/conf/transparent_proxy
else
    rm -rf ./build/conf/transparent_proxy/*
fi

mkdir -p ./build/conf/restrict_local
if [ -z "${RESTRICT_LOCAL}" ]; then
    rm -rf ./build/conf/restrict_local/restrict_local.conf
else
    cp ./conf/restrict_local/restrict_local.conf ./build/conf/restrict_local
fi

if [ -z "${RESTRICT_LOCAL_DOCKER}" ]; then
    rm -rf ./build/conf/restrict_local/restrict_local_docker.conf
else
    cp ./conf/restrict_local/restrict_local_docker.conf ./build/conf/restrict_local
fi

mkdir -p ./build/conf/dynamic_certs
if [ -z "${DISABLE_DYNAMIC_CERTS}" ]; then
    cp ./conf/dynamic_certs/*.conf ./build/conf/dynamic_certs
else
    rm -rf ./build/conf/dynamic_certs/*.conf
fi

mkdir -p ./build/conf/forward_cache_expiry_override
if [ -z "${DISABLE_FORWARD_CACHE_EXPIRY_OVERRIDE}" ]; then
    cp ./conf/forward_cache_expiry_override/*.conf ./build/conf/forward_cache_expiry_override
else
    rm -rf ./build/conf/forward_cache_expiry_override/*.conf
fi

mkdir -p ./build/conf/range_cache_expiry_override
if [ -z "${DISABLE_RANGE_CACHE_EXPIRY_OVERRIDE}" ]; then
    cp ./conf/range_cache_expiry_override/*.conf ./build/conf/range_cache_expiry_override
else
    rm -rf ./build/conf/range_cache_expiry_override/*.conf
fi

cp ./certs/nginx.crt ./build/conf
cp ./certs/nginx.key ./build/conf
cp ./certs/cacert.pem ./build/conf

cp ./scripts/*.sh ./build

# Replace the openresty symlink with the actual nginx binary to allow copying across systems.
rm -rf ./build/bin/openresty
cp ./build/nginx/sbin/nginx ./build/bin/openresty
chmod +x ./build/bin/openresty
