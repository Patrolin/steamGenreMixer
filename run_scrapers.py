from scrape_steam_apps import scrape_steam_apps

scrapers = [
  scrape_steam_apps
]
if __name__ == '__main__':
  for scraper in scrapers:
    scraper()
