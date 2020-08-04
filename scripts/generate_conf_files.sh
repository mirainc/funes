# Generate configuration files from templates.
# envs: LOG_DIR
if [ -z "$LOG_DIR" ]
then
    export LOG_DIR="./logs"
fi

# Uncomment for testing
# export NAMESERVER="127.0.0.11"
if [ -z "$NAMESERVER" ]; then
	export NAMESERVER=`cat /etc/resolv.conf | grep "nameserver" | awk '{print $2}' | tr '\n' ' '`
fi

echo "Nameserver is: $NAMESERVER"

echo "Copying nginx config"
envsubst '${LOG_DIR}' < ./conf/nginx.conf.template > ./conf/nginx.conf
envsubst '${NAMESERVER} ${LOG_DIR}' < ./conf/nginx.conf.server.template > ./conf/nginx.conf.server
