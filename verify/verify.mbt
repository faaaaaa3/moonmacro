// Verify that expanded derive output is valid MoonBit code.
// These tests run the expander and then check the output for correctness.

test "verify_derive_constructor" {
  let source = "#[macro_derive(Constructor)]\nstruct Point {\n  x: Int\n  y: Int\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Point") is None { fail("struct Point should be present, got: " + result) }
  if result.find("pub fn Point::new") is None { fail("expected Point::new") }
  if result.find("x: Int, y: Int") is None { fail("expected params") }
  if result.find("{ x, y }") is None { fail("expected struct literal") }
  if result.find("#[") is Some(_) { fail("should not contain any #[") }
}

test "verify_derive_constructor_generic" {
  let source = "#[macro_derive(Constructor)]\nstruct Pair[T] {\n  first: T\n  second: T\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Pair[T]") is None { fail("expected Pair[T]") }
  if result.find("pub fn[T] Pair::new") is None { fail("expected Pair::new[T]") }
  if result.find("first: T, second: T") is None { fail("expected params") }
  if result.find("-> Pair[T]") is None { fail("expected Pair[T] return") }
}

test "verify_derive_getters" {
  let source = "#[macro_derive(Getters)]\nstruct Point {\n  x: Int\n  y: String\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Point") is None { fail("struct Point should be present") }
  if result.find("pub fn Point::x") is None { fail("expected getter x, got: " + result) }
  if result.find("pub fn Point::y") is None { fail("expected getter y") }
  if result.find("self: Point") is None { fail("expected self param") }
  if result.find("-> Int") is None { fail("expected Int return type") }
  if result.find("-> String") is None { fail("expected String return type") }
}

test "verify_derive_enum_from_str" {
  let source = "#[macro_derive(EnumFromStr)]\nenum Color {\n  Red\n  Green\n  Blue\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("enum Color") is None { fail("enum Color should be present") }
  if result.find("pub fn Color::from_string") is None { fail("expected from_string") }
  if result.find("\"Red\" => Some(Color::Red)") is None { fail("expected Red match, got: " + result) }
  if result.find("\"Green\" => Some(Color::Green)") is None { fail("expected Green match, got: " + result) }
  if result.find("\"Blue\" => Some(Color::Blue)") is None { fail("expected Blue match, got: " + result) }
  if result.find("_ => None") is None { fail("expected fallback, got: " + result) }
}

test "verify_expand_greet_macro" {
  let source = "macro_rules! greet { ($name:expr) => { fn greet_$name() -> String { \"Hello, $name!\" } } }\ngreet!(World)"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_file(source, defs)
  if result.find("fn greet_World") is None { fail("expected greet_World") }
  if result.find("Hello, World!") is None { fail("expected Hello, World!") }
  if result.find("macro_rules!") is None { fail("macro definition should be preserved") }
}

test "verify_expand_nested_macro" {
  let source = "macro_rules! double { ($x:expr) => { $x * 2 } }\nmacro_rules! apply { ($f:expr) => { double!($f) } }\nlet result = apply!(21)"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_file(source, defs)
  if result.find("21 * 2") is None { fail("expected 21 * 2, got: " + result) }
  if result.find("double!") is Some(_) { fail("double! should be fully expanded") }
}

test "verify_builtin_stringify" {
  let source = "let s = stringify!(hello world)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("\"hello world\"") is None { fail("expected quoted string, got: " + result) }
}

test "verify_builtin_assert" {
  let source = "assert!(x > 0)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("abort") is None { fail("expected abort in assert output, got: " + result) }
  if result.find("println") is None { fail("expected println in assert output") }
  if result.find("x > 0") is None { fail("expected condition preserved") }
}

test "verify_builtin_matches" {
  let source = "let b = matches!(result, Ok(val))"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("match result") is None { fail("expected match, got: " + result) }
  if result.find("Ok(val) => true") is None { fail("expected Ok(val) => true") }
  if result.find("_ => false") is None { fail("expected fallthrough false, got: " + result) }
}

test "verify_builtin_todo" {
  let source = "todo!()"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("abort") is None { fail("expected abort in todo output, got: " + result) }
}

test "verify_builtin_todo_with_message" {
  let source = "todo!(\"fix this\")"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("abort") is None { fail("expected abort in todo output") }
}

test "verify_stacked_derive" {
  let source = "#[macro_derive(Constructor)]\n#[macro_derive(Getters)]\nstruct Point { x: Int, y: Int }"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Point::new") is None { fail("expected new") }
  if result.find("pub fn Point::x") is None { fail("expected getter x") }
  if result.find("pub fn Point::y") is None { fail("expected getter y") }
  if result.find("#[macro_derive") is Some(_) { fail("should not contain #[macro_derive, got: " + result) }
}

test "verify_derive_constructor_kind_error" {
  let source = "#[macro_derive(Constructor)]\nenum Color {\n  Red\n  Green\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("only supports structs") is None { fail("expected error message") }
}

test "verify_derive_enum_from_str_data_variants" {
  let source = "#[macro_derive(EnumFromStr)]\nenum Expr {\n  Int(Int)\n  Add(Expr, Expr)\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("requires at least one unit variant") is None { fail("expected error for no unit variants") }
}

test "verify_preserves_non_macro_code" {
  let source = "fn main {\n  println(\"hello\")\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result != source { fail("non-macro source should be unchanged, got: " + result) }
}

test "verify_derive_constructor_single_field" {
  let source = "#[macro_derive(Constructor)]\nstruct Wrap {\n  value: String\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Wrap") is None { fail("struct Wrap should be present") }
  if result.find("pub fn Wrap::new") is None { fail("expected Wrap::new") }
  if result.find("value: String") is None { fail("expected value param") }
}

test "verify_derive_constructor_mut_field" {
  let source = "#[macro_derive(Constructor)]\nstruct Point {\n  mut x: Int\n  y: String\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Point::new") is None { fail("expected Point::new") }
  if result.find("x: Int, y: String") is None { fail("expected params") }
}

test "verify_derive_constructor_empty" {
  let source = "#[macro_derive(Constructor)]\nstruct Empty {}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Empty") is None { fail("struct should be preserved") }
}

test "verify_derive_getters_generic" {
  let source = "#[macro_derive(Getters)]\nstruct Wrap[T] {\n  value: T\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("struct Wrap[T]") is None { fail("struct should be present") }
  if result.find("pub fn[T] Wrap::value") is None { fail("expected getter value, got: " + result) }
  if result.find("self: Wrap[T]") is None { fail("expected self: Wrap[T]") }
  if result.find("-> T") is None { fail("expected T return type") }
}

test "verify_derive_getters_single_field" {
  let source = "#[macro_derive(Getters)]\nstruct Wrap { value: String }"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Wrap::value") is None { fail("expected getter value") }
  if result.find("self: Wrap") is None { fail("expected self param") }
}

test "verify_derive_enum_from_str_mixed" {
  let source = "#[macro_derive(EnumFromStr)]\nenum Expr {\n  Int(Int)\n  Add(Expr, Expr)\n  Zero\n  One\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Expr::from_string") is None { fail("expected from_string") }
  if result.find("\"Zero\" => Some(Expr::Zero)") is None { fail("expected Zero, got: " + result) }
  if result.find("\"One\" => Some(Expr::One)") is None { fail("expected One, got: " + result) }
  if result.find("\"Int\"") is Some(_) { fail("should not match data variant Int") }
  if result.find("_ => None") is None { fail("expected fallback, got: " + result) }
}

test "verify_builtin_matches_complex" {
  let source = "let b = matches!(x, Some(y))"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("match x") is None { fail("expected match x") }
  if result.find("Some(y) => true") is None { fail("expected Some(y) => true, got: " + result) }
}

test "verify_builtin_assert_complex" {
  let source = "assert!(x > 0 && y < 10)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("if !(x > 0 && y < 10)") is None { fail("expected condition preserved") }
  if result.find("assertion failed: x > 0 && y < 10") is None { fail("expected message preserved") }
}

test "verify_builtin_dbg" {
  let source = "let x = 42\nlet y = dbg!(x + 1)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("let __dbg_val = x + 1") is None { fail("expected var binding, got: " + result) }
  // stringify! is expanded in a later pass, so check for its result
  if result.find("\"x + 1\"") is None { fail("expected quoted expr text, got: " + result) }
  if result.find("__dbg_val.to_string()") is None { fail("expected to_string") }
}

test "verify_builtin_dbg_nested_parens" {
  let source = "let y = dbg!(foo(1, 2))"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("let __dbg_val = foo(1, 2)") is None { fail("expected nested parens, got: " + result) }
  if result.find("\"foo(1, 2)\"") is None { fail("expected quoted expr text") }
}

test "verify_builtin_let_array_simple" {
  let source = "let_array!(a, b, c = arr)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("let a = arr[0]") is None { fail("expected let a = arr[0], got: " + result) }
  if result.find("let b = arr[1]") is None { fail("expected let b = arr[1]") }
  if result.find("let c = arr[2]") is None { fail("expected let c = arr[2]") }
}

test "verify_builtin_let_array_mut" {
  let source = "let_array!(mut x, mut y = state)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("let mut x = state[0]") is None { fail("expected let mut x = state[0], got: " + result) }
  if result.find("let mut y = state[1]") is None { fail("expected let mut y = state[1]") }
}

test "verify_builtin_let_array_start" {
  let source = "let_array!(a, b, c = items, start: 5)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("let a = items[5]") is None { fail("expected let a = items[5], got: " + result) }
  if result.find("let b = items[6]") is None { fail("expected let b = items[6]") }
  if result.find("let c = items[7]") is None { fail("expected let c = items[7]") }
}

test "verify_builtin_let_array_brackets" {
  let source = "let_array!(a, b = get_arr())"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("let a = get_arr()[0]") is None { fail("expected bracket expr, got: " + result) }
  if result.find("let b = get_arr()[1]") is None { fail("expected let b = get_arr()[1]") }
}

test "verify_builtin_call_each_simple" {
  let source = "call_each!(m.add, \"a\", \"b\", \"bc\")"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("m.add(\"a\")") is None { fail("expected m.add(\"a\"), got: " + result) }
  if result.find("m.add(\"b\")") is None { fail("expected m.add(\"b\")") }
  if result.find("m.add(\"bc\")") is None { fail("expected m.add(\"bc\")") }
}

test "verify_builtin_call_each_dotted" {
  let source = "call_each!(m.add, 1, 2, 3)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("m.add(1)") is None { fail("expected m.add(1), got: " + result) }
  if result.find("m.add(2)") is None { fail("expected m.add(2)") }
  if result.find("m.add(3)") is None { fail("expected m.add(3)") }
}

test "verify_builtin_call_each_multi_arg" {
  let source = "call_each!(map.insert, (\"k1\", 1), (\"k2\", 2))"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("map.insert(\"k1\", 1)") is None { fail("expected map.insert(k1,1), got: " + result) }
  if result.find("map.insert(\"k2\", 2)") is None { fail("expected map.insert(k2,2)") }
}

test "verify_builtin_call_each_mixed_arity_rejected" {
  let source = "call_each!(f, a, (b, c), d)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result != source { fail("expected unexpanded, got: " + result) }
}

test "verify_builtin_repeat_array_make" {
  let source = "let state = [repeat!(Array::make(4, 0), 4)]"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("[Array::make(4, 0), Array::make(4, 0), Array::make(4, 0), Array::make(4, 0)]") is None {
    fail("expected repeated array init, got: " + result)
  }
}

test "verify_builtin_repeat_custom_sep" {
  let source = "repeat!(x, 3, +)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("x+x+x") is None { fail("expected x+x+x, got: " + result) }
}

test "verify_builtin_inspect" {
  let source = "inspect!(f(), \"ok\")"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("@debug.debug_inspect(f(), content=\"ok\")") is None {
    fail("expected inspect expansion, got: " + result)
  }
}

test "verify_builtin_echo" {
  let source = "echo!(x, y)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("println(\"x = \\{x}, y = \\{y}\")") is None {
    fail("expected echo expansion, got: " + result)
  }
}

test "verify_builtin_logger" {
  let source = "logger!(fn calc() -> Int {\n  42\n})"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("entering calc") is None { fail("expected entering calc, got: " + result) }
  if result.find("leaving calc") is None { fail("expected leaving calc, got: " + result) }
  if result.find("defer { println") is None { fail("expected defer, got: " + result) }
}

test "verify_builtin_timeit" {
  let source = "timeit!(fn compute() -> Int {\n  99\n})"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("@env.now()") is None { fail("expected @env.now(), got: " + result) }
  if result.find("__timeit_start") is None { fail("expected __timeit_start, got: " + result) }
  if result.find("compute took") is None { fail("expected compute took, got: " + result) }
}

test "verify_builtin_tryn" {
  let source = "tryn!(read_line(), 3)"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("__tryn_max = 3") is None { fail("expected __tryn_max = 3, got: " + result) }
  if result.find("read_line()") is None { fail("expected read_line(), got: " + result) }
  if result.find("loop") is None { fail("expected loop, got: " + result) }
  if result.find("break None") is None { fail("expected break None, got: " + result) }
  if result.find("break __tryn_cur") is None { fail("expected break __tryn_cur, got: " + result) }
}

test "verify_custom_derive_marker" {
  let source = "macro_derive! MyMarker {\n  pub fn $T::is_active(self: $T) -> Bool { true }\n}\n#[macro_derive(MyMarker)]\nstruct Config {\n  debug: Bool\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("macro_derive!") is None && result.find("macro_derive") is Some(_) {  }
  if result.find("Config::is_active") is None { fail("expected Config::is_active, got: " + result) }
  if result.find("struct Config") is None { fail("expected struct Config, got: " + result) }
}

test "verify_custom_derive_multiple_traits" {
  let source = "macro_derive! MyMarker { // marker\n}\nmacro_derive! MyAccessors {\n  pub fn $T::name(self: $T) -> String { \"$body\" }\n}\n#[macro_derive(MyMarker, MyAccessors)]\nenum Stuff {\n  A\n  B\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("// marker") is None { fail("expected marker output, got: " + result) }
  if result.find("Stuff::name") is None { fail("expected name accessor, got: " + result) }
  if result.find("unknown derive") is Some(_) { fail("unexpected unknown derive: " + result) }
}

test "verify_custom_derive_totuple" {
  let source = "macro_derive! ToTuple {\n  pub fn $T::to_tuple(self: $T) -> ($field_types) { ($fields) }\n}\n#[macro_derive(ToTuple)]\nstruct Point {\n  x: Int\n  y: Int\n}\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("-> (Int, Int)") is None { fail("expected -> (Int, Int), got: " + result) }
  if result.find("(x, y)") is None { fail("expected (x, y), got: " + result) }
  if result.find("Point::to_tuple") is None { fail("expected Point::to_tuple, got: " + result) }
}

test "verify_custom_derive_enuminfo" {
  let source = "macro_derive! EnumInfo {\n  pub fn $T::variant_count() -> Int { \"$variants\".split(\", \").length() }\n  pub fn $T::kind() -> String { \"$kind\" }\n}\n#[macro_derive(EnumInfo)]\nenum Color {\n  Red\n  Green\n  Blue\n}\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("Color::variant_count") is None { fail("expected variant_count, got: " + result) }
  if result.find("Color::kind") is None { fail("expected kind, got: " + result) }
  if result.find("\"Red, Green, Blue\"") is None { fail("expected variants string, got: " + result) }
  if result.find("\"enum\"") is None { fail("expected kind string, got: " + result) }
}

test "verify_custom_derive_fieldnames" {
  let source = "macro_derive! FieldNames {\n  pub fn $T::field_names() -> Array[String] { [\"$fields\"].flat_map(fn(s) { s.split(\", \") }) }\n}\n#[macro_derive(FieldNames)]\nstruct Point {\n  x: Int\n  y: Int\n}\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("Point::field_names") is None { fail("expected field_names, got: " + result) }
  if result.find("\"x, y\"") is None { fail("expected field string, got: " + result) }
  if result.find("split") is None { fail("expected split, got: " + result) }
}

test "verify_custom_derive_allmeta" {
  let source = "macro_derive! AllMeta {\n  pub fn $T::type_name() -> String { \"$T\" }\n  pub fn $T::kind() -> String { \"$kind\" }\n  pub fn $T::generics_str() -> String { \"$generics\" }\n  pub fn $T::fields_str() -> String { \"$fields\" }\n  pub fn $T::field_types_str() -> String { \"$field_types\" }\n  pub fn $T::variants_str() -> String { \"$variants\" }\n  pub fn $T::body_str() -> String { \"$body\" }\n  pub fn $T::display_name() -> String { \"$Name\" }\n}\n#[macro_derive(AllMeta)]\nstruct Point {\n  x: Int\n  y: String\n}\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let expanded = @moonmacro.expand_file(source, defs)
  let result = @moonmacro.strip_macro_defs(expanded)
  if result.find("type_name") is None { fail("expected type_name, got: " + result) }
  if result.find("\"Point\"") is None { fail("expected $T, got: " + result) }
  if result.find("struct") is None { fail("expected $kind, got: " + result) }
  if result.find("x, y") is None { fail("expected $fields, got: " + result) }
  if result.find("Int, String") is None { fail("expected $field_types, got: " + result) }
  if result.find("Point::variants_str") is None { fail("expected variants_str, got: " + result) }
  if result.find("display_name") is None { fail("expected $Name method, got: " + result) }
}

test "verify_derive_enum_with_fielded_variants" {
  let source = "#[macro_derive(Constructor)]\nenum Result {\n  Ok(Int)\n  Err(String)\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("only supports structs") is None { fail("expected error for enum with fields") }
}

test "verify_custom_derive_enum_field_types" {
  let source = "macro_derive! TypeList {\n  pub fn $T::type_list() -> String { \"$field_types\" }\n}\n#[macro_derive(TypeList)]\nenum Result {\n  Ok(Int)\n  Err(String)\n}\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let expanded = @moonmacro.expand_file(source, defs)
  let result = @moonmacro.strip_macro_defs(expanded)
  if result.find("Result::type_list") is None { fail("expected type_list, got: " + result) }
  if result.find("\"Int, String\"") is None { fail("expected Int, String, got: " + result) }
}

test "verify_custom_derive_fullinfo" {
  let source = "macro_derive! FullInfo {\n  pub fn $T::full_type_name() -> String { \"$Name ($T)\" }\n  pub fn $T::kind_str() -> String { \"$kind\" }\n  pub fn $T::generics_str() -> String { \"$generics\" }\n  pub fn $T::fields_str() -> String { \"$fields\" }\n  pub fn $T::field_types_str() -> String { \"$field_types\" }\n  pub fn $T::variants_str() -> String { \"$variants\" }\n  pub fn $T::body_str() -> String { \"$body\" }\n}\n#[macro_derive(FullInfo)]\nenum Color {\n  Red\n  Green\n  Blue\n}\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let expanded = @moonmacro.expand_file(source, defs)
  let result = @moonmacro.strip_macro_defs(expanded)
  if result.find("Color (Color)") is None { fail("expected $Name ($T), got: " + result) }
  if result.find("enum") is None { fail("expected $kind=enum, got: " + result) }
  if result.find("Red, Green, Blue") is None { fail("expected variants, got: " + result) }
  if result.find("Color::fields_str") is None { fail("expected fields_str, got: " + result) }
  if result.find("Color::field_types_str") is None { fail("expected field_types_str, got: " + result) }
}

test "verify_derive_enum_from_str_generic" {
  let source = "#[macro_derive(EnumFromStr)]\nenum Box[T] {\n  Item(T)\n  Empty\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn[T] Box::from_string") is None { fail("expected generic from_string, got: " + result) }
  if result.find("-> Box[T]?") is None { fail("expected Box[T]? return, got: " + result) }
  if result.find("\"Empty\" => Some(Box::Empty)") is None { fail("expected Empty match, got: " + result) }
  if result.find("\"Item\"") is Some(_) { fail("should not match data variant Item") }
}

test "verify_derive_enum_from_str_many_variants" {
  let source = "#[macro_derive(EnumFromStr)]\nenum Day {\n  Mon\n  Tue\n  Wed\n  Thu\n  Fri\n  Sat\n  Sun\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Day::from_string") is None { fail("expected from_string") }
  if result.find("\"Mon\" => Some(Day::Mon)") is None { fail("expected Mon match, got: " + result) }
  if result.find("\"Sun\" => Some(Day::Sun)") is None { fail("expected Sun match, got: " + result) }
  if result.find("_ => None") is None { fail("expected fallback, got: " + result) }
}

test "verify_derive_enum_from_str_empty" {
  let source = "#[macro_derive(EnumFromStr)]\nenum Empty {\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("requires at least one unit variant") is None { fail("expected error for empty enum, got: " + result) }
}

test "verify_derive_enum_from_str_stacked" {
  let source = "#[macro_derive(EnumFromStr)]\n#[macro_derive(Getters)]\nstruct Point {\n  x: Int\n  y: Int\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Point::x") is None { fail("expected getter x, got: " + result) }
  if result.find("pub fn Point::y") is None { fail("expected getter y, got: " + result) }
  if result.find("// EnumFromStr only supports enums") is None { fail("expected EnumFromStr error, got: " + result) }
}

test "verify_derive_enum_from_str_trailing_semicolon" {
  let source = "#[macro_derive(EnumFromStr)]\nenum Color {\n  Red;\n  Green;\n  Blue;\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Color::from_string") is None { fail("expected from_string") }
  if result.find("\"Red\" => Some(Color::Red)") is None { fail("expected Red match, got: " + result) }
  if result.find("\"Blue\" => Some(Color::Blue)") is None { fail("expected Blue match, got: " + result) }
}
