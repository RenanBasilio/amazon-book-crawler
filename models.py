import psycopg2

import settings

conn = psycopg2.connect(database=settings.database, host=settings.host, user=settings.user)
cur = conn.cursor()

class Produto(object):
    def __init__(self, title, url, isbn, autor, crawl_time):
        super(Produto, self).__init__()
        self.title = title
        self.url = url
        self.isbn = isbn
        self.autor = autor
        self.crawl_time = crawl_time

    def save(self):
        cur.execute("INSERT INTO products_temp (title, product_url, isbn, authors) VALUES (%s, %s, %s, %s) RETURNING id", (
            self.title,
            self.url,
            self.isbn,
            self.autor,
        ))
        conn.commit()
        return cur.fetchone()[0]

        print(self.title)

class Preco(object):
    def __init__(self, url, value, position):
        super(Preco, self).__init__()
        self.url = url
        self.value = value
        self.position = position

    def save(self):
        cur.execute("INSERT INTO prices_temp (url, value, position) VALUES (%s, %s, %s) RETURNING id", (
            self.url,
            self.value,
            1,
            # self.position,
        ))
        conn.commit()
        return cur.fetchone()[0]

        print(self.title)

class Lista():
    def load():
        cur = conn.cursor()
        cur.execute("SELECT * FROM listagem")
        products = []
        for row in cur:
            products.append(row)
        return products

class Link(object):
    def __init__(self, url, isbn):
        super(Link, self).__init__()
        self.url = url
        self.isbn = isbn

    def save(self):
        cur.execute("INSERT INTO list_us_temp (url, isbn) VALUES (%s, %s) RETURNING 1", (
            self.url,
            self.isbn,
        ))
        conn.commit()
        return cur.fetchone()[0]

        print(self.title)


if __name__ == '__main__':

    # setup tables
    cur.execute("DROP TABLE IF EXISTS products_temp")
    cur.execute("""CREATE TABLE products_temp (
        id          serial PRIMARY KEY,
        title       varchar(2056),
        product_url         varchar(2056),
        isbn varchar(2056),
        authors       varchar(128)
    );""")
    conn.commit()

    print ("Hello, World!")
