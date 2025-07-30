#!/bin/bash
# Generate configuration files from templates.

# create the local data directory.
mkdir -p /data/funes/cert_cache
chown -R www-data:www-data /data/funes

if [ -z "$VERBOSE" ]
then
	export VERBOSE=false
fi

# Root CA cert config.
if [ ! -z "$ROOT_CA_CERT" ] && [ ! -z "$ROOT_CA_KEY" ]; then
	echo "Using root CA cert: $ROOT_CA_CERT $ROOT_CA_KEY"
	echo "Looking for root CA cert, will retry every 5s if not found"
	while true; do
		if test -f "$ROOT_CA_CERT" && test -f "$ROOT_CA_KEY"; then
			echo "Root CA cert found"
			break
		else
			sleep 5
		fi
	done
else
	echo "Using default root CA cert"
	# generate and use the
	export ROOT_CA_CERT=/data/funes/root_ca.crt
	export ROOT_CA_KEY=/data/funes/root_ca.key
	if test -f "$ROOT_CA_CERT" && test -f "$ROOT_CA_KEY"; then
	    echo "Default root CA files exist"
	else
		echo "Default root CA files missing, generating..."
		openssl req -x509 -outform PEM -new -nodes -newkey rsa:2048 -days 365 -out $ROOT_CA_CERT -subj "/C=US/ST=California/L=San Francisco/O=Funes Signing Authority/CN=Funes Signing Authority" -keyout $ROOT_CA_KEY
	fi
	if [ "$VERBOSE" != "false" ]; then
		echo
		cat $ROOT_CA_CERT
		echo
	fi
fi

# Give www-data access to the root CA cert and key.
chown www-data $ROOT_CA_CERT
chown www-data $ROOT_CA_KEY

## Run this if you want to add the root CA cert to local certificate store.
# cp $ROOT_CA_CERT /usr/local/share/ca-certificates/
# update-ca-certificates

if [ -z "$LOG_DIR" ]
then
    export LOG_DIR="./logs"
fi

if [ -z "$CONTENT_CACHE_DIR" ]
then
	export CONTENT_CACHE_DIR="/data/funes/content_cache"
fi
if [ -z "$CONTENT_CACHE_KEYS_ZONE" ]
then
	export CONTENT_CACHE_KEYS_ZONE="10m"
fi

# Get available disk space in Gigabytes. Using -l to only check local filesystems.
DISK_SPACE_GB=$(($(lsblk -d -b -o SIZE /dev/sda | tail -n 1) / 1073741824))

# Define cache size bounds in GB
LOWER_BOUND_GB=10
UPPER_BOUND_GB=100

echo "LOWER_BOUND_GB: ${LOWER_BOUND_GB}g. UPPER_BOUND_GB: ${UPPER_BOUND_GB}g. Disk Size ${DISK_SPACE_GB}."

# Ensure the upper bound is at least the lower bound
if [ "$UPPER_BOUND_GB" -lt "$LOWER_BOUND_GB" ]; then
    UPPER_BOUND_GB=$LOWER_BOUND_GB
fi

if [ -z "$CONTENT_CACHE_SIZE" ]; then
    # If CONTENT_CACHE_SIZE is not set, calculate a default.
    if [ "$DISK_SPACE_GB" -gt 32 ]; then
        # If disk space is > 32GB, use half of it for cache
        CACHE_SIZE_GB=$((DISK_SPACE_GB / 2))
    else
        # Otherwise, use the default 10g
        CACHE_SIZE_GB=10
    fi
else
    # If CONTENT_CACHE_SIZE is set, parse the numeric value.
    CACHE_SIZE_GB=$(echo "$CONTENT_CACHE_SIZE" | sed 's/[gG]$//')
fi

# Clamp the cache size to the defined bounds
if [ "$CACHE_SIZE_GB" -lt "$LOWER_BOUND_GB" ]; then
    echo "Cache size is below the ${LOWER_BOUND_GB}g minimum. Adjusting to ${LOWER_BOUND_GB}g."
    CACHE_SIZE_GB=$LOWER_BOUND_GB
elif [ "$CACHE_SIZE_GB" -gt "$UPPER_BOUND_GB" ]; then
    echo "Cache size exceeds the upper bound of ${UPPER_BOUND_GB}g. Adjusting to ${UPPER_BOUND_GB}g."
    CACHE_SIZE_GB=$UPPER_BOUND_GB
fi

export CONTENT_CACHE_SIZE="${CACHE_SIZE_GB}g"

if [ -z "$CERT_MEM_CACHE_TTL_SEC" ]
then
	export CERT_MEM_CACHE_TTL_SEC="3600"
fi
if [ -z "$SSL_VERIFY_DEPTH" ]
then
	export SSL_VERIFY_DEPTH="3"
fi
if [ -z "$PROXY_BUFFER_SIZE" ]
then
	export PROXY_BUFFER_SIZE="4k"
fi
if [ -z "$PROXY_BUFFERS" ]
then
	export PROXY_BUFFERS="4 4k"
fi
if [ -z "$PROXY_BUSY_BUFFERS_SIZE" ]
then
	export PROXY_BUSY_BUFFERS_SIZE="4k"
fi
if [ -z "$PROXY_CONNECT_DATA_TIMEOUT" ]
then
	export PROXY_CONNECT_DATA_TIMEOUT="60s"
fi
if [ -z "$PROXY_READ_DATA_TIMEOUT" ]
then
	export PROXY_READ_DATA_TIMEOUT="60s"
fi

printf 'LOG_DIR=%s\n' "$LOG_DIR"
printf 'CONTENT_CACHE_DIR=%s\n' "$CONTENT_CACHE_DIR"
printf 'CONTENT_CACHE_KEYS_ZONE=%s\n' "$CONTENT_CACHE_KEYS_ZONE"
printf 'CONTENT_CACHE_SIZE=%s\n' "$CONTENT_CACHE_SIZE"
printf 'CERT_MEM_CACHE_TTL_SEC=%s\n' "$CERT_MEM_CACHE_TTL_SEC"
printf 'SSL_VERIFY_DEPTH=%s\n' "$SSL_VERIFY_DEPTH"
printf 'PROXY_BUFFER_SIZE=%s\n' "$PROXY_BUFFER_SIZE"
printf 'PROXY_BUFFERS=%s\n' "$PROXY_BUFFERS"
printf 'PROXY_BUSY_BUFFERS_SIZE=%s\n' "$PROXY_BUSY_BUFFERS_SIZE"
printf 'PROXY_CONNECT_DATA_TIMEOUT=%s\n' "$PROXY_CONNECT_DATA_TIMEOUT"
printf 'PROXY_READ_DATA_TIMEOUT=%s\n' "$PROXY_READ_DATA_TIMEOUT"

# Uncomment for testing
# export NAMESERVER="127.0.0.11"
if [ -z "$NAMESERVER" ]; then
	# This is the recommended method for finding the local nameserver using /etc/resolv.conf.
	# https://trac.nginx.org/nginx/ticket/658
	export NAMESERVER=`cat /etc/resolv.conf | grep "nameserver" | awk '{print $2}' | tr '\n' ' '`
fi

echo "Nameserver is: $NAMESERVER"

echo "Copying nginx config"
envsubst '${ROOT_CA_CERT} ${ROOT_CA_KEY} ${LOG_DIR} ${PROXY_BUFFER_SIZE} ${PROXY_BUFFERS} ${PROXY_BUSY_BUFFERS_SIZE}' < ./conf/nginx.conf.template > ./conf/nginx.conf
envsubst '${PROXY_CONNECT_DATA_TIMEOUT} ${PROXY_READ_DATA_TIMEOUT} ${NAMESERVER} ${LOG_DIR} ${CONTENT_CACHE_DIR} ${CONTENT_CACHE_KEYS_ZONE} ${CONTENT_CACHE_SIZE} ${SSL_VERIFY_DEPTH}' < ./conf/nginx.conf.server.template > ./conf/nginx.conf.server
envsubst '${ROOT_CA_CERT} ${ROOT_CA_KEY} ${CERT_MEM_CACHE_TTL_SEC}' < ./conf/generate_ssl_certs.template.lua > ./conf/generate_ssl_certs.lua
