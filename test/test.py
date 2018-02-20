import requests
import sultan
import os
import unittest
import time

from sultan.api import Sultan
s = Sultan()

PROXY_PATH = os.environ.get('PROXY_PATH', '127.0.0.1:3128')

if not PROXY_PATH:
    raise Exception('Expected PROXY_PATH environment variable to be set.')

proxies = {
    'http': 'http://' + PROXY_PATH,
    'https': 'https://' + PROXY_PATH,
}

HTTP_IMAGE_URL = 'http://www.titaniumteddybear.net/wp-content/uploads/2011/04/wow-its-fucking-nothing.jpg'
HTTPS_IMAGE_URL = 'https://i.imgur.com/3YBkyf6.jpg'


def fetch(url):
    return requests.get(url, proxies=proxies, verify=False)

def clear_cache():
    result = s.rm('-rf /data/funes_rmb_cache/*').run()
    if result.rc != 0:
        raise Exception('Failed to clear cache: %s' % result.stderr)


clear_cache()
time.sleep(2)  # wait for nginx to start


class CacheTests(unittest.TestCase):

    def test_get_https_image(self):
        r = fetch(HTTPS_IMAGE_URL)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.headers['Funes-Cache-Status'], 'MISS')

        r = fetch(HTTPS_IMAGE_URL)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.headers['Funes-Cache-Status'], 'HIT')

    def test_get_http_image(self):
        r = fetch(HTTP_IMAGE_URL)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.headers['Funes-Cache-Status'], 'MISS')

        r = fetch(HTTP_IMAGE_URL)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.headers['Funes-Cache-Status'], 'HIT')
