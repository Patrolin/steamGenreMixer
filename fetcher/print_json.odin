package main
import "core:encoding/json"
import "core:fmt"

// print json
_print_spaces :: proc(depth: int) {
	for i := 0; i < depth; i += 1 {
		fmt.print("  ")
	}
}
pretty_print_json_tiny :: proc(value: json.Value, newline: bool = true) {
	need_comma := false
	switch v in value {
	case nil, json.Null, json.Boolean, json.Float:
		fmt.print(v)
	case json.Integer:
		fmt.printf("(int)%d", v)
	case json.String:
		fmt.printf("\"%v\"", v)
	case json.Array:
		fmt.print("[")
		i := 0
		for ; i < 3 && i < len(v); i += 1 {
			if need_comma {fmt.print(",")}
			pretty_print_json_tiny(v[i], false)
			need_comma = true
		}
		if i < len(v) {
			fmt.print("..")
		}
		fmt.print("]")
	case json.Object:
		fmt.print("{")
		for key, item in v {
			if need_comma {fmt.print(",")}
			pretty_print_json_tiny(key, false)
			fmt.print(":")
			pretty_print_json_tiny(item, false)
			need_comma = true
		}
		fmt.print("}")
	}
	if newline {fmt.println()}
}
pretty_print_json :: proc(value: json.Value, depth: int = 0) {
	switch v in value {
	case nil, json.Null, json.Boolean, json.Float:
		fmt.print(v)
	case json.Integer:
		fmt.printf("%i", v)
	case json.String:
		fmt.printf("\"%v\"", v)
	case json.Array:
		fmt.println("[")
		for item in v {
			_print_spaces(depth + 1)
			pretty_print_json(item, depth + 1)
			fmt.println(",")
		}
		_print_spaces(depth)
		fmt.print("]")
	case json.Object:
		fmt.println("{")
		for key, item in v {
			_print_spaces(depth + 1)
			pretty_print_json(key, depth + 1)
			fmt.print(": ")
			pretty_print_json(item, depth + 1)
			fmt.println(",")
		}
		_print_spaces(depth)
		fmt.print("}")
	}
	if depth == 0 {fmt.println()}
}
