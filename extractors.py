from html.parser import HTMLParser
import re

htmlparser = HTMLParser()


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


def get_primary_img(item):
    thumb = item.find("img", "s-access-image")
    if thumb:
        src = thumb["src"]

        p1 = src.split("/")
        p2 = p1[-1].split(".")

        base = p2[0]
        ext = p2[-1]

        return "/".join(p1[:-1]) + "/" + base + "." + ext

    return None