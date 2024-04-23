default: install

dev-build:
	docker-compose kill
	docker-compose -f docker-compose.yml build # --no-cache

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

build: extract
	sh build.sh

extract: download
	mkdir -p extract
	tar -xzvf download/openresty-1.25.3.1.tar.gz -C extract

download:
	mkdir -p download
	wget -P download https://openresty.org/download/openresty-1.25.3.1.tar.gz

clean: clean-build clean-download clean-extract clean-package

clean-build:
	rm -rf build

clean-extract:
	rm -rf extract

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
