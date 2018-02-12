default: run

dev:
	sh dev.sh

run: install
	cd build && sh run.sh

install: build configure

configure:
	sh config.sh

build: patch
	sh build.sh

patch: extract
	sh patch.sh

extract: download
	mkdir -p extract
	tar -xzvf download/nginx-1.12.1.tar.gz -C extract

download:
	mkdir -p download
	wget -P download http://nginx.org/download/nginx-1.12.1.tar.gz

clean: clean-build clean-download clean-extract

clean-build:
	rm -rf build

clean-extract:
	rm -rf extract
	rm patch

clean-download:
	rm -rf download

sniff:
	tcptrack -i eth0 -r 2

rmcache:
	rm -rf /data/fwd_proxy_cache

tail-cache:
	tail -f build/logs/cache.log

tail-error:
	tail -f build/logs/error.log

tail-logs:
	tail -f build/logs/*.log
