from os import system as run_cmd
import traceback

# NOTE: `>` redirect also works on windows
COMMANDS = [
  "python scrape_steam_apps.py > scrape_steam_apps.log 2>&1"
]
if __name__ == '__main__':
  with open("run_scrapers.log", "w+", encoding="utf8") as f:
    try:
      for cmd in COMMANDS:
        exit_status = run_cmd(cmd)
        #exit_code = waitstatus_to_exitcode(exit_status)
        f.write(f"{exit_status}, {cmd}\n")
    except BaseException as err:
      err_string = "".join(traceback.format_exception(type(err), err, err.__traceback__))
      f.write(f"exception: {err_string}\n")
