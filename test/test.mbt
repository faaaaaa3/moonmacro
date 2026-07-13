test "find_macro_defs" {
  let source = "macro_rules! foo { ($x:expr) => { $x } }"
  let defs = @moonmacro.find_macro_defs(source)
  if defs.length() != 1 { fail("expected 1 def, got " + defs.length().to_string()) }
  if defs[0].name != "foo" { fail("expected name foo, got " + defs[0].name) }
  if defs[0].patterns.length() != 1 { fail("expected 1 rule") }
}

test "find_macro_defs_multiple" {
  let source = "macro_rules! a { ($x:expr) => { $x } } macro_rules! b { ($y:expr) => { $y } }"
  let defs = @moonmacro.find_macro_defs(source)
  if defs.length() != 2 { fail("expected 2 defs") }
  if defs[0].name != "a" { fail("expected name a") }
  if defs[1].name != "b" { fail("expected name b") }
}

test "find_macro_invocations" {
  let source = "greet!(World)"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { fail("expected 1 invocation") }
  match invs[0] {
    @moonmacro.FuncCall(name, args, delim, _s, _e) => {
      if name != "greet" { fail("expected name greet") }
      if args != "World" { fail("expected args World") }
      if delim != "(" { fail("expected delim (") }
    }
    _ => fail("expected FuncCall")
  }
}

test "find_bracket_invocation" {
  let source = "name![1, 2, 3]"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { fail("expected 1 invocation") }
  match invs[0] {
    @moonmacro.FuncCall(name, args, delim, _s, _e) => {
      if name != "name" { fail("expected name name") }
      if args != "1, 2, 3" { fail("expected args") }
      if delim != "[" { fail("expected delim [") }
    }
    _ => fail("expected FuncCall")
  }
}

test "parse_pattern_simple" {
  let frags = @moonmacro.parse_pattern("$x:expr")
  if frags.length() != 1 { fail("expected 1 fragment") }
  match frags[0] {
    @moonmacro.Capture(name, kind) => {
      if name != "x" { fail("expected name x") }
      if kind != "expr" { fail("expected kind expr") }
    }
    _ => fail("expected Capture")
  }
}

test "parse_pattern_repetition" {
  let frags = @moonmacro.parse_pattern("$($x:expr),*")
  if frags.length() != 1 { fail("expected 1 fragment (Repetition)") }
  match frags[0] {
    @moonmacro.Repetition(_inner, sep, _op) => {
      if sep != "," { fail("expected sep ','") }
    }
    _ => fail("expected Repetition")
  }
}

test "parse_pattern_mixed" {
  let frags = @moonmacro.parse_pattern("[$($x:expr),*]")
  if frags.length() != 3 { fail("expected 3 fragments, got " + frags.length().to_string()) }
  match frags[0] {
    @moonmacro.Lit(s) => { if s != "[" { fail("expected Lit '['") } }
    _ => fail("expected Lit")
  }
  match frags[1] {
    @moonmacro.Repetition(_inner, _sep, _op) => ()
    _ => fail("expected Repetition")
  }
  match frags[2] {
    @moonmacro.Lit(s) => { if s != "]" { fail("expected Lit ']'") } }
    _ => fail("expected Lit")
  }
}

test "match_simple" {
  let matched = @moonmacro.match_pattern("$x:expr", "42")
  match matched {
    None => fail("expected match")
    Some(captures) => {
      if !captures.contains("x") { fail("expected capture x") }
      if captures["x"][0] != "42" { fail("expected '42'") }
    }
  }
}

test "match_repetition" {
  let matched = @moonmacro.match_pattern("$($x:expr),*", "1, 2, 3")
  match matched {
    None => fail("expected match")
    Some(captures) => {
      if captures["x"].length() != 3 { fail("expected 3 captures") }
      if captures["x"][0] != "1" { fail("expected '1'") }
      if captures["x"][1] != "2" { fail("expected '2'") }
      if captures["x"][2] != "3" { fail("expected '3'") }
    }
  }
}

test "match_repetition_single" {
  let matched = @moonmacro.match_pattern("$($x:expr),*", "42")
  match matched {
    None => fail("expected match")
    Some(captures) => {
      if captures["x"].length() != 1 { fail("expected 1 capture") }
      if captures["x"][0] != "42" { fail("expected '42'") }
    }
  }
}

test "match_multi_capture_with_brackets" {
  let matched = @moonmacro.match_pattern("[$x:expr] rest $y:expr", "[42] rest hello")
  match matched {
    None => fail("expected match")
    Some(captures) => {
      if captures["x"][0] != "42" { fail("expected x='42'") }
      if captures["y"][0] != "hello" { fail("expected y='hello'") }
    }
  }
}

test "match_multi_capture_with_literal" {
  let matched = @moonmacro.match_pattern("$x:expr + $y:expr", "1 + 2")
  match matched {
    None => fail("expected match")
    Some(captures) => {
      if !captures.contains("x") { fail("expected x") }
      if !captures.contains("y") { fail("expected y") }
      if captures["x"][0] != "1" { fail("expected x='1'") }
      if captures["y"][0] != "2" { fail("expected y='2'") }
    }
  }
}

test "match_repetition_empty" {
  let matched = @moonmacro.match_pattern("$($x:expr),*", "")
  match matched {
    None => fail("expected match for empty input")
    Some(captures) => {
      if captures["x"].length() != 0 { fail("expected 0 captures") }
    }
  }
}

test "expand_simple" {
  let captures : Map[String, Array[String]] = { "x": ["42"] }
  let result = @moonmacro.expand_template("result = $x", captures)
  if result != "result = 42" { fail("expected 'result = 42'") }
}

test "expand_repetition_template" {
  let captures : Map[String, Array[String]] = { "x": ["1", "2", "3"] }
  let result = @moonmacro.expand_template("[$($x),*]", captures)
  if result != "[1,2,3]" { fail("expected '[1,2,3]'") }
}

test "expand_macro_call" {
  let source = "macro_rules! double { ($x:expr) => { $x * 2 } }"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_macro_call("double", "21", defs)
  match result {
    None => fail("expected Some")
    Some(code) => {
      let trimmed = code.trim().to_owned()
      if trimmed != "21 * 2" { fail("expected '21 * 2'") }
    }
  }
}

test "expand_file" {
  let source = "macro_rules! greet { ($name:expr) => { fn greet_$name() {} } }\ngreet!(World)\n"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_file(source, defs)
  if result.find("greet_World") is None { fail("expected greet_World in output") }
  if result.find("macro_rules!") is None { fail("expected macro_rules! preserved") }
}

test "expand_builtin_stringify" {
  match @moonmacro.expand_builtin("stringify", "hello") {
    None => fail("expected Some")
    Some(code) => if code != "\"hello\"" { fail("expected '\"hello\"'") }
  }
}

test "expand_builtin_unknown" {
  let result = @moonmacro.expand_builtin("nope", "args")
  if result is Some(_) { fail("expected None for unknown builtin") }
}

test "find_derive_invocation" {
  let source = "#[macro_derive(Constructor)]\nstruct Point { x: Int, y: Int }\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { fail("expected 1 invocation") }
  match invs[0] {
    @moonmacro.Derive(traits, name, kind, _generics, _body, _s, _e) => {
      if traits.length() != 1 { fail("expected 1 trait, got " + traits.length().to_string()) }
      if traits[0] != "Constructor" { fail("expected Constructor, got " + traits[0]) }
      if name != "Point" { fail("expected Point") }
      if kind != "struct" { fail("expected struct") }
    }
    _ => fail("expected Derive")
  }
}

test "derive_with_braces" {
  let source = "#[macro_derive(Constructor)]\nstruct Point {\n  x: Int\n  y: Int\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { fail("expected 1 invocation") }
  match invs[0] {
    @moonmacro.Derive(_traits, name, _kind, _generics, body, _s, _e) => {
      if name != "Point" { fail("expected Point") }
      if body.find("x: Int") is None { fail("body should contain x: Int") }
    }
    _ => fail("expected Derive")
  }
}

test "generate_derive_constructor" {
  let result = @moonmacro.generate_derives(["Constructor"], "Point", "struct", "", "{ x: Int, y: Int }", [])
  if result.find("pub fn Point::new") is None { fail("expected Point::new, got: " + result) }
  if result.find("x: Int, y: Int") is None { fail("expected params") }
  if result.find("{ x, y }") is None { fail("expected struct literal") }
}

test "generate_derive_constructor_generic" {
  let result = @moonmacro.generate_derives(["Constructor"], "Pair", "struct", "[T]", "{ first: T, second: T }", [])

  if result.find("pub fn Pair::new[T]") is None { fail("expected Pair::new[T]") }
  if result.find("first: T, second: T") is None { fail("expected typed params") }
  if result.find("-> Pair[T]") is None { fail("expected Pair[T] return") }
}

test "generate_derive_getters" {
  let result = @moonmacro.generate_derives(["Getters"], "Point", "struct", "", "{ x: Int, y: String }", [])

  if result.find("pub fn Point::x") is None { fail("expected getter x, got: " + result) }
  if result.find("pub fn Point::y") is None { fail("expected getter y") }
  if result.find("self: Point") is None { fail("expected self param") }
  if result.find("-> Int") is None { fail("expected Int return") }
  if result.find("-> String") is None { fail("expected String return") }
  if result.find("self.x") is None { fail("expected self.x body") }
}

test "generate_derive_enum_from_str" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Color", "enum", "", "{\n  Red\n  Green\n}", [])

  if result.find("pub fn Color::from_string") is None { fail("expected from_string") }
  if result.find("\"Red\" => Some(Color::Red)") is None { fail("expected Red match, got: " + result) }
  if result.find("\"Green\" => Some(Color::Green)") is None { fail("expected Green match, got: " + result) }
  if result.find("_ => None") is None { fail("expected fallback, got: " + result) }
  if result.find("-> Color?") is None { fail("expected Color? return") }
}

test "generate_derive_enum_from_str_skips_data_variants" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Expr", "enum", "", "{\n  Int(Int)\n  Add(Expr, Expr)\n}", [])

  if result.find("// EnumFromStr requires") is None { fail("expected error for no unit variants") }
}

test "stacked_derive_same_struct" {
  let source = "#[macro_derive(Constructor)]\n#[macro_derive(Constructor)]\nstruct Point { x: Int }\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { fail("expected 1 invocation, got " + invs.length().to_string()) }
  match invs[0] {
    @moonmacro.Derive(traits, name, _kind, _generics, _body, _s, _e) => {
      if traits.length() != 2 { fail("expected 2 merged traits, got " + traits.length().to_string()) }
      if traits[0] != "Constructor" { fail("expected Constructor") }
      if traits[1] != "Constructor" { fail("expected Constructor") }
      if name != "Point" { fail("expected Point") }
    }
    _ => fail("expected Derive")
  }
}

test "generate_derive_constructor_kind_error" {
  let result = @moonmacro.generate_derives(["Constructor"], "Color", "enum", "", "{ Red; Green }", [])

  if result.find("only supports structs") is None { fail("expected error for enum") }
}

test "generate_derive_getters_kind_error" {
  let result = @moonmacro.generate_derives(["Getters"], "Color", "enum", "", "{ Red; Green }", [])

  if result.find("only supports structs") is None { fail("expected error for enum") }
}

test "generate_derive_enum_from_str_kind_error" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Point", "struct", "", "{ x: Int }", [])

  if result.find("only supports enums") is None { fail("expected error for struct") }
}

test "expand_builtin_matches" {
  match @moonmacro.expand_builtin("matches", "x, Some(y)") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("match x") is None { fail("expected match x") }
      if code.find("Some(y) => true") is None { fail("expected pattern match, got: " + code) }
    }
  }
}

test "expand_builtin_todo" {
  match @moonmacro.expand_builtin("todo", "") {
    None => fail("expected Some")
    Some(code) => if code != "println(\"not implemented\"); abort(\"\")" { fail("expected 'not implemented', got: " + code) }
  }
}

test "expand_builtin_todo_with_message" {
  // args from source todo!("fix this") includes surrounding quotes
  match @moonmacro.expand_builtin("todo", "\"fix this\"") {
    None => fail("expected Some")
    Some(code) => if code != "println(\"fix this\"); abort(\"\")" { fail("expected 'fix this', got: " + code) }
  }
}

test "expand_file_nested" {
  let source = "macro_rules! double { ($x:expr) => { $x * 2 } }\nmacro_rules! apply { ($f:expr) => { double!($f) } }\napply!(21)\n"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_file(source, defs)
  if result.find("21 * 2") is None { fail("expected 21 * 2 after nested expansion") }
  if result.find("double!") is Some(_) { fail("double! should be expanded away") }
}

test "no_matches" {
  let source = "fn main { println(\"hello\") }"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 0 { fail("expected 0 invocations, got " + invs.length().to_string()) }
}

test "expand_builtin_dbg_simple" {
  match @moonmacro.expand_builtin("dbg", "x") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("let __dbg_val = x") is None { fail("expected var binding, got: " + code) }
      if code.find("stringify!(x)") is None { fail("expected stringify!(x)") }
      if code.find("__dbg_val.to_string()") is None { fail("expected to_string call") }
      if code.find("__dbg_val") is None { fail("expected __dbg_val") }
    }
  }
}

test "expand_builtin_dbg_complex_expr" {
  match @moonmacro.expand_builtin("dbg", "foo(1, 2) + bar[baz]") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("let __dbg_val = foo(1, 2) + bar[baz]") is None { fail("expected full expr, got: " + code) }
      if code.find("stringify!(foo(1, 2) + bar[baz])") is None { fail("expected stringify with brackets, got: " + code) }
    }
  }
}

test "expand_builtin_dbg_empty" {
  match @moonmacro.expand_builtin("dbg", "") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("let __dbg_val = ") is None { fail("expected empty var binding") }
    }
  }
}

test "find_macro_defs_empty" {
  let source = ""
  let defs = @moonmacro.find_macro_defs(source)
  if defs.length() != 0 { fail("expected 0 defs") }
}

test "find_macro_defs_no_macros" {
  let source = "fn main { println(\"hello\") }"
  let defs = @moonmacro.find_macro_defs(source)
  if defs.length() != 0 { fail("expected 0 defs") }
}

test "find_macro_invocations_nested_brackets" {
  let source = "foo!(bar[baz])"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { fail("expected 1 invocation") }
  match invs[0] {
    @moonmacro.FuncCall(name, args, delim, _s, _e) => {
      if name != "foo" { fail("expected name foo") }
      if args != "bar[baz]" { fail("expected args 'bar[baz]'") }
      if delim != "(" { fail("expected delim (") }
    }
    _ => fail("expected FuncCall")
  }
}

test "expand_builtin_assert" {
  match @moonmacro.expand_builtin("assert", "x > 0") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("if !(x > 0)") is None { fail("expected condition") }
      if code.find("assertion failed: x > 0") is None { fail("expected message") }
    }
  }
}

test "expand_builtin_matches_no_comma" {
  let result = @moonmacro.expand_builtin("matches", "x Some(y)")
  if result is Some(_) { fail("expected None without comma") }
}

test "expand_builtin_stringify_empty" {
  match @moonmacro.expand_builtin("stringify", "") {
    None => fail("expected Some")
    Some(code) => if code != "\"\"" { fail("expected empty quotes") }
  }
}

test "expand_builtin_stringify_special" {
  match @moonmacro.expand_builtin("stringify", "a + b * c") {
    None => fail("expected Some")
    Some(code) => if code != "\"a + b * c\"" { fail("expected quoted, got: " + code) }
  }
}

test "generate_derive_constructor_single_field" {
  let result = @moonmacro.generate_derives(["Constructor"], "Wrap", "struct", "", "{ value: Int }", [])

  if result.find("pub fn Wrap::new") is None { fail("expected Wrap::new") }
  if result.find("value: Int") is None { fail("expected value: Int") }
  if result.find("{ value }") is None { fail("expected struct literal") }
}

test "generate_derive_constructor_empty_struct" {
  let result = @moonmacro.generate_derives(["Constructor"], "Empty", "struct", "", "{}", [])

  if result.find("requires at least one field") is None { fail("expected error for empty struct") }
}

test "generate_derive_constructor_mut_field" {
  let result = @moonmacro.generate_derives(["Constructor"], "Point", "struct", "", "{ mut x: Int, y: String }", [])

  if result.find("pub fn Point::new") is None { fail("expected Point::new") }
  if result.find("x: Int") is None { fail("expected x: Int param") }
  if result.find("{ x, y }") is None { fail("expected struct literal") }
}

test "generate_derive_getters_single_field" {
  let result = @moonmacro.generate_derives(["Getters"], "Wrap", "struct", "", "{ value: String }", [])

  if result.find("pub fn Wrap::value") is None { fail("expected getter value") }
  if result.find("self: Wrap") is None { fail("expected self param") }
  if result.find("-> String") is None { fail("expected String return") }
}

test "generate_derive_getters_empty_struct" {
  let result = @moonmacro.generate_derives(["Getters"], "Empty", "struct", "", "{}", [])

  if result.find("requires at least one field") is None { fail("expected error for empty struct") }
}

test "generate_derive_getters_generic" {
  let result = @moonmacro.generate_derives(["Getters"], "Wrap", "struct", "[T]", "{ value: T }", [])

  if result.find("pub fn Wrap::value") is None { fail("expected getter value") }
  if result.find("self: Wrap[T]") is None { fail("expected self: Wrap[T]") }
  if result.find("-> T") is None { fail("expected T return") }
  if result.find("self.value") is None { fail("expected self.value body") }
}

test "generate_derive_enum_from_str_single" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Status", "enum", "", "{\n  Active\n}", [])

  if result.find("pub fn Status::from_string") is None { fail("expected from_string") }
  if result.find("\"Active\" => Some(Status::Active)") is None { fail("expected Active match, got: " + result) }
  if result.find("_ => None") is None { fail("expected fallback, got: " + result) }
}

test "generate_derive_enum_from_str_mixed" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Expr", "enum", "", "{\n  Int(Int)\n  Add(Expr, Expr)\n  Zero\n}", [])

  if result.find("pub fn Expr::from_string") is None { fail("expected from_string") }
  if result.find("\"Zero\" => Some(Expr::Zero)") is None { fail("expected Zero match, got: " + result) }
  if result.find("\"Int\"") is Some(_) { fail("should not match Int (data variant)") }
}

test "separate_derive_on_different_structs" {
  let source = "#[macro_derive(Constructor)]\nstruct Point { x: Int }\n\n#[macro_derive(Getters)]\nstruct Wrap { value: String }"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 2 { fail("expected 2 separate invocations, got " + invs.length().to_string()) }
  match invs[0] {
    @moonmacro.Derive(traits, name, _kind, _generics, _body, _s, _e) => {
      if traits.length() != 1 { fail("expected 1 trait") }
      if name != "Point" { fail("expected Point") }
    }
    _ => fail("expected Derive for Point")
  }
  match invs[1] {
    @moonmacro.Derive(traits, name, _kind, _generics, _body, _s, _e) => {
      if traits[0] != "Getters" { fail("expected Getters") }
      if name != "Wrap" { fail("expected Wrap") }
    }
    _ => fail("expected Derive for Wrap")
  }
}

test "expand_builtin_unknown_case_sensitive" {
  let result = @moonmacro.expand_builtin("DBG", "x")
  if result is Some(_) { fail("expected None for wrong case") }
}

test "expand_file_no_change" {
  let source = "fn add(x: Int, y: Int) -> Int { x + y }"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result != source { fail("plain code should be unchanged") }
}

test "expand_builtin_let_array_simple" {
  match @moonmacro.expand_builtin("let_array", "a, b, c = arr") {
    None => fail("expected Some")
    Some(code) => {
      if code != "let a = arr[0]; let b = arr[1]; let c = arr[2]" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_let_array_mut" {
  match @moonmacro.expand_builtin("let_array", "mut a, mut b = state") {
    None => fail("expected Some")
    Some(code) => {
      if code != "let mut a = state[0]; let mut b = state[1]" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_let_array_mixed_mut" {
  match @moonmacro.expand_builtin("let_array", "mut a, b, mut c = data") {
    None => fail("expected Some")
    Some(code) => {
      if code != "let mut a = data[0]; let b = data[1]; let mut c = data[2]" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_let_array_with_start" {
  match @moonmacro.expand_builtin("let_array", "a, b = items, start: 3") {
    None => fail("expected Some")
    Some(code) => {
      if code != "let a = items[3]; let b = items[4]" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_let_array_single_var" {
  match @moonmacro.expand_builtin("let_array", "x = get_array()") {
    None => fail("expected Some")
    Some(code) => {
      if code != "let x = get_array()[0]" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_let_array_no_eq" {
  let result = @moonmacro.expand_builtin("let_array", "a, b, c")
  if result is Some(_) { fail("expected None without =") }
}

test "expand_builtin_let_array_no_vars" {
  let result = @moonmacro.expand_builtin("let_array", " = arr")
  if result is Some(_) { fail("expected None without vars") }
}

test "expand_builtin_let_array_start_zero" {
  match @moonmacro.expand_builtin("let_array", "a, b = xs, start: 0") {
    None => fail("expected Some")
    Some(code) => {
      if code != "let a = xs[0]; let b = xs[1]" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_call_each_simple" {
  match @moonmacro.expand_builtin("call_each", "m.add, a, b, bc") {
    None => fail("expected Some")
    Some(code) => {
      if code != "m.add(a); m.add(b); m.add(bc)" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_call_each_quoted_args" {
  let args = "m.add, \"a\", \"b\", \"bc\""
  match @moonmacro.expand_builtin("call_each", args) {
    None => fail("expected Some")
    Some(code) => {
      let expected = "m.add(\"a\"); m.add(\"b\"); m.add(\"bc\")"
      if code != expected { fail("unexpected: " + code + " expected: " + expected) }
    }
  }
}

test "expand_builtin_call_each_single_arg" {
  match @moonmacro.expand_builtin("call_each", "f, x") {
    None => fail("expected Some")
    Some(code) => {
      if code != "f(x)" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_call_each_no_args" {
  let result = @moonmacro.expand_builtin("call_each", "f")
  if result is Some(_) { fail("expected None without comma") }
}

test "expand_builtin_call_each_empty_args" {
  let result = @moonmacro.expand_builtin("call_each", "f,  ")
  if result is Some(_) { fail("expected None with only whitespace args") }
}

test "expand_builtin_call_each_multi_arg" {
  let args = "map.insert, (\"k1\", 1), (\"k2\", 2)"
  match @moonmacro.expand_builtin("call_each", args) {
    None => fail("expected Some")
    Some(code) => {
      let expected = "map.insert(\"k1\", 1); map.insert(\"k2\", 2)"
      if code != expected { fail("unexpected: " + code + " expected: " + expected) }
    }
  }
}

test "expand_builtin_call_each_mixed_arity_rejected" {
  let args = "f, a, (b, c), d"
  match @moonmacro.expand_builtin("call_each", args) {
    None => ()
    Some(_) => fail("expected None for mixed arity")
  }
}

test "expand_builtin_repeat_simple" {
  match @moonmacro.expand_builtin("repeat", "Array::make(4, 0), 4") {
    None => fail("expected Some")
    Some(code) => {
      let expected = "Array::make(4, 0), Array::make(4, 0), Array::make(4, 0), Array::make(4, 0)"
      if code != expected { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_repeat_twice" {
  match @moonmacro.expand_builtin("repeat", "42, 2") {
    None => fail("expected Some")
    Some(code) => {
      if code != "42, 42" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_repeat_custom_sep" {
  match @moonmacro.expand_builtin("repeat", "x, 3, +") {
    None => fail("expected Some")
    Some(code) => {
      if code != "x+x+x" { fail("unexpected code: [" + code + "]") }
    }
  }
}

test "expand_builtin_repeat_once" {
  match @moonmacro.expand_builtin("repeat", "hello, 1") {
    None => fail("expected Some")
    Some(code) => {
      if code != "hello" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_repeat_zero" {
  let result = @moonmacro.expand_builtin("repeat", "x, 0")
  if result is Some(_) { fail("expected None for count 0") }
}

test "expand_builtin_repeat_negative" {
  let result = @moonmacro.expand_builtin("repeat", "x, -1")
  if result is Some(_) { fail("expected None for negative count") }
}

test "expand_builtin_repeat_no_count" {
  let result = @moonmacro.expand_builtin("repeat", "x")
  if result is Some(_) { fail("expected None without count") }
}

test "expand_builtin_call_each_triple_arg" {
  let args = "f, (1, 2, 3), (4, 5, 6)"
  match @moonmacro.expand_builtin("call_each", args) {
    None => fail("expected Some")
    Some(code) => {
      if code != "f(1, 2, 3); f(4, 5, 6)" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_inspect_simple" {
  match @moonmacro.expand_builtin("inspect", "x, \"abc\"") {
    None => fail("expected Some")
    Some(code) => {
      if code != "@debug.debug_inspect(x, content=\"abc\")" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_inspect_with_func_call" {
  match @moonmacro.expand_builtin("inspect", "m.get(\"C\"), \"Some(1)\"") {
    None => fail("expected Some")
    Some(code) => {
      if code != "@debug.debug_inspect(m.get(\"C\"), content=\"Some(1)\")" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_inspect_no_comma" {
  let result = @moonmacro.expand_builtin("inspect", "x")
  if result is Some(_) { fail("expected None without comma") }
}

test "expand_builtin_echo_simple" {
  match @moonmacro.expand_builtin("echo", "x") {
    None => fail("expected Some")
    Some(code) => {
      if code != "println(\"x = \\{x}\")" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_echo_multi" {
  match @moonmacro.expand_builtin("echo", "x, y") {
    None => fail("expected Some")
    Some(code) => {
      if code != "println(\"x = \\{x}, y = \\{y}\")" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_echo_three" {
  match @moonmacro.expand_builtin("echo", "a, b, c") {
    None => fail("expected Some")
    Some(code) => {
      if code != "println(\"a = \\{a}, b = \\{b}, c = \\{c}\")" { fail("unexpected: " + code) }
    }
  }
}

test "expand_builtin_echo_empty" {
  let result = @moonmacro.expand_builtin("echo", "  ")
  if result is Some(_) { fail("expected None for whitespace-only") }
}

test "expand_builtin_logger_simple" {
  match @moonmacro.expand_builtin("logger", "fn foo() {\n  bar()\n}") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("entering foo") is None { fail("missing entering: " + code) }
      if code.find("leaving foo") is None { fail("missing leaving: " + code) }
      if code.find("defer") is None { fail("missing defer: " + code) }
      if code.find("entering foo") <= code.find("defer") { fail("defer must come before entering: " + code) }
    }
  }
}

test "expand_builtin_logger_empty_body" {
  match @moonmacro.expand_builtin("logger", "fn empty() {}") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("entering empty") is None { fail("missing entering: " + code) }
      if code.find("leaving empty") is None { fail("missing leaving: " + code) }
    }
  }
}

test "expand_builtin_logger_with_ret" {
  match @moonmacro.expand_builtin("logger", "fn add(x: Int, y: Int) -> Int {\n  x + y\n}") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("entering add") is None { fail("missing entering: " + code) }
      if code.find("leaving add") is None { fail("missing leaving: " + code) }
    }
  }
}

test "expand_builtin_logger_not_fn" {
  let result = @moonmacro.expand_builtin("logger", "let x = 42")
  if result is Some(_) { fail("expected None for non-fn") }
}

test "expand_builtin_timeit_simple" {
  match @moonmacro.expand_builtin("timeit", "fn foo() {\n  bar()\n}") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("@env.now()") is None { fail("missing @env.now(): " + code) }
      if code.find("__timeit_start") is None { fail("missing __timeit_start: " + code) }
      if code.find("defer") is None { fail("missing defer: " + code) }
      if code.find("took") is None { fail("missing took: " + code) }
    }
  }
}

test "expand_builtin_timeit_empty_body" {
  match @moonmacro.expand_builtin("timeit", "fn empty() {}") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("@env.now()") is None { fail("missing @env.now(): " + code) }
      if code.find("empty took") is None { fail("missing func name in msg: " + code) }
    }
  }
}

test "expand_builtin_timeit_not_fn" {
  let result = @moonmacro.expand_builtin("timeit", "let x = 42")
  if result is Some(_) { fail("expected None for non-fn") }
}

test "expand_builtin_tryn_simple" {
  match @moonmacro.expand_builtin("tryn", "get_val(), 3") {
    None => fail("expected Some")
    Some(code) => {
      if code.find("__tryn_max = 3") is None { fail("missing max: " + code) }
      if code.find("loop") is None { fail("missing loop: " + code) }
      if code.find("break None") is None { fail("missing break None: " + code) }
      if code.find("get_val()") is None { fail("missing get_val: " + code) }
      if code.find("__tryn_cur is Some(_)") is None { fail("missing Some check: " + code) }
    }
  }
}

test "expand_builtin_tryn_wrong_arg_count" {
  let result = @moonmacro.expand_builtin("tryn", "get_val()")
  if result is Some(_) { fail("expected None for 1 arg") }
  let result2 = @moonmacro.expand_builtin("tryn", "a, b, c")
  if result2 is Some(_) { fail("expected None for 3 args") }
}

test "find_derive_defs_simple" {
  let source = "macro_derive! MyMarker {\n  pub fn $T::is_active(self: $T) -> Bool { true }\n}"
  let defs = @moonmacro.find_derive_defs(source)
  if defs.length() != 1 { fail("expected 1 def, got " + defs.length().to_string()) }
  if defs[0].name != "MyMarker" { fail("expected MyMarker, got " + defs[0].name) }
  if defs[0].template.find("$T") is None { fail("expected $T in template, got: " + defs[0].template) }
}

test "find_derive_defs_multiple" {
  let source = "macro_derive! A { hi }\nmacro_derive! B { bye }"
  let defs = @moonmacro.find_derive_defs(source)
  if defs.length() != 2 { fail("expected 2 defs, got " + defs.length().to_string()) }
  if defs[0].name != "A" { fail("expected A") }
  if defs[1].name != "B" { fail("expected B") }
}

test "expand_derive_template_substitutes_T" {
  let t = @moonmacro.expand_derive_template("pub fn $T::new() -> $T { $T::default() }", "Point", "struct", "", "{}")
  if t.find("Point::new") is None { fail("expected Point::new, got: " + t) }
  if t.find("-> Point") is None { fail("expected -> Point, got: " + t) }
  if t.find("Point::default") is None { fail("expected Point::default, got: " + t) }
}

test "expand_derive_template_substitutes_type" {
  let t = @moonmacro.expand_derive_template("$type", "MyStruct", "struct", "", "{ x: Int }")
  if t != "MyStruct" { fail("expected MyStruct, got: " + t) }
}

test "expand_derive_template_substitutes_body" {
  let t = @moonmacro.expand_derive_template("fields: $body", "Point", "struct", "", "{ x: Int, y: Int }")
  if t.find("{ x: Int, y: Int }") is None { fail("expected body, got: " + t) }
}

test "expand_derive_template_substitutes_kind" {
  let t = @moonmacro.expand_derive_template("it is a $kind", "Foo", "enum", "", "{ A }")
  if t != "it is a enum" { fail("expected 'it is a enum', got: " + t) }
}

test "expand_derive_template_substitutes_generics" {
  let t = @moonmacro.expand_derive_template("$T$generics", "Wrap", "struct", "[T]", "{ value: T }")
  if t != "Wrap[T]" { fail("expected Wrap[T], got: " + t) }
}

test "expand_derive_template_substitutes_Name" {
  let t = @moonmacro.expand_derive_template("$Name", "my_type", "struct", "", "{}")
  if t != "My_type" { fail("expected My_type, got: " + t) }
}

test "expand_derive_template_unknown_escape" {
  let t = @moonmacro.expand_derive_template("$x + $y", "Foo", "struct", "", "{}")
  if t != "$x + $y" { fail("expected literal $x + $y, got: " + t) }
}

test "generate_derives_uses_custom_derive" {
  let custom = [@moonmacro.DeriveDef::{ name: "MyTrait", template: "pub fn $T::extra() -> Int { 42 }" }]
  let result = @moonmacro.generate_derives(["MyTrait"], "Point", "struct", "", "{}", custom)
  if result.find("Point::extra") is None { fail("expected Point::extra, got: " + result) }
  if result.find("extra() -> Int") is None { fail("expected extra method, got: " + result) }
  if result.find("unknown derive") is None {  }
}

test "generate_derives_custom_fallback_to_builtin_then_unknown" {
  let custom = [@moonmacro.DeriveDef::{ name: "CustomTrait", template: "// custom" }]
  let result = @moonmacro.generate_derives(["Constructor", "CustomTrait", "NoExist"], "Point", "struct", "", "{ x: Int }", custom)
  if result.find("Point::new") is None { fail("expected Constructor output") }
  if result.find("// custom") is None { fail("expected custom output") }
  if result.find("unknown derive: NoExist") is None { fail("expected unknown message") }
}

test "expand_derive_template_substitutes_fields" {
  let t = @moonmacro.expand_derive_template("($fields)", "Point", "struct", "", "{ x: Int, y: Int }")
  if t != "(x, y)" { fail("expected (x, y), got: " + t) }
}

test "expand_derive_template_substitutes_field_types" {
  let t = @moonmacro.expand_derive_template("($field_types)", "Point", "struct", "", "{ x: Int, y: String }")
  if t != "(Int, String)" { fail("expected (Int, String), got: " + t) }
}

test "expand_derive_template_substitutes_variants" {
  let t = @moonmacro.expand_derive_template("[$variants]", "Color", "enum", "", "{ Red, Green, Blue }")
  if t != "[Red, Green, Blue]" { fail("expected [Red, Green, Blue], got: " + t) }
}

test "expand_derive_template_fields_empty_for_enum" {
  let t = @moonmacro.expand_derive_template("f($fields) t($field_types)", "Color", "enum", "", "{ Red, Green }")
  if t != "f() t()" { fail("expected empty fields/types for enum, got: " + t) }
}

test "expand_derive_template_enum_field_types_parenthesized" {
  let t = @moonmacro.expand_derive_template("types($field_types)", "Result", "enum", "", "{ Ok(Int), Err(String) }")
  if t != "types(Int, String)" { fail("expected types(Int, String), got: " + t) }
}

test "expand_derive_template_enum_field_types_multi_field" {
  let t = @moonmacro.expand_derive_template("[$field_types]", "Expr", "enum", "", "{ Lit(Int), Add(Expr, Expr), Mul(Expr, Expr) }")
  if t != "[Int, Expr, Expr, Expr, Expr]" { fail("expected all types, got: " + t) }
}

test "expand_derive_template_enum_field_types_record" {
  let t = @moonmacro.expand_derive_template("($field_types)", "Node", "enum", "", "{ Int { value: Int, label: String } }")
  if t != "(Int, String)" { fail("expected field types from record, got: " + t) }
}

test "expand_derive_template_variants_empty_for_struct" {
  let t = @moonmacro.expand_derive_template("v($variants)", "Point", "struct", "", "{ x: Int }")
  if t != "v()" { fail("expected empty variants for struct, got: " + t) }
}

test "generate_derives_allmeta_uses_all_vars" {
  let custom = [@moonmacro.DeriveDef::{ name: "AllMeta", template: "pub fn $T::type_name() -> String { \"$T\" }\npub fn $T::kind() -> String { \"$kind\" }\npub fn $T::generics_str() -> String { \"$generics\" }\npub fn $T::fields_str() -> String { \"$fields\" }\npub fn $T::field_types_str() -> String { \"$field_types\" }\npub fn $T::variants_str() -> String { \"$variants\" }\npub fn $T::body_str() -> String { \"$body\" }\npub fn $T::display_name() -> String { \"$Name\" }" }]
  let result = @moonmacro.generate_derives(["AllMeta"], "Point", "struct", "[T]", "{ x: T, y: T }", custom)
  if result.find("Point::type_name") is None { fail("expected type_name") }
  if result.find("\"Point\"") is None { fail("expected $T substitution") }
  if result.find("struct") is None { fail("expected $kind") }
  if result.find("[T]") is None { fail("expected $generics") }
  if result.find("x, y") is None { fail("expected $fields") }
  if result.find("T, T") is None { fail("expected $field_types") }
  if result.find("Point::variants_str") is None { fail("expected variants_str") }
  if result.find("$variants") is Some(_) { fail("$variants should be substituted") }
  if result.find("x: T, y: T") is None { fail("expected $body") }
  if result.find("Point") is None { fail("expected $Name") }
}

test "generate_derives_fullinfo_struct" {
  let custom = [@moonmacro.DeriveDef::{ name: "FullInfo", template: "pub fn $T::full_name() -> String { \"$kind $T$generics\" }" }]
  let result = @moonmacro.generate_derives(["FullInfo"], "Vec", "struct", "[T]", "{ items: Array[T] }", custom)
  if result.find("struct Vec[T]") is None { fail("expected 'struct Vec[T]', got: " + result) }
}

test "generate_derives_enummeta_enum" {
  let custom = [@moonmacro.DeriveDef::{ name: "EnumMeta", template: "pub fn $T::variant_names() -> String { \"$variants\" }" }]
  let result = @moonmacro.generate_derives(["EnumMeta"], "Color", "enum", "", "{ Red, Green, Blue }", custom)
  if result.find("\"Red, Green, Blue\"") is None { fail("expected variants, got: " + result) }
}

test "generate_derives_structinfo_struct" {
  let custom = [@moonmacro.DeriveDef::{ name: "StructInfo", template: "pub fn $T::field_names() -> Array[String] { [\"$fields\"] }" }]
  let result = @moonmacro.generate_derives(["StructInfo"], "Point", "struct", "", "{ x: Int, y: Int }", custom)
  if result.find("[\"x, y\"]") is None { fail("expected field array, got: " + result) }
}

test "generate_derives_showtype_struct" {
  let custom = [@moonmacro.DeriveDef::{ name: "ShowType", template: "pub fn $T::show_type() -> String { \"$kind $T$generics\" }" }]
  let result = @moonmacro.generate_derives(["ShowType"], "Wrap", "struct", "", "{ value: Int }", custom)
  if result.find("\"struct Wrap\"") is None { fail("expected 'struct Wrap', got: " + result) }
}

test "no_expand_in_string" {
  let source = "macro_rules! greet { ($n:expr) => { fn greet_$n() {} } }\nprintln(\"hello greet!(World)\")"
  let defs = @moonmacro.find_macro_defs(source)
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 0 { fail("expected 0 invocations (all inside string), got " + invs.length().to_string()) }
  let result = @moonmacro.expand_file(source, defs)
  if result.find("fn greet_World") is Some(_) { fail("greet! inside string should NOT be expanded, got: " + result) }
  if result.find("println(\"hello greet!(World)\")") is None { fail("greet! inside string should remain intact, got: " + result) }
}

test "no_expand_in_comment" {
  let source = "macro_rules! greet { ($n:expr) => { fn greet_$n() {} } }\n// greet!(World)"
  let defs = @moonmacro.find_macro_defs(source)
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 0 { fail("expected 0 invocations (all in comment), got " + invs.length().to_string()) }
}

test "no_expand_in_multiline_string" {
  let source = "macro_rules! greet { ($n:expr) => { fn greet_$n() {} } }\n#| greet!(World) |#"
  let defs = @moonmacro.find_macro_defs(source)
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 0 { fail("expected 0 invocations (all in multiline string), got " + invs.length().to_string()) }
}

test "no_expand_in_dollar_multiline_string" {
  let source = "macro_rules! greet { ($n:expr) => { fn greet_$n() {} } }\n$| greet!(World) |#"
  let defs = @moonmacro.find_macro_defs(source)
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 0 { fail("expected 0 invocations (all in $| multiline string), got " + invs.length().to_string()) }
}

test "expand_outside_string_only" {
  let source = "macro_rules! greet { ($n:expr) => { fn greet_$n() {} } }\nprintln(\"hi greet!(World)\")\ngreet!(World)"
  let defs = @moonmacro.find_macro_defs(source)
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { fail("expected 1 invocation (outside string), got " + invs.length().to_string()) }
  let result = @moonmacro.expand_file(source, defs)
  if result.find("fn greet_World") is None { fail("expect greet_World expansion, got: " + result) }
  if result.find("println(\"hi greet!(World)\")") is None { fail("string should be unchanged, got: " + result) }
}

test "generate_derive_enum_from_str_generic" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Opt", "enum", "[T]", "{\n  Some(T)\n  None\n}", [])
  if result.find("pub fn Opt::from_string[T]") is None { fail("expected generic from_string, got: " + result) }
  if result.find("-> Opt[T]?") is None { fail("expected Opt[T]? return, got: " + result) }
  if result.find("\"None\" => Some(Opt::None)") is None { fail("expected None match, got: " + result) }
  if result.find("\"Some\"") is Some(_) { fail("should not match data variant Some, got: " + result) }
}

test "generate_derive_enum_from_str_many_variants" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Digits", "enum", "", "{\n  Zero\n  One\n  Two\n  Three\n  Four\n  Five\n  Six\n  Seven\n  Eight\n  Nine\n  Ten\n}", [])
  if result.find("pub fn Digits::from_string") is None { fail("expected from_string") }
  if result.find("\"Zero\" => Some(Digits::Zero)") is None { fail("expected Zero, got: " + result) }
  if result.find("\"Nine\" => Some(Digits::Nine)") is None { fail("expected Nine, got: " + result) }
  if result.find("\"Ten\" => Some(Digits::Ten)") is None { fail("expected Ten, got: " + result) }
  if result.find("_ => None") is None { fail("expected fallback, got: " + result) }
}

test "generate_derive_enum_from_str_empty_enum" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Empty", "enum", "", "{\n}", [])
  if result.find("requires at least one unit variant") is None { fail("expected error for empty enum, got: " + result) }
}

test "generate_derive_enum_from_str_stacked_with_constructor" {
  let source = "#[macro_derive(Constructor)]\n#[macro_derive(EnumFromStr)]\nenum Status {\n  Active\n  Inactive\n}\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result.find("pub fn Status::new") is Some(_) { fail("Constructor should not apply to enum, got: " + result) }
  if result.find("pub fn Status::from_string") is None { fail("expected from_string, got: " + result) }
  if result.find("\"Active\" => Some(Status::Active)") is None { fail("expected Active match, got: " + result) }
  if result.find("\"Inactive\" => Some(Status::Inactive)") is None { fail("expected Inactive match, got: " + result) }
}

test "generate_derive_enum_from_str_data_with_mixed_types" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Expr", "enum", "", "{\n  Int(Int)\n  Add(Expr, Expr)\n  Mul(Expr, Expr)\n  Zero\n  One\n}", [])
  if result.find("pub fn Expr::from_string") is None { fail("expected from_string") }
  if result.find("\"Zero\" => Some(Expr::Zero)") is None { fail("expected Zero match, got: " + result) }
  if result.find("\"One\" => Some(Expr::One)") is None { fail("expected One match, got: " + result) }
  if result.find("\"Int\"") is Some(_) { fail("should not match data variant Int, got: " + result) }
  if result.find("\"Add\"") is Some(_) { fail("should not match data variant Add, got: " + result) }
  if result.find("\"Mul\"") is Some(_) { fail("should not match data variant Mul, got: " + result) }
}

test "generate_derive_enum_from_str_trailing_semicolon" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Color", "enum", "", "{ Red; Green; Blue; }", [])
  if result.find("pub fn Color::from_string") is None { fail("expected from_string") }
  if result.find("\"Red\" => Some(Color::Red)") is None { fail("expected Red, got: " + result) }
  if result.find("\"Green\" => Some(Color::Green)") is None { fail("expected Green, got: " + result) }
  if result.find("\"Blue\" => Some(Color::Blue)") is None { fail("expected Blue, got: " + result) }
}

test "generate_derive_enum_from_str_complex_generic" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Either", "enum", "[L, R]", "{\n  Left(L)\n  Right(R)\n  Both(L, R)\n  Neither\n}", [])
  if result.find("pub fn Either::from_string[L, R]") is None { fail("expected generic from_string, got: " + result) }
  if result.find("-> Either[L, R]?") is None { fail("expected Either[L, R]? return, got: " + result) }
  if result.find("\"Neither\" => Some(Either::Neither)") is None { fail("expected Neither match, got: " + result) }
  if result.find("\"Left\"") is Some(_) { fail("should not match data variant Left, got: " + result) }
  if result.find("\"Right\"") is Some(_) { fail("should not match data variant Right, got: " + result) }
  if result.find("\"Both\"") is Some(_) { fail("should not match data variant Both, got: " + result) }
}

test "generate_derive_enum_from_str_record_variants" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Event", "enum", "", "{\n  Click { x: Int; y: Int }\n  KeyPress(String)\n  Resize\n  Close\n}", [])
  if result.find("pub fn Event::from_string") is None { fail("expected from_string") }
  if result.find("\"Resize\" => Some(Event::Resize)") is None { fail("expected Resize match, got: " + result) }
  if result.find("\"Close\" => Some(Event::Close)") is None { fail("expected Close match, got: " + result) }
  if result.find("\"Click\"") is Some(_) { fail("should not match record variant Click, got: " + result) }
  if result.find("\"KeyPress\"") is Some(_) { fail("should not match data variant KeyPress, got: " + result) }
}
