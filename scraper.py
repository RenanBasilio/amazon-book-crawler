import sys
import io
import os
from datetime import datetime

import settings
from models import Produto, Preco
from helpers import make_request, log, build_search_url, format_url, download_image
from extractors import get_title, get_url, get_isbn, get_author, get_price, get_primary_img, get_top_search_result

def scrape_listings(page):
    listings = page.find_all("li", {"class":"zg-item-immersion"})

    if listings:
        for listing in listings:
            product = Produto(
                title = get_title(listing),
                url=format_url(get_url(listing)),
                isbn=get_isbn(listing),
                autor=get_author(listing),
                crawl_time=datetime.now()
            )
            productid = product.save()

            if not os.path.isfile(os.path.join(settings.image_dir, product.isbn+".jpg")):
                download_image(get_primary_img(listing), product.isbn+".jpg")

        print("Found {} listings.".format(len(listings)))

def scrape_price(url):
    page = make_request(format_url(url))
    preco = Preco(
        url = url,
        value = get_price(page),
        position = 1
    )
    precoid = preco.save()
