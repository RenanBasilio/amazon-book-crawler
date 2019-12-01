import sys
from datetime import datetime
from math import inf

import re

import settings
from models import Produto
from helpers import make_request, log, format_url
from extractors import get_title, get_url, get_primary_img, get_isbn, get_author
from bs4 import BeautifulSoup

crawl_time = datetime.now()

def begin_crawl():

    # explode out all of our category `start_urls` into subcategories
    with open(settings.start_file, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue  # skip blank and commented out lines

            page = make_request(line)

            # look for subcategory links on this page
            subcategories = crawl_subcategories(line, max_depth=settings.max_category_depth)

            log("Found {} subcategories on {}".format(len(subcategories), line))

def crawl_subcategories(url, recursive=True, max_depth=inf, depth=0):

    page = make_request(url)

    category =  page.find("span", {"class":"zg_selected"})
    log("Crawling subcategory {}... (Depth {})".format(category.string, depth))

    subcategories = category.parent.find_next_sibling("ul")

    pages = []

    if not subcategories or not recursive or depth >= max_depth:
        # Essa e uma categoria folha, entao busca todas as paginas da categoria
        pages.append(url)
        pagination = page.find("ul", {"class":"a-pagination"})
        if pagination:
            subpages = pagination.find("li", {"class":"a-normal"}).find_all("a")
            parse_listings(page)
            # Em cada subpagina, busca todos os produtos
            for subpage in subpages:
                parse_listings(make_request(subpage["href"]))

    else:
        # Essa e uma categoria intermediaria, entao busca todas as subcategorias recursivamente
        depth += 1
        for subcategory in subcategories.find_all("a"):
            pages.extend(crawl_subcategories(subcategory["href"], recursive, max_depth, depth))

    return pages

def parse_listings(page):

    global crawl_time

    urls = []
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
            product.save()

            print("Found {} [ Title: {}, Author: {}, Isbn: {} ]".format(product.url, product.title, product.autor, product.isbn))

        print("Found {} listings.".format(len(listings)))

if __name__ == '__main__':

    if len(sys.argv) > 1 and sys.argv[1] == "start":
        log("Seeding the URL frontier with subcategory URLs")
        begin_crawl()  # put a bunch of subcategory URLs into the queue
