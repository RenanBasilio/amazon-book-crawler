import os

current_dir = os.path.dirname(os.path.realpath(__file__))

# Database
database = "ambermu"
host = "localhost"
user = "postgres"

# Request
headers = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Encoding": "gzip, deflate, sdch, br",
    "Accept-Language": "en-US,en;q=0.8",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36",
}
allowed_params = ["node", "rh", "page"]

# Crawling Logic
start_file = os.path.join(current_dir, "start-urls.txt")
max_requests = 2 * 10**6  # two million
max_details_per_listing = 9999
max_category_depth=1

# Logging & Storage
log_stdout = True
image_dir = os.path.join(current_dir, "results", "images")
export_dir = os.path.join(current_dir, "results")
