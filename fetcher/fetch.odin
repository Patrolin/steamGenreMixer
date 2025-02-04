package main
import http "../odin-http"
import "../odin-http/client"
import "core:encoding/json"
import "core:fmt"
import "core:reflect"
import "core:strings"

// fetch and parse json
_parse_json :: proc(bytes: []u8) -> json.Value {
	value, json_err := json.parse(bytes, json.DEFAULT_SPECIFICATION, true)
	fmt.assertf(json_err == .None, "Couldn't parse JSON: %s", json_err)
	return value
}
construct_url :: proc(base_url: string, args: ..any) -> (sb: strings.Builder, url: string) {
	sb = strings.builder_make_len(len(base_url))
	fmt.sbprintf(&sb, base_url, ..args)
	url = strings.to_string(sb)
	fmt.printfln("fetch: %v", url)
	return
}
fetch_body :: proc(base_url: string, headers: []string, args: ..any) -> (body: string) {
	sb, url := construct_url(base_url, ..args)
	defer strings.builder_destroy(&sb)
	req: client.Request
	client.request_init(&req, .Get)
	defer client.request_destroy(&req)
	for i := 0; i < len(headers); i += 2 {
		http.headers_set(&req.headers, headers[i], headers[i + 1])
	}
	fmt.printfln("headers: %v", req.headers._kv)
	res, err := client.request(&req, url)
	defer client.response_destroy(&res)
	fmt.assertf(err == nil, "Request failed: %s", err)
	raw_body, allocation, body_err := client.response_body(&res)
	fmt.printfln("res.headers: %v", res.headers)
	fmt.assertf(body_err == nil, "Body error: %s", body_err)
	defer client.body_destroy(raw_body, allocation)
	body = strings.clone(raw_body.(client.Body_Plain))
	return
}
fetch_json :: proc(base_url: string, type: JsonType, args: ..any) -> json.Value {
	sb, url := construct_url(base_url, ..args)
	defer strings.builder_destroy(&sb)
	res, err := client.get(url)
	defer client.response_destroy(&res)
	fmt.assertf(err == nil, "Request failed: %s", err)
	raw_body, allocation, body_err := client.response_body(&res)
	fmt.assertf(body_err == nil, "Body error: %s", body_err)
	defer client.body_destroy(raw_body, allocation)
	value := _parse_json(transmute([]u8)raw_body.(client.Body_Plain))
	assert_json_type(value, type)
	return value
}
