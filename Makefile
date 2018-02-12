dev:
	sh dev.sh

run:
	cd build && sh run.sh

sniff:
	tcptrack -i eth0 -r 2

rmcache:
	rm -rf /tmp/fwd_proxy_cache

tail-cache:
	tail -f build/logs/cache.log

tail-error:
	tail -f build/logs/error.log

tail-logs:
	tail -f build/logs/*.log

install: build configure

configure:
	sh config.sh

build: patch
	sh build.sh

patch: download
	sh patch.sh

download:
	mkdir -p download
	wget -P download http://nginx.org/download/nginx-1.12.1.tar.gz
	tar -xzvf download/nginx-1.12.1.tar.gz -C download

clean: clean-build clean-download

clean-build:
	rm -rf build

clean-download:
	rm -rf download
	rm patch
