// Verify that expanded derive output is valid MoonBit code.
// These tests run the expander and then check the output for correctness.

test "verify_derive_struct_to_json" {
  let source = "#[macro_derive(ToJson)]\nstruct Point {\n  x: Int\n  y: Int\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Point") is None { abort("struct Point should be present, got: " + result) }
  if result.find("fn Point::to_json") is None { abort("expected Point::to_json") }
  if result.find("self.x.to_json()") is None { abort("expected self.x.to_json()") }
  if result.find("self.y.to_json()") is None { abort("expected self.y.to_json()") }
  if result.find("fn Point::to_string") is Some(_) { abort("should not contain to_string") }
  if result.find("#[") is Some(_) { abort("should not contain any #[") }
}

test "verify_derive_enum_to_json" {
  let source = "#[macro_derive(ToJson)]\nenum Color {\n  Red\n  Green(Int)\n  Blue(Int, String)\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("enum Color") is None { abort("enum Color should be present") }
  if result.find("fn Color::to_json") is None { abort("expected to_json") }
  if result.find("Red") is None { abort("expected Red variant") }
  if result.find("Green(a)") is None { abort("expected Green(a) pattern") }
  if result.find("Blue(a, b)") is None { abort("expected Blue(a, b) pattern") }
  if result.find("fn Color::to_string") is Some(_) { abort("should not contain to_string") }
}

test "verify_derive_generic_enum" {
  let source = "#[macro_derive(ToJson)]\nenum Option[T] {\n  Some(T)\n  None\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("enum Option[T]") is None { abort("expected Option[T]") }
  if result.find("fn Option::to_json") is None { abort("expected to_json, got: " + result) }
  if result.find("Some(a)") is None { abort("expected Some(a)") }
  if result.find("None => {") is None { abort("expected None arm") }
  if result.find("a.to_json()") is None { abort("expected a.to_json()") }
}

test "verify_derive_struct_generic" {
  let source = "#[macro_derive(ToJson)]\nstruct Pair[T] {\n  first: T\n  second: T\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Pair[T]") is None { abort("expected Pair[T]") }
  if result.find("fn Pair::to_json") is None { abort("expected to_json") }
  if result.find("self : Pair[T]") is None { abort("expected self : Pair[T]") }
  if result.find("self.first.to_json()") is None { abort("expected first.to_json()") }
}

test "verify_expand_greet_macro" {
  let source = "macro_rules! greet { ($name:expr) => { fn greet_$name() -> String { \"Hello, $name!\" } } }\ngreet!(World)"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_file(source, defs)
  if result.find("fn greet_World") is None { abort("expected greet_World") }
  if result.find("Hello, World!") is None { abort("expected Hello, World!") }
  // macro definition should be preserved
  if result.find("macro_rules!") is None { abort("macro definition should be preserved") }
}

test "verify_expand_nested_macro" {
  let source = "macro_rules! double { ($x:expr) => { $x * 2 } }\nmacro_rules! apply { ($f:expr) => { double!($f) } }\nlet result = apply!(21)"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_file(source, defs)
  if result.find("21 * 2") is None { abort("expected 21 * 2, got: " + result) }
  if result.find("double!") is Some(_) { abort("double! should be fully expanded") }
}

test "verify_builtin_vec" {
  let source = "let nums = vec![1, 2, 3]"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("[1, 2, 3]") is None { abort("expected [1, 2, 3], got: " + result) }
}

test "verify_builtin_stringify" {
  let source = "let s = stringify!(hello world)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("\"hello world\"") is None { abort("expected quoted string, got: " + result) }
}

test "verify_builtin_assert" {
  let source = "assert!(x > 0)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("abort") is None { abort("expected abort in assert output, got: " + result) }
  if result.find("x > 0") is None { abort("expected condition preserved") }
}

test "verify_stacked_derive" {
  let source = "#[macro_derive(ToJson)]\n#[macro_derive(ToJson)]\nstruct Point { x: Int, y: Int }"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("fn Point::to_json") is None { abort("expected to_json") }
  if result.find("#[macro_derive") is Some(_) { abort("should not contain #[macro_derive, got: " + result) }
}

test "verify_preserves_non_macro_code" {
  let source = "fn main {\n  println(\"hello\")\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result != source { abort("non-macro source should be unchanged, got: " + result) }
}
