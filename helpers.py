import os
import random
import re

from datetime import datetime

from urllib.parse import urlparse

import eventlet
requests = eventlet.import_patched('requests.__init__')
time = eventlet.import_patched('time')

from bs4 import BeautifulSoup
from requests.exceptions import RequestException
from selenium import webdriver

import settings

num_requests = 0
options = webdriver.ChromeOptions()
#options.add_argument('--headless')
driver = webdriver.Chrome(chrome_options=options)


def make_request(url, return_soup=True):
    # global request building and response handling

    if "picassoRedirect" in url:
        return None  # skip the redirect URLs

    global num_requests
    if num_requests >= settings.max_requests:
        raise Exception("Reached the max number of requests: {}".format(settings.max_requests))

    try:
        driver.get(url)
        html = driver.page_source
    except RequestException as e:
        log("WARNING: Request for {} failed, trying again.".format(url))
        return make_request(url)  # try request again, recursively

    num_requests += 1

    if return_soup:
        return BeautifulSoup(html, features="html.parser")
    return html

def clean_url(url):
    return re.sub('\/ref.+', '', url)

def format_url(url, base=None):
    # make sure URLs aren't relative, and strip unnecssary query args
    u = urlparse(url)
    b = urlparse(base)

    scheme = u.scheme or b.scheme or "https"
    host = u.netloc or b.netloc or "www.amazon.com.br"
    path = u.path or b.path

    if not u.query:
        query = ""
    else:
        query = "?"
        for piece in u.query.split("&"):
            k, v = piece.split("=")
            if k in settings.allowed_params:
                query += "{k}={v}&".format(**locals())
        query = query[:-1]

    return clean_url("{scheme}://{host}{path}{query}".format(**locals()))

def log(msg):
    # global logging function
    if settings.log_stdout:
        try:
            print("{}: {}".format(datetime.now(), msg))
        except UnicodeEncodeError:
            pass  # squash logging errors in case of non-ascii text

def shutdown():
    driver.close()

def build_search_url(base, isbn):
    return "{}/s?i=stripbooks&rh=p_66%3A{}&s=relevanceexprank&Adv-Srch-Books-Submit.x=16&Adv-Srch-Books-Submit.y=15&unfiltered=1&ref=sr_adv_b".format(base, isbn)

if __name__ == '__main__':
    # test proxy server IP masking
    r = make_request('https://api.ipify.org?format=json', return_soup=False)
    print(r.text)