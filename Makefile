default: install

dev:
	sh dev.sh

.PHONY: test
test:
	sh test.sh

run: install
	cd build && sh run.sh

package: install clear-logs
	mkdir -p package
	zip -r package/funes.zip build

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

clean: clean-build clean-download clean-extract clean-package

clean-build:
	rm -rf build

clean-extract:
	rm -rf extract
	rm patch

clean-download:
	rm -rf download

clean-package:
	rm -rf package

sniff:
	tcptrack -i eth0 -r 2

clear-cache:
	rm -rf /data/funes_rmb_cache/*

make clear-logs:
	cd build && sh logtruncate.sh

tail-cache:
	tail -f build/logs/cache.log

tail-rangecache:
	tail -f build/logs/range_cache.log

tail-error:
	tail -f build/logs/error.log

tail-logs:
	tail -f build/logs/*.log
