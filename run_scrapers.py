import traceback
from scrape_steam_apps import scrape_steam_apps

functions = [
  scrape_steam_apps
]
if __name__ == '__main__':
  with open("run_scrapers.log", "w+", encoding="utf8") as f:
    try:
      for function in functions:
        function()
    except BaseException as err:
      err_string = "".join(traceback.format_exception(type(err), err, err.__traceback__))
      f.write(f"exception: {err_string}\n")
