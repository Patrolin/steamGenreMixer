package main
import "core:encoding/json"
import "core:fmt"
import "core:strings"
import win "core:sys/windows"

API_GET_ALL_APPS :: "https://api.steampowered.com/ISteamApps/GetAppList/v2/"
API_GET_APP_INFO :: "https://store.steampowered.com/app/%v/"

main :: proc() {
	when ODIN_OS == .Windows {
		win.SetConsoleOutputCP(win.CODEPAGE(win.CP_UTF8))
	}
	//app_list_data := fetch_json(API_GET_ALL_APPS, .Object)
	//app_list := get_json(app_list_data, .Array, "applist", "apps").(json.Array)
	raw_app_list, _ := json.parse(
		transmute([]u8)string("[{\"appid\": 1835850, name: \"Name\"}]"),
		json.DEFAULT_SPECIFICATION,
		true,
	)
	fmt.print("raw_app_list: ")
	pretty_print_json(raw_app_list)
	app_list := raw_app_list.(json.Array)
	fmt.printfln("len(app_list): %v", len(app_list))
	pretty_print_json(app_list[0])
	for app in app_list {
		app_id := get_json(app, .Integer, "appid").(json.Integer)
		do_fetch :: proc(app_id: json.Integer) -> string {
			// NOTE: this fails due to not odin-http not handling redirects
			return fetch_body(
				API_GET_APP_INFO,
				{
					"User-Agent",
					"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36",
					"Accept",
					"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
					"Accept-Encoding",
					"gzip, deflate, br",
					"Connection",
					"keep-alive",
					"Upgrade-Insecure-Requests",
					"1",
					"Cookie",
					"wants_mature_content=1",
				},
				app_id,
			)
		}
		app_html := do_fetch(app_id)
		fmt.println("-- BODY_START --")
		fmt.println(app_html)
		fmt.println("-- BODY_END --")
		/*app_html = do_fetch(app_id)
		fmt.println("-- BODY_START --")
		fmt.println(app_html)
		fmt.println("-- BODY_END --")*/
		app_name := get_app_name(app_html)
		app_tags := get_app_tags(app_html)
		fmt.printfln("app_id: %v", app_id)
		fmt.printfln("app_name: %v", app_name)
		fmt.printfln("app_tags: %v", app_tags)
		break
	}
}
get_app_name :: proc(app_html: string) -> string {
	return ""
}
get_app_tags :: proc(app_html: string) -> (tags: [dynamic]string) {
	index_after :: proc(str: string, i: int, substr: string) -> (next_i: int, ok: bool) {
		k := strings.index(str[i:], substr)
		return i + k + len(substr), k != -1
	}
	i, ok := 0, true
	for i < len(app_html) {
		i, ok = index_after(app_html, i, "\"app_tag\"")
		if !ok {return}
		i, ok = index_after(app_html, i, ">")
		if !ok {return}
		j := i + strings.index(app_html[i:], "</a>")
		fmt.assertf(j != -1, "Malformed HTML (unclosed anchor tag)")
		append(&tags, app_html[i:j])
	}
	return
}
