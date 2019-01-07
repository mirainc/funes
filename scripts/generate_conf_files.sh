# Generate configuration files from templates.
# envs: LOG_DIR
if [ -z "$LOG_DIR" ]
then
    export LOG_DIR="./logs"
fi
envsubst '${LOG_DIR}' < ./conf/nginx.conf.template > ./conf/nginx.conf
envsubst '${LOG_DIR}' < ./conf/nginx.conf.server.template > ./conf/nginx.conf.server
