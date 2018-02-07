# funes

A forward proxy with caching.

*"I was struck by the thought that every word I spoke, every expression of my face or motion of my hand would endure in his implacable memory..."*

## Start

This assumes you are using `docker-machine` on a Mac.

```
make start
```

## Configuring browser proxy

These assume that you are running `docker-machine` on port `192.168.99.100` with the port configuration set in `docker-compose.yml`.

### Chrome

Start chrome with the following flag:
```
--proxy-server="https=192.168.99.100:3128;http=192.168.99.100:3128"
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

To redirect all HTTPS requests received by the tunnel back to Nginx, a local `dnsmasq` instance is started that responds to all DNS requests with `127.0.0.1`. This local `dnsmasq` is configured as the DNS resolver for the proxy.

- Basic proxy setup taken from: https://stackoverflow.com/questions/46060028/how-to-use-nginx-as-forward-proxy-for-any-requested-location
- Cache config for proxy_cache: https://www.nginx.com/blog/nginx-caching-guide/

## Todo
- [ ] Implement base case cache strategy
- [ ] Allow specifying other cache cases
- [ ] Static fallback content?
