import requests
import sultan
import os
import unittest
import time

from sultan.api import Sultan
s = Sultan()

PROXY_PATH = os.environ.get('PROXY_PATH', '127.0.0.1:3128')
RUN_CONTEXT = os.environ.get('RUN_CONTEXT', 'local')

if not PROXY_PATH:
    raise Exception('Expected PROXY_PATH environment variable to be set.')

proxies = {
    'http': 'http://' + PROXY_PATH,
    'https': 'https://' + PROXY_PATH,
}


HTTP_IMAGE_URL = 'http://www.webmfiles.org/wp-content/uploads/2010/05/webm-files.jpg'
HTTPS_IMAGE_URL = 'https://i.imgur.com/3YBkyf6.jpg'
HTTPS_VIDEO_URL = 'https://prefetch-video-sample.storage.googleapis.com/gbike.webm'
RSS_URL = 'http://www.avclub.com/rss'
HLS_STREAM_URL = 'http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8'
EXPIRED_SSL_URL = 'https://expired.badssl.com'


def fetch(url, headers=None):
    if headers is None:
        headers = {}
    return requests.get(url, proxies=proxies, headers=headers, verify=False)


def clear_cache():
    result = s.rm('-rf /data/funes_rmb_cache/*').run()
    if result.rc != 0:
        raise Exception('Failed to clear cache: %s' % result.stderr)


def can_disable_network():
    return RUN_CONTEXT == 'local'


def disable_network():
    if can_disable_network() and is_online():
        result = s.ifconfig('eth0 down').run()
        if result.rc != 0:
            raise Exception('Failed to disable network: %s' % result.stderr)


def enable_network():
    if not is_online():
        result = s.ifconfig('eth0 up').run()
        if result.rc != 0:
            raise Exception('Failed to enable network: %s' % result.stderr)

        result = s.route('add default gw 172.20.0.1 eth0').run()
        if result.rc != 0:
            raise Exception('Failed to set default gateway: %d' % result.rc)

        time.sleep(2)  # wait for network to come back online


def is_online():
    result = s.cat('/sys/class/net/eth0/operstate').run()
    if result.rc != 0:
        raise Exception('Failed to get network status: %s' % result.stderr)
    return result.stdout[0] == 'up'


time.sleep(3)  # wait for nginx to start
print "Running in context: %s" % RUN_CONTEXT
print "Can disable network: %s" % can_disable_network()


class CacheTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        disable_network()
        enable_network()
        clear_cache()

    @classmethod
    def tearDownClass(self):
        clear_cache()

    def tearDown(self):
        enable_network()

    def case_fetch_uncached_resource(self, url, headers=None):
        r = fetch(url, headers)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.headers['Funes-Cache-Status'], 'MISS')

        r = fetch(url, headers)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.headers['Funes-Cache-Status'], 'MISS')

    def case_fetch_resource(self, url, headers=None, eta=None):
        r = fetch(url, headers)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.headers['Funes-Cache-Status'], 'MISS')

        r = fetch(url, headers)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.headers['Funes-Cache-Status'], 'HIT')

        cached_time = r.headers['Date']

        if can_disable_network():
            disable_network()

            r = fetch(url, headers)
            self.assertEqual(r.status_code, 200)
            self.assertEqual(r.headers['Funes-Cache-Status'], 'HIT')

        if eta is not None:
            time.sleep(eta + 1)  # add 1s buffer

            if can_disable_network():
                r = fetch(url, headers)
                self.assertEqual(r.status_code, 200)
                self.assertEqual(r.headers['Funes-Cache-Status'], 'STALE')

                cached_time = r.headers['Date']

                enable_network()

            r = fetch(url, headers)
            self.assertEqual(r.status_code, 200)
            self.assertNotEqual(cached_time, r.headers['Date'])
            self.assertEqual(r.headers['Funes-Cache-Status'], 'EXPIRED')

    def test_get_http_image(self):
        self.case_fetch_resource(HTTP_IMAGE_URL)

    def test_get_https_image(self):
        self.case_fetch_resource(HTTPS_IMAGE_URL)

    def test_get_video(self):
        self.case_fetch_resource(HTTPS_VIDEO_URL, headers={'bytes': '0-65535'})

    def test_get_rss(self):
        self.case_fetch_resource(RSS_URL, eta=5)

    def test_get_hls(self):
        self.case_fetch_uncached_resource(HLS_STREAM_URL)

    def test_get_expired_ssl(self):
        r = fetch(EXPIRED_SSL_URL)
        self.assertEqual(r.status_code, 502)
