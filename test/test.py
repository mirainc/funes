import requests
import os
import unittest

PROXY_PATH = os.environ.get('PROXY_PATH', '127.0.0.1:3128')

if not PROXY_PATH:
    raise Exception('Expected PROXY_PATH environment variable to be set.')

proxies = {
  'http': 'http://' + PROXY_PATH,
  'https': 'https://' + PROXY_PATH,
}

HTTP_IMAGE_URL = 'http://www.titaniumteddybear.net/wp-content/uploads/2011/04/wow-its-fucking-nothing.jpg'

def fetch(url):
    return requests.get(url, proxies=proxies)

class CacheTests(unittest.TestCase):
    def test_http_image(self):
        r = fetch(HTTP_IMAGE_URL)
        self.assertEqual(r.status_code, 200)


