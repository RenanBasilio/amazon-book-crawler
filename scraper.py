import sys
import io
from datetime import datetime

from models import Produto
from helpers import make_request, log, build_search_url, format_url
from extractors import get_url, get_top_search_result, get_price

def run_test():
    test_product = Produto(
        "Practical Web Scraping for Data Science: Best Practices and Examples with Python",
        "https://www.amazon.com.br/Practical-Web-Scraping-Data-Science/dp/1484235819",
        "1484235819",
        "Seppe vanden Broucke",
        datetime.now()
    )

    urls = [test_product.url]
    urls.extend(find_foreign(test_product.isbn))

    log("Found the following urls for the product: {}".format(urls))

    for url in urls:
        price = scrape_price(url)
        if price:
            log("Found price for product at {}: {}".format(url, price))



def find_foreign(isbn):
    url = build_search_url("https://www.amazon.com", isbn)
    page = make_request(url)
    search_result = get_top_search_result(page)
    if (search_result):
        return [format_url(get_url(search_result), "https://www.amazon.com")]
    else: 
        return []

def scrape_price(url):
    page = make_request(format_url(url))
    return get_price(page)