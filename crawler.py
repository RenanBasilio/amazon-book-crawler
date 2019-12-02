import sys
import os
import re
from datetime import datetime
from math import inf

import settings
from models import Produto, Lista
from helpers import make_request, log, format_url, build_search_url, shutdown
from scraper import scrape_listings, scrape_product
from extractors import get_top_search_result, get_url

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
            scrape_listings(page)
            # Em cada subpagina, busca todos os produtos
            for subpage in subpages:
                scrape_listings(make_request(subpage["href"]))

    else:
        # Essa e uma categoria intermediaria, entao busca todas as subcategorias recursivamente
        depth += 1
        for subcategory in subcategories.find_all("a"):
            pages.extend(crawl_subcategories(subcategory["href"], recursive, max_depth, depth))

    return pages

def find_foreign(isbn):
    url = build_search_url("https://www.amazon.com", isbn)
    page = make_request(url)
    search_result = get_top_search_result(page)
    if search_result:
        return [format_url(get_url(search_result), "https://www.amazon.com")]
    else:
        return []

def run_test():
    products = Lista.load()
    # test_product = Produto(
    #     "Practical Web Scraping for Data Science: Best Practices and Examples with Python",
    #     "https://www.amazon.com.br/Practical-Web-Scraping-Data-Science/dp/1484235819",
    #     "1484235819",
    #     "Seppe vanden Broucke",
    #     datetime.now()
    # )


    for test_product in products:
        urls = [test_product[1]]
        urls.extend(find_foreign(test_product[0]))
        log("Found the following urls for the product: {}".format(urls))

        for url in urls:
            price = scrape_product(url)
            if price:
                log("Found price for product at {}: {}".format(url, price))


if __name__ == '__main__':

    if len(sys.argv) > 1:
        if sys.argv[1] == "start":
            log("Seeding the URL frontier with subcategory URLs")
            begin_crawl()

        elif sys.argv[1] == "update" and len(sys.argv) > 2 and sys.argv[2]:
                log("Retrieving specified product IDs from database...")
                for productId in sys.argv[2:]:
                    exit() # scrape product page

        elif sys.argv[1] == "test":
            log("Running search and information extraction test...")
            run_test()
        else:
            log("No products supplied to update method.")

    else:
        log("Starting full database update...")

    log("Done")
    shutdown()
