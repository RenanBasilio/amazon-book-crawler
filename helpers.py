import os
import random
import queue

from datetime import datetime
urlqueue = queue.Queue()

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
options.add_argument('--headless')
driver = webdriver.Chrome(chrome_options=options)


def make_request(url, return_soup=True):
    # global request building and response handling

    url = format_url(url)

    if "picassoRedirect" in url:
        return None  # skip the redirect URLs

    global num_requests
    if num_requests >= settings.max_requests:
        raise Exception("Reached the max number of requests: {}".format(settings.max_requests))

    proxies = get_proxy()
    try:
        driver.get(url)
        html = driver.page_source
    except RequestException as e:
        log("WARNING: Request for {} failed, trying again.".format(url))
        return make_request(url)  # try request again, recursively

    num_requests += 1

    if return_soup:
        return BeautifulSoup(html, features="html.parser"), html
    return html


def format_url(url):
    # make sure URLs aren't relative, and strip unnecssary query args
    u = urlparse(url)

    scheme = u.scheme or "https"
    host = u.netloc or "www.amazon.com.br"
    path = u.path

    if not u.query:
        query = ""
    else:
        query = "?"
        for piece in u.query.split("&"):
            k, v = piece.split("=")
            if k in settings.allowed_params:
                query += "{k}={v}&".format(**locals())
        query = query[:-1]

    return "{scheme}://{host}{path}{query}".format(**locals())


def log(msg):
    # global logging function
    if settings.log_stdout:
        try:
            print("{}: {}".format(datetime.now(), msg))
        except UnicodeEncodeError:
            pass  # squash logging errors in case of non-ascii text


def get_proxy():
    # choose a proxy server to use for this request, if we need one
    if not settings.proxies or len(settings.proxies) == 0:
        return None

    proxy_ip = random.choice(settings.proxies)
    proxy_url = "socks5://{user}:{passwd}@{ip}:{port}/".format(
        user=settings.proxy_user,
        passwd=settings.proxy_pass,
        ip=proxy_ip,
        port=settings.proxy_port,

    )
    return {
        "http": proxy_url,
        "https": proxy_url
    }


def enqueue_url(u):
    url = format_url(u)
    return urlqueue.put(url)


def dequeue_url():
    return urlqueue.get()


if __name__ == '__main__':
    # test proxy server IP masking
    r = make_request('https://api.ipify.org?format=json', return_soup=False)
    print(r.text)