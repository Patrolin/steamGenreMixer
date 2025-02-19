from io import TextIOWrapper
from time import sleep, time
from typing import Any, cast
from datetime import date
import requests

def get_today_iso():
  return date.today().isoformat()

HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
  'Accept-Encoding': 'gzip, deflate, br',
  'Connection': 'keep-alive',
  'Upgrade-Insecure-Requests': '1',
  'Cookie': 'wants_mature_content=1', # skip mature warning dialog
}
def assertf(ok: bool, fmt: str, *args: list[Any]):
  if not ok:
    raise Exception(fmt.format(*args))
def strings_index(string: str, substr: str) -> int:
  try:
    return string.index(substr)
  except ValueError:
    return -1
def get_app_tags(app_html: str) -> list[str]:
  tags: list[str] = []
  def index_after(string: str, index: int, substr: str):
    k = strings_index(string[index:], substr)
    return index + k + len(substr), k != -1
  (i, ok) = 0, True
  while i < len(app_html):
    (i, ok) = index_after(app_html, i, "\"app_tag\"")
    if not ok: return tags
    (i, ok) = index_after(app_html, i, ">")
    if not ok: return tags
    j = i + strings_index(app_html[i:], "</a>")
    assertf(ok, "Malformed HTML (unclosed anchor tag)")
    tags.append(app_html[i:j].strip())
  return tags

def strings_escape(string: str):
  return string.replace("\"", "\\\"")
def get_first_n_csv_values_on_line(csv: str, n: int) -> list[str]:
  acc = []
  i = 0
  while len(acc) < n:
    offset = strings_index(csv[i:], ",")
    j = i if offset == -1 else i + offset
    acc.append(csv[i:j])
    i = j+1
  return acc
class CsvDatabase:
  file_name: str
  file: TextIOWrapper
  known_ids: dict[int, str]
  def __init__(self, file_name: str):
    self.file_name = file_name
    self.file = cast(TextIOWrapper, None)
    self.known_ids = dict()
  def __enter__(self):
    try:
      with open(self.file_name, "r", encoding="utf8") as f:
        for line in f:
          iso_date, app_id = get_first_n_csv_values_on_line(line, 2)
          if app_id != "":
            self.known_ids[int(app_id)] = iso_date
    except FileNotFoundError:
      pass
    self.file = cast(TextIOWrapper, open(self.file_name, "a+", encoding="utf8"))
    return self
  def __exit__(self, _exception_type, _exception_value, _exception_traceback):
    self.file.close()

SECONDS_BETWEEN_REQUESTS = 5.0
def formatTime(seconds: float) -> str:
  if seconds > 3600:
    hours = int(seconds / 3600)
    minutes = int((seconds - hours*3600) / 60)
    return f"{hours} h {minutes} min"
  elif seconds > 60:
    minutes = int(seconds / 60)
    seconds = int(seconds - minutes*60)
    return f"{minutes} min {seconds} s"
  else:
    return f"{seconds/1} s"

def scrape_steam_apps():
  try:
    all_apps = requests.get('https://api.steampowered.com/ISteamApps/GetAppList/v2/').json()['applist']['apps']
    all_apps_count = len(all_apps)

    with CsvDatabase("apps.csv") as db:
      starting_i = len(db.known_ids)
      i = starting_i
      start_time = time()
      def get_time_to_wait_until():
        return start_time + SECONDS_BETWEEN_REQUESTS * (i - starting_i)
      t = start_time
      prev_t = t
      for app in all_apps:
        prev_active_t = time()
        app_id = app['appid']
        if app_id in db.known_ids: continue
        app_name = app['name']
        today_iso = get_today_iso()
        response = requests.get(f"https://store.steampowered.com/app/{app_id}/", headers=HEADERS, allow_redirects=True)
        app_html = response.text
        app_tags = get_app_tags(app_html)
        db.file.write(f"{today_iso}, {app_id}, \"{strings_escape(app_name)}\", {', '.join(app_tags)}\n")
        i += 1
        if i % 10 == 0:
          db.file.flush()
        print(f"app_id: {app_id}")
        print(f"app_name: {app_name}")
        print(f"app_tags: {app_tags}")
        t = time()
        dt_full = t - prev_t
        prev_t = t
        dt_active = t - prev_active_t
        remaining_count = all_apps_count - i
        time_to_wait = max(0.0, get_time_to_wait_until() - t)
        print(f"  Progress: {i}/{all_apps_count}, ETA: {formatTime(remaining_count * SECONDS_BETWEEN_REQUESTS)}, (took {dt_active:.2} s, waiting {time_to_wait:.2} s)", flush=True)
        if time_to_wait > 0:
          sleep(time_to_wait)
  except KeyboardInterrupt:
    exit(1)

if __name__ == '__main__':
  scrape_steam_apps()

# TODO: scrape type of content:
#   .Soundtrack
#   .Game
#   .Dlc
#   .App
# TODO: scrape whether content is still available
# TODO: write a lookup compressor to make the final size smaller
# TODO: write a web gui to browse through the data
# TODO: add filters:
#   excludeUnavailableContent = true,
#   tagsExclude = ["Nudity", "Sexual Content", "Hentai", "NSFW"],
#   tagsInclude = [], // "Multiplayer"
#   tagsToExclude = ["Soundtrack", "Controller"],
#   firstNTags = 5,
#   firstNTagsInclude = [],
#   firstTag = null,
#   secondTag = null
#   ..
