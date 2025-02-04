package main
import "../odin-http/client"
import "core:encoding/json"
import "core:fmt"
import "core:strings"

// get json by key
JsonType :: enum {
	Null,
	Integer,
	Float,
	Boolean,
	String,
	Array,
	Object,
	IntegerOrNull,
	FloatOrNull,
	BooleanOrNull,
	StringOrNull,
	ArrayOrNull,
	ObjectOrNull,
	Any,
}
@(disabled = ODIN_DISABLE_ASSERT)
assert_json_type :: proc(value: json.Value, type: JsonType, loc := #caller_location) {
	if !is_json_type(value, type) {
		fmt.printf("expected: .%v, got: .%v: ", type, get_json_type(value))
		pretty_print_json_tiny(value) // TODO: sbprint this
		assert(false, "Wrong json type", loc = loc)
	}
}
is_json_type :: proc(value: json.Value, type: JsonType) -> (ok: bool) {
	switch type {
	case .Null:
	case .Integer, .IntegerOrNull:
		_, ok = value.(json.Integer)
	case .Float, .FloatOrNull:
		_, ok = value.(json.Float)
	case .Boolean, .BooleanOrNull:
		_, ok = value.(json.Boolean)
	case .String, .StringOrNull:
		_, ok = value.(json.String)
	case .Array, .ArrayOrNull:
		_, ok = value.(json.Array)
	case .Object, .ObjectOrNull:
		_, ok = value.(json.Object)
	case .Any:
		ok = true
	}
	_, is_null := value.(json.Null)
	ok ||= (type >= .IntegerOrNull) && is_null
	return ok
}
get_json_type :: proc(value: json.Value) -> JsonType {
	switch v in value {
	case nil, json.Null:
		return JsonType.Null
	case json.Integer:
		return JsonType.Integer
	case json.Float:
		return JsonType.Float
	case json.Boolean:
		return JsonType.Boolean
	case json.String:
		return JsonType.String
	case json.Array:
		return JsonType.Array
	case json.Object:
		return JsonType.Object
	}
	fmt.assertf(false, "Invalid value: %v", value)
	return JsonType.Any // make compiler happy
}
get_json :: proc(value: json.Value, type: JsonType, keys: ..string) -> json.Value {
	acc: json.Value = value
	for key in keys {
		object, ok := acc.(json.Object)
		if !ok {
			fmt.print("value is missing key: \"%v\", value: ", key)
			pretty_print_json_tiny(value)
			assert(false)
		}
		acc = object[key]
	}
	assert_json_type(acc, type)
	return acc
}
