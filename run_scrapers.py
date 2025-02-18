from scrape_steam_apps import scrape_steam_apps

functions = [
  scrape_steam_apps
]
if __name__ == '__main__':
  for function in functions:
    function()
