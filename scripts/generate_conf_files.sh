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
if [ -z "$CONTENT_CACHE_SIZE" ]
then
	export CONTENT_CACHE_SIZE="10g"
fi
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
