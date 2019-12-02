import re

def get_title(item):
    title = item.find("div", {"class":"p13n-sc-truncated"})

    if title.has_attr("title"):
        title = title["title"]
    else:
        title = title.string

    if title:
        return title
    else:
        return "<missing product title>"


def get_url(item):
    link = item.find("a", {"class":"a-link-normal"})
    if link:
        return link["href"]
    else:
        return "<missing product url>"


def get_isbn(item):
    isbn = re.search("(?<=\/dp\/)[^\/]+", item.find("a", {"class":"a-link-normal"})["href"])
    if isbn:
        return isbn.group()
    else:
        return None

def get_author(item):
    author = item.find("a", {"class":"a-link-normal"}).find_next_sibling().find("span").string
    if author:
        return author
    else:
        return "<missing author>"

def get_price(item):
    try:
        price = item.find("span", {"class":"offer-price"}).string
        return price
    except:
        return 0

def get_top_search_result(item):
    try:
        results = item.find("div", {"class":"s-search-results"})
        return item.find_all("div", {"class":"s-result-item"})[0]
    except:
        return 0

def get_primary_img(item):
    thumb = item.find("img")
    if thumb:
        return thumb["src"]
    else:
        return None
