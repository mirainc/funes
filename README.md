# funes

A forward proxy with caching.

*"I was struck by the thought that every word I spoke, every expression of my face or motion of my hand would endure in his implacable memory..."*

Uses: https://github.com/chobits/ngx_http_proxy_connect_module/tree/96ae4e06381f821218f368ad0ba964f87cbe0266
(code copied to `ngx_http_proxy_connect_module`). Code is copied instead of using submodule as Github doesn't support including submodule code in releases.

## Dependencies

- `faketime`
- `openssl` (tested with version 1.0.2g)

## Start

funes listens on ports 80, 443, and 3128. By default it will cache all GET requests for 1 minute, with certain content types having longer expirations (see `conf/nginx.conf.server`). It will serve stale responses indefinitely if there is no network connection.

### Build for your local architecture

```
make
```

This will compile Nginx and place all required files in the `build` directory.

Inside the `build` directory, `bash run.sh` to start the application.

`make package` can be run to zip the `build` directory to `package/funes.zip`. The zip can be extracted and run elsewhere.


#### Build options

The following build options are available using environment variables:

```bash
# Disable the transparent proxy on port 80/443
DISABLE_TRANSPARENT_PROXY

# Disallow all connections except those from 127.0.0.1/24
RESTRICT_LOCAL

# Disallow all connections except from 127.0.0.1/24 and Docker IPs (172.18, 172.19, 172.21 prefixes)
# Cannot be combined with RESTRICT_LOCAL
RESTRICT_LOCAL_DOCKER
```

Usage example:
```bash
DISABLE_TRANSPARENT_PROXY=1 RESTRICT_LOCAL=1 make

DISABLE_TRANSPARENT_PROXY=1 RESTRICT_LOCAL_DOCKER=1 make
```

### Build for Docker

```
docker build -f Dockerfile.build .
docker run -d -p 3128:3128 <created_image_id>
```

## Development

```
make dev-build 		# Builds the docker container
make dev        	# Starts container and runs Funes.
```

will start a local development instance in Docker.

If you have not made any changes between runs of the Docker container, you can run `make dev` again to avoid having to rebuild Openresty.

After making changes, run `make dev-build` again to rebuild the container and pull in changes.

### Testing Changes

Run the full test suite:

```
make test
```

Due to Codeship limitations, it's not possible to run the full test suite in Codeship because you cannot disable the network adapter.

Full test suite should be run with `RUN_CONTEXT=local` after changes to test offline functionality.

### Customizing expiration rules

In `conf/nginx.conf.server`, expiration rules can be set for URI (`$uri_expiry`), host (`$host_expiry`), and content type (`$content_type_expiry`). By default there are only content type expiry rules defined. Refer to the examples in this file for usage patterns.

## Configuring browser proxy

### Chrome

Start chrome with the following flag:
```
--proxy-server="https=127.0.0.1:3128;http=127.0.0.1:3128"
```

### Electron

Wrap your call to `<electron_window>.loadURL` following this example:
```
mainWindow.webContents.session.setProxy({proxyRules:"https=192.168.99.100:3128;http=192.168.99.100:3128"}, function () {
      mainWindow.loadURL(url.format({
        pathname: path.join(__dirname, 'index.html'),
        protocol: 'file:',
        slashes: true
      }))
  });
```

## Architecture

funes is meant to be used as a caching proxy for browser clients that need to function seamlessly if offline.

When Chrome is configured to use a proxy `<proxy_host>:<proxy_port>`, it does the following
1. Sends HTTP requests to `<proxy_host>:<proxy_port>` instead of `<external_host>:80`
  - This request will contain a header `Host: <external_host`
2. Send a `CONNECT` request to `<proxy_host>:<proxy_port>`, which opens a tunnel to the proxy. Send the original request through the tunnel.

funes responds to these requests:
1. Send the request to `<external_host>:80`. Cache the result and return.
2. Open a tunnel to `<funes_host>:443`, which then receives the original HTTPS request. Send the request to `<external_host>:443`. Cache the result and return.

See https://en.wikipedia.org/wiki/HTTP_tunnel#HTTP_CONNECT_tunneling for more information on how tunneling works.

By default, the proxy server will cache everything with a TTL of 1 minute. If the resource cannot be refreshed after the TTL, it will continue serving the stale cached copy.

```
Details about other cache cases:
- content that is known to be unchanging (cache forever)
- anything else?
```

### Implementation

The main proxy server uses Nginx, and the [Nginx Proxy Connect](https://github.com/chobits/ngx_http_proxy_connect_module) module to implement HTTP `CONNECT` method handling (since Nginx does not natively support the `CONNECT` method).

~~To redirect all HTTPS requests received by the tunnel back to Nginx, a local `dnsmasq` instance is started that responds to all DNS requests with `127.0.0.1`. This local `dnsmasq` is configured as the DNS resolver for the proxy.~~ Although dnsmasq works well for this purpose, we now use the `proxy_connect_address` directive provided by the Nginx Proxy Connect module, which redirects all proxied traffic to the specified address.

- Basic proxy setup taken from: https://stackoverflow.com/questions/46060028/how-to-use-nginx-as-forward-proxy-for-any-requested-location
- Cache config for proxy_cache: https://www.nginx.com/blog/nginx-caching-guide/
