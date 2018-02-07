dev:
	sh scripts/dev.sh

dev-persistent:
	sh do some stuff

# Below commands are intended to be run inside the Docker container.
start:
	sh start.sh

sniff:
	tcptrack -i eth0 -r 2

rmcache:
	rm -rf /tmp/fwd_proxy_cache

tail-cache:
	tail -f /usr/local/nginx/logs/cache.log

tail-error:
	tail -f /usr/local/nginx/logs/error.log

tail-logs:
	tail -f /usr/local/nginx/logs/*.log
