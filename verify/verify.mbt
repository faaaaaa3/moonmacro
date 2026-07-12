// Verify that expanded derive output is valid MoonBit code.
// These tests run the expander and then check the output for correctness.

test "verify_derive_constructor" {
  let source = "#[macro_derive(Constructor)]\nstruct Point {\n  x: Int\n  y: Int\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Point") is None { abort("struct Point should be present, got: " + result) }
  if result.find("pub fn Point::new") is None { abort("expected Point::new") }
  if result.find("x: Int, y: Int") is None { abort("expected params") }
  if result.find("{ x, y }") is None { abort("expected struct literal") }
  if result.find("#[") is Some(_) { abort("should not contain any #[") }
}

test "verify_derive_constructor_generic" {
  let source = "#[macro_derive(Constructor)]\nstruct Pair[T] {\n  first: T\n  second: T\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Pair[T]") is None { abort("expected Pair[T]") }
  if result.find("pub fn Pair::new[T]") is None { abort("expected Pair::new[T]") }
  if result.find("first: T, second: T") is None { abort("expected params") }
  if result.find("-> Pair[T]") is None { abort("expected Pair[T] return") }
}

test "verify_derive_getters" {
  let source = "#[macro_derive(Getters)]\nstruct Point {\n  x: Int\n  y: String\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Point") is None { abort("struct Point should be present") }
  if result.find("pub fn Point::X") is None { abort("expected getter X, got: " + result) }
  if result.find("pub fn Point::Y") is None { abort("expected getter Y") }
  if result.find("self: Point") is None { abort("expected self param") }
  if result.find("-> Int") is None { abort("expected Int return type") }
  if result.find("-> String") is None { abort("expected String return type") }
}

test "verify_derive_enum_from_str" {
  let source = "#[macro_derive(EnumFromStr)]\nenum Color {\n  Red\n  Green\n  Blue\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("enum Color") is None { abort("enum Color should be present") }
  if result.find("pub fn Color::from_string") is None { abort("expected from_string") }
  if result.find("\"Red\" => Some(Red)") is None { abort("expected Red match") }
  if result.find("\"Green\" => Some(Green)") is None { abort("expected Green match") }
  if result.find("\"Blue\" => Some(Blue)") is None { abort("expected Blue match") }
  if result.find("_ => None") is None { abort("expected fallback") }
}

test "verify_expand_greet_macro" {
  let source = "macro_rules! greet { ($name:expr) => { fn greet_$name() -> String { \"Hello, $name!\" } } }\ngreet!(World)"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_file(source, defs)
  if result.find("fn greet_World") is None { abort("expected greet_World") }
  if result.find("Hello, World!") is None { abort("expected Hello, World!") }
  if result.find("macro_rules!") is None { abort("macro definition should be preserved") }
}

test "verify_expand_nested_macro" {
  let source = "macro_rules! double { ($x:expr) => { $x * 2 } }\nmacro_rules! apply { ($f:expr) => { double!($f) } }\nlet result = apply!(21)"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_file(source, defs)
  if result.find("21 * 2") is None { abort("expected 21 * 2, got: " + result) }
  if result.find("double!") is Some(_) { abort("double! should be fully expanded") }
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

test "verify_builtin_matches" {
  let source = "let b = matches!(result, Ok(val))"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("match result") is None { abort("expected match, got: " + result) }
  if result.find("Ok(val) => true") is None { abort("expected Ok(val) => true") }
  if result.find("_ => false") is None { abort("expected fallthrough false") }
}

test "verify_builtin_todo" {
  let source = "todo!()"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("abort(\"not implemented\")") is None { abort("expected abort, got: " + result) }
}

test "verify_builtin_todo_with_message" {
  let source = "todo!(\"fix this\")"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("abort(\"fix this\")") is None { abort("expected abort with message") }
}

test "verify_stacked_derive" {
  let source = "#[macro_derive(Constructor)]\n#[macro_derive(Getters)]\nstruct Point { x: Int, y: Int }"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Point::new") is None { abort("expected new") }
  if result.find("pub fn Point::X") is None { abort("expected getter X") }
  if result.find("pub fn Point::Y") is None { abort("expected getter Y") }
  if result.find("#[macro_derive") is Some(_) { abort("should not contain #[macro_derive, got: " + result) }
}

test "verify_derive_constructor_kind_error" {
  let source = "#[macro_derive(Constructor)]\nenum Color {\n  Red\n  Green\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("only supports structs") is None { abort("expected error message") }
}

test "verify_derive_enum_from_str_data_variants" {
  let source = "#[macro_derive(EnumFromStr)]\nenum Expr {\n  Int(Int)\n  Add(Expr, Expr)\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("requires at least one unit variant") is None { abort("expected error for no unit variants") }
}

test "verify_preserves_non_macro_code" {
  let source = "fn main {\n  println(\"hello\")\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result != source { abort("non-macro source should be unchanged, got: " + result) }
}

test "verify_derive_constructor_single_field" {
  let source = "#[macro_derive(Constructor)]\nstruct Wrap {\n  value: String\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Wrap") is None { abort("struct Wrap should be present") }
  if result.find("pub fn Wrap::new") is None { abort("expected Wrap::new") }
  if result.find("value: String") is None { abort("expected value param") }
}

test "verify_derive_constructor_mut_field" {
  let source = "#[macro_derive(Constructor)]\nstruct Point {\n  mut x: Int\n  y: String\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Point::new") is None { abort("expected Point::new") }
  if result.find("x: Int, y: String") is None { abort("expected params") }
}

test "verify_derive_constructor_empty" {
  let source = "#[macro_derive(Constructor)]\nstruct Empty {}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Empty") is None { abort("struct should be preserved") }
}

test "verify_derive_getters_generic" {
  let source = "#[macro_derive(Getters)]\nstruct Wrap[T] {\n  value: T\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Wrap[T]") is None { abort("struct should be present") }
  if result.find("pub fn Wrap::Value") is None { abort("expected getter Value") }
  if result.find("self: Wrap[T]") is None { abort("expected self: Wrap[T]") }
  if result.find("-> T") is None { abort("expected T return type") }
}

test "verify_derive_getters_single_field" {
  let source = "#[macro_derive(Getters)]\nstruct Wrap { value: String }"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Wrap::Value") is None { abort("expected getter Value") }
  if result.find("self: Wrap") is None { abort("expected self param") }
}

test "verify_derive_enum_from_str_mixed" {
  let source = "#[macro_derive(EnumFromStr)]\nenum Expr {\n  Int(Int)\n  Add(Expr, Expr)\n  Zero\n  One\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Expr::from_string") is None { abort("expected from_string") }
  if result.find("\"Zero\" => Some(Zero)") is None { abort("expected Zero") }
  if result.find("\"One\" => Some(One)") is None { abort("expected One") }
  if result.find("\"Int\"") is Some(_) { abort("should not match data variant Int") }
  if result.find("_ => None") is None { abort("expected fallback") }
}

test "verify_builtin_matches_complex" {
  let source = "let b = matches!(x, Some(y))"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("match x") is None { abort("expected match x") }
  if result.find("Some(y) => true") is None { abort("expected Some(y) => true") }
}

test "verify_builtin_assert_complex" {
  let source = "assert!(x > 0 && y < 10)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("if !(x > 0 && y < 10)") is None { abort("expected condition preserved") }
  if result.find("assertion failed: x > 0 && y < 10") is None { abort("expected message preserved") }
}

test "verify_builtin_dbg" {
  let source = "let x = 42\nlet y = dbg!(x + 1)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("let __dbg_val = x + 1") is None { abort("expected var binding, got: " + result) }
  // stringify! is expanded in a later pass, so check for its result
  if result.find("\"x + 1\"") is None { abort("expected quoted expr text, got: " + result) }
  if result.find("__dbg_val.to_string()") is None { abort("expected to_string") }
}

test "verify_builtin_dbg_nested_parens" {
  let source = "let y = dbg!(foo(1, 2))"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("let __dbg_val = foo(1, 2)") is None { abort("expected nested parens, got: " + result) }
  if result.find("\"foo(1, 2)\"") is None { abort("expected quoted expr text") }
}
