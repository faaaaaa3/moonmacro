test "find_macro_defs" {
  let source = "macro_rules! foo { ($x:expr) => { $x } }"
  let defs = @moonmacro.find_macro_defs(source)
  if defs.length() != 1 { abort("expected 1 def, got " + defs.length().to_string()) }
  if defs[0].name != "foo" { abort("expected name foo, got " + defs[0].name) }
  if defs[0].patterns.length() != 1 { abort("expected 1 rule") }
}

test "find_macro_defs_multiple" {
  let source = "macro_rules! a { ($x:expr) => { $x } } macro_rules! b { ($y:expr) => { $y } }"
  let defs = @moonmacro.find_macro_defs(source)
  if defs.length() != 2 { abort("expected 2 defs") }
  if defs[0].name != "a" { abort("expected name a") }
  if defs[1].name != "b" { abort("expected name b") }
}

test "find_macro_invocations" {
  let source = "greet!(World)"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { abort("expected 1 invocation") }
  match invs[0] {
    @moonmacro.FuncCall(name, args, delim, _s, _e) => {
      if name != "greet" { abort("expected name greet") }
      if args != "World" { abort("expected args World") }
      if delim != "(" { abort("expected delim (") }
    }
    _ => abort("expected FuncCall")
  }
}

test "find_bracket_invocation" {
  let source = "name![1, 2, 3]"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { abort("expected 1 invocation") }
  match invs[0] {
    @moonmacro.FuncCall(name, args, delim, _s, _e) => {
      if name != "name" { abort("expected name name") }
      if args != "1, 2, 3" { abort("expected args") }
      if delim != "[" { abort("expected delim [") }
    }
    _ => abort("expected FuncCall")
  }
}

test "parse_pattern_simple" {
  let frags = @moonmacro.parse_pattern("$x:expr")
  if frags.length() != 1 { abort("expected 1 fragment") }
  match frags[0] {
    @moonmacro.Capture(name, kind) => {
      if name != "x" { abort("expected name x") }
      if kind != "expr" { abort("expected kind expr") }
    }
    _ => abort("expected Capture")
  }
}

test "parse_pattern_repetition" {
  let frags = @moonmacro.parse_pattern("$($x:expr),*")
  if frags.length() != 1 { abort("expected 1 fragment (Repetition)") }
  match frags[0] {
    @moonmacro.Repetition(_inner, sep, _op) => {
      if sep != "," { abort("expected sep ','") }
    }
    _ => abort("expected Repetition")
  }
}

test "parse_pattern_mixed" {
  let frags = @moonmacro.parse_pattern("[$($x:expr),*]")
  if frags.length() != 3 { abort("expected 3 fragments, got " + frags.length().to_string()) }
  match frags[0] {
    @moonmacro.Lit(s) => { if s != "[" { abort("expected Lit '['") } }
    _ => abort("expected Lit")
  }
  match frags[1] {
    @moonmacro.Repetition(_inner, _sep, _op) => ()
    _ => abort("expected Repetition")
  }
  match frags[2] {
    @moonmacro.Lit(s) => { if s != "]" { abort("expected Lit ']'") } }
    _ => abort("expected Lit")
  }
}

test "match_simple" {
  let matched = @moonmacro.match_pattern("$x:expr", "42")
  match matched {
    None => abort("expected match")
    Some(captures) => {
      if !captures.contains("x") { abort("expected capture x") }
      if captures["x"][0] != "42" { abort("expected '42'") }
    }
  }
}

test "match_repetition" {
  let matched = @moonmacro.match_pattern("$($x:expr),*", "1, 2, 3")
  match matched {
    None => abort("expected match")
    Some(captures) => {
      if captures["x"].length() != 3 { abort("expected 3 captures") }
      if captures["x"][0] != "1" { abort("expected '1'") }
      if captures["x"][1] != "2" { abort("expected '2'") }
      if captures["x"][2] != "3" { abort("expected '3'") }
    }
  }
}

test "match_repetition_single" {
  let matched = @moonmacro.match_pattern("$($x:expr),*", "42")
  match matched {
    None => abort("expected match")
    Some(captures) => {
      if captures["x"].length() != 1 { abort("expected 1 capture") }
      if captures["x"][0] != "42" { abort("expected '42'") }
    }
  }
}

test "match_multi_capture_with_brackets" {
  let matched = @moonmacro.match_pattern("[$x:expr] rest $y:expr", "[42] rest hello")
  match matched {
    None => abort("expected match")
    Some(captures) => {
      if captures["x"][0] != "42" { abort("expected x='42'") }
      if captures["y"][0] != "hello" { abort("expected y='hello'") }
    }
  }
}

test "match_multi_capture_with_literal" {
  let matched = @moonmacro.match_pattern("$x:expr + $y:expr", "1 + 2")
  match matched {
    None => abort("expected match")
    Some(captures) => {
      if !captures.contains("x") { abort("expected x") }
      if !captures.contains("y") { abort("expected y") }
      if captures["x"][0] != "1" { abort("expected x='1'") }
      if captures["y"][0] != "2" { abort("expected y='2'") }
    }
  }
}

test "match_repetition_empty" {
  let matched = @moonmacro.match_pattern("$($x:expr),*", "")
  match matched {
    None => abort("expected match for empty input")
    Some(captures) => {
      if captures["x"].length() != 0 { abort("expected 0 captures") }
    }
  }
}

test "expand_simple" {
  let captures : Map[String, Array[String]] = { "x": ["42"] }
  let result = @moonmacro.expand_template("result = $x", captures)
  if result != "result = 42" { abort("expected 'result = 42'") }
}

test "expand_repetition_template" {
  let captures : Map[String, Array[String]] = { "x": ["1", "2", "3"] }
  let result = @moonmacro.expand_template("[$($x),*]", captures)
  if result != "[1,2,3]" { abort("expected '[1,2,3]'") }
}

test "expand_macro_call" {
  let source = "macro_rules! double { ($x:expr) => { $x * 2 } }"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_macro_call("double", "21", defs)
  match result {
    None => abort("expected Some")
    Some(code) => {
      let trimmed = code.trim().to_owned()
      if trimmed != "21 * 2" { abort("expected '21 * 2'") }
    }
  }
}

test "expand_file" {
  let source = "macro_rules! greet { ($name:expr) => { fn greet_$name() {} } }\ngreet!(World)\n"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_file(source, defs)
  if result.find("greet_World") is None { abort("expected greet_World in output") }
  if result.find("macro_rules!") is None { abort("expected macro_rules! preserved") }
}

test "expand_builtin_stringify" {
  match @moonmacro.expand_builtin("stringify", "hello") {
    None => abort("expected Some")
    Some(code) => if code != "\"hello\"" { abort("expected '\"hello\"'") }
  }
}

test "expand_builtin_unknown" {
  let result = @moonmacro.expand_builtin("nope", "args")
  if result is Some(_) { abort("expected None for unknown builtin") }
}

test "find_derive_invocation" {
  let source = "#[macro_derive(Constructor)]\nstruct Point { x: Int, y: Int }\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { abort("expected 1 invocation") }
  match invs[0] {
    @moonmacro.Derive(traits, name, kind, _generics, _body, _s, _e) => {
      if traits.length() != 1 { abort("expected 1 trait, got " + traits.length().to_string()) }
      if traits[0] != "Constructor" { abort("expected Constructor, got " + traits[0]) }
      if name != "Point" { abort("expected Point") }
      if kind != "struct" { abort("expected struct") }
    }
    _ => abort("expected Derive")
  }
}

test "derive_with_braces" {
  let source = "#[macro_derive(Constructor)]\nstruct Point {\n  x: Int\n  y: Int\n}"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { abort("expected 1 invocation") }
  match invs[0] {
    @moonmacro.Derive(_traits, name, _kind, _generics, body, _s, _e) => {
      if name != "Point" { abort("expected Point") }
      if body.find("x: Int") is None { abort("body should contain x: Int") }
    }
    _ => abort("expected Derive")
  }
}

test "generate_derive_constructor" {
  let result = @moonmacro.generate_derives(["Constructor"], "Point", "struct", "", "{ x: Int, y: Int }")
  if result.find("pub fn Point::new") is None { abort("expected Point::new, got: " + result) }
  if result.find("x: Int, y: Int") is None { abort("expected params") }
  if result.find("{ x, y }") is None { abort("expected struct literal") }
}

test "generate_derive_constructor_generic" {
  let result = @moonmacro.generate_derives(["Constructor"], "Pair", "struct", "[T]", "{ first: T, second: T }")
  if result.find("pub fn Pair::new[T]") is None { abort("expected Pair::new[T]") }
  if result.find("first: T, second: T") is None { abort("expected typed params") }
  if result.find("-> Pair[T]") is None { abort("expected Pair[T] return") }
}

test "generate_derive_getters" {
  let result = @moonmacro.generate_derives(["Getters"], "Point", "struct", "", "{ x: Int, y: String }")
  if result.find("pub fn Point::X") is None { abort("expected getter X (PascalCase), got: " + result) }
  if result.find("pub fn Point::Y") is None { abort("expected getter Y") }
  if result.find("self: Point") is None { abort("expected self param") }
  if result.find("-> Int") is None { abort("expected Int return") }
  if result.find("-> String") is None { abort("expected String return") }
  if result.find("self.x") is None { abort("expected self.x body") }
}

test "generate_derive_enum_from_str" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Color", "enum", "", "{\n  Red\n  Green\n}")
  if result.find("pub fn Color::from_string") is None { abort("expected from_string") }
  if result.find("\"Red\" => Some(Red)") is None { abort("expected Red match") }
  if result.find("\"Green\" => Some(Green)") is None { abort("expected Green match") }
  if result.find("_ => None") is None { abort("expected fallback") }
  if result.find("-> Color?") is None { abort("expected Color? return") }
}

test "generate_derive_enum_from_str_skips_data_variants" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Expr", "enum", "", "{\n  Int(Int)\n  Add(Expr, Expr)\n}")
  if result.find("// EnumFromStr requires") is None { abort("expected error for no unit variants") }
}

test "stacked_derive_same_struct" {
  let source = "#[macro_derive(Constructor)]\n#[macro_derive(Constructor)]\nstruct Point { x: Int }\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { abort("expected 1 invocation, got " + invs.length().to_string()) }
  match invs[0] {
    @moonmacro.Derive(traits, name, _kind, _generics, _body, _s, _e) => {
      if traits.length() != 2 { abort("expected 2 merged traits, got " + traits.length().to_string()) }
      if traits[0] != "Constructor" { abort("expected Constructor") }
      if traits[1] != "Constructor" { abort("expected Constructor") }
      if name != "Point" { abort("expected Point") }
    }
    _ => abort("expected Derive")
  }
}

test "generate_derive_constructor_kind_error" {
  let result = @moonmacro.generate_derives(["Constructor"], "Color", "enum", "", "{ Red; Green }")
  if result.find("only supports structs") is None { abort("expected error for enum") }
}

test "generate_derive_getters_kind_error" {
  let result = @moonmacro.generate_derives(["Getters"], "Color", "enum", "", "{ Red; Green }")
  if result.find("only supports structs") is None { abort("expected error for enum") }
}

test "generate_derive_enum_from_str_kind_error" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Point", "struct", "", "{ x: Int }")
  if result.find("only supports enums") is None { abort("expected error for struct") }
}

test "expand_builtin_matches" {
  match @moonmacro.expand_builtin("matches", "x, Some(y)") {
    None => abort("expected Some")
    Some(code) => {
      if code.find("match x") is None { abort("expected match x") }
      if code.find("Some(y) => true") is None { abort("expected pattern match") }
    }
  }
}

test "expand_builtin_todo" {
  match @moonmacro.expand_builtin("todo", "") {
    None => abort("expected Some")
    Some(code) => if code != "abort(\"not implemented\")" { abort("expected 'not implemented'") }
  }
}

test "expand_builtin_todo_with_message" {
  // args from source todo!("fix this") includes surrounding quotes
  match @moonmacro.expand_builtin("todo", "\"fix this\"") {
    None => abort("expected Some")
    Some(code) => if code != "abort(\"fix this\")" { abort("expected abort with message") }
  }
}

test "expand_file_nested" {
  let source = "macro_rules! double { ($x:expr) => { $x * 2 } }\nmacro_rules! apply { ($f:expr) => { double!($f) } }\napply!(21)\n"
  let defs = @moonmacro.find_macro_defs(source)
  let result = @moonmacro.expand_file(source, defs)
  if result.find("21 * 2") is None { abort("expected 21 * 2 after nested expansion") }
  if result.find("double!") is Some(_) { abort("double! should be expanded away") }
}

test "no_matches" {
  let source = "fn main { println(\"hello\") }"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 0 { abort("expected 0 invocations, got " + invs.length().to_string()) }
}

test "expand_builtin_dbg_simple" {
  match @moonmacro.expand_builtin("dbg", "x") {
    None => abort("expected Some")
    Some(code) => {
      if code.find("let __dbg_val = x") is None { abort("expected var binding, got: " + code) }
      if code.find("stringify!(x)") is None { abort("expected stringify!(x)") }
      if code.find("__dbg_val.to_string()") is None { abort("expected to_string call") }
      if code.find("__dbg_val") is None { abort("expected __dbg_val") }
    }
  }
}

test "expand_builtin_dbg_complex_expr" {
  match @moonmacro.expand_builtin("dbg", "foo(1, 2) + bar[baz]") {
    None => abort("expected Some")
    Some(code) => {
      if code.find("let __dbg_val = foo(1, 2) + bar[baz]") is None { abort("expected full expr, got: " + code) }
      if code.find("stringify!(foo(1, 2) + bar[baz])") is None { abort("expected stringify with brackets, got: " + code) }
    }
  }
}

test "expand_builtin_dbg_empty" {
  match @moonmacro.expand_builtin("dbg", "") {
    None => abort("expected Some")
    Some(code) => {
      if code.find("let __dbg_val = ") is None { abort("expected empty var binding") }
    }
  }
}

test "find_macro_defs_empty" {
  let source = ""
  let defs = @moonmacro.find_macro_defs(source)
  if defs.length() != 0 { abort("expected 0 defs") }
}

test "find_macro_defs_no_macros" {
  let source = "fn main { println(\"hello\") }"
  let defs = @moonmacro.find_macro_defs(source)
  if defs.length() != 0 { abort("expected 0 defs") }
}

test "find_macro_invocations_nested_brackets" {
  let source = "foo!(bar[baz])"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { abort("expected 1 invocation") }
  match invs[0] {
    @moonmacro.FuncCall(name, args, delim, _s, _e) => {
      if name != "foo" { abort("expected name foo") }
      if args != "bar[baz]" { abort("expected args 'bar[baz]'") }
      if delim != "(" { abort("expected delim (") }
    }
    _ => abort("expected FuncCall")
  }
}

test "expand_builtin_assert" {
  match @moonmacro.expand_builtin("assert", "x > 0") {
    None => abort("expected Some")
    Some(code) => {
      if code.find("if !(x > 0)") is None { abort("expected condition") }
      if code.find("assertion failed: x > 0") is None { abort("expected message") }
    }
  }
}

test "expand_builtin_matches_no_comma" {
  let result = @moonmacro.expand_builtin("matches", "x Some(y)")
  if result is Some(_) { abort("expected None without comma") }
}

test "expand_builtin_stringify_empty" {
  match @moonmacro.expand_builtin("stringify", "") {
    None => abort("expected Some")
    Some(code) => if code != "\"\"" { abort("expected empty quotes") }
  }
}

test "expand_builtin_stringify_special" {
  match @moonmacro.expand_builtin("stringify", "a + b * c") {
    None => abort("expected Some")
    Some(code) => if code != "\"a + b * c\"" { abort("expected quoted, got: " + code) }
  }
}

test "generate_derive_constructor_single_field" {
  let result = @moonmacro.generate_derives(["Constructor"], "Wrap", "struct", "", "{ value: Int }")
  if result.find("pub fn Wrap::new") is None { abort("expected Wrap::new") }
  if result.find("value: Int") is None { abort("expected value: Int") }
  if result.find("{ value }") is None { abort("expected struct literal") }
}

test "generate_derive_constructor_empty_struct" {
  let result = @moonmacro.generate_derives(["Constructor"], "Empty", "struct", "", "{}")
  if result.find("requires at least one field") is None { abort("expected error for empty struct") }
}

test "generate_derive_constructor_mut_field" {
  let result = @moonmacro.generate_derives(["Constructor"], "Point", "struct", "", "{ mut x: Int, y: String }")
  if result.find("pub fn Point::new") is None { abort("expected Point::new") }
  if result.find("x: Int") is None { abort("expected x: Int param") }
  if result.find("{ x, y }") is None { abort("expected struct literal") }
}

test "generate_derive_getters_single_field" {
  let result = @moonmacro.generate_derives(["Getters"], "Wrap", "struct", "", "{ value: String }")
  if result.find("pub fn Wrap::Value") is None { abort("expected getter Value") }
  if result.find("self: Wrap") is None { abort("expected self param") }
  if result.find("-> String") is None { abort("expected String return") }
}

test "generate_derive_getters_empty_struct" {
  let result = @moonmacro.generate_derives(["Getters"], "Empty", "struct", "", "{}")
  if result.find("requires at least one field") is None { abort("expected error for empty struct") }
}

test "generate_derive_getters_generic" {
  let result = @moonmacro.generate_derives(["Getters"], "Wrap", "struct", "[T]", "{ value: T }")
  if result.find("pub fn Wrap::Value") is None { abort("expected getter Value") }
  if result.find("self: Wrap[T]") is None { abort("expected self: Wrap[T]") }
  if result.find("-> T") is None { abort("expected T return") }
  if result.find("self.value") is None { abort("expected self.value body") }
}

test "generate_derive_enum_from_str_single" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Status", "enum", "", "{\n  Active\n}")
  if result.find("pub fn Status::from_string") is None { abort("expected from_string") }
  if result.find("\"Active\" => Some(Active)") is None { abort("expected Active match") }
  if result.find("_ => None") is None { abort("expected fallback") }
}

test "generate_derive_enum_from_str_mixed" {
  let result = @moonmacro.generate_derives(["EnumFromStr"], "Expr", "enum", "", "{\n  Int(Int)\n  Add(Expr, Expr)\n  Zero\n}")
  if result.find("pub fn Expr::from_string") is None { abort("expected from_string") }
  if result.find("\"Zero\" => Some(Zero)") is None { abort("expected Zero match") }
  if result.find("\"Int\"") is Some(_) { abort("should not match Int (data variant)") }
}

test "separate_derive_on_different_structs" {
  let source = "#[macro_derive(Constructor)]\nstruct Point { x: Int }\n\n#[macro_derive(Getters)]\nstruct Wrap { value: String }"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 2 { abort("expected 2 separate invocations, got " + invs.length().to_string()) }
  match invs[0] {
    @moonmacro.Derive(traits, name, _kind, _generics, _body, _s, _e) => {
      if traits.length() != 1 { abort("expected 1 trait") }
      if name != "Point" { abort("expected Point") }
    }
    _ => abort("expected Derive for Point")
  }
  match invs[1] {
    @moonmacro.Derive(traits, name, _kind, _generics, _body, _s, _e) => {
      if traits[0] != "Getters" { abort("expected Getters") }
      if name != "Wrap" { abort("expected Wrap") }
    }
    _ => abort("expected Derive for Wrap")
  }
}

test "expand_builtin_unknown_case_sensitive" {
  let result = @moonmacro.expand_builtin("DBG", "x")
  if result is Some(_) { abort("expected None for wrong case") }
}

test "expand_file_no_change" {
  let source = "fn add(x: Int, y: Int) -> Int { x + y }"
  let defs : Array[@moonmacro.MacroDef] = []
  let result = @moonmacro.expand_file(source, defs)
  if result != source { abort("plain code should be unchanged") }
}

test "expand_builtin_let_array_simple" {
  match @moonmacro.expand_builtin("let_array", "a, b, c = arr") {
    None => abort("expected Some")
    Some(code) => {
      if code != "let a = arr[0]; let b = arr[1]; let c = arr[2]" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_let_array_mut" {
  match @moonmacro.expand_builtin("let_array", "mut a, mut b = state") {
    None => abort("expected Some")
    Some(code) => {
      if code != "let mut a = state[0]; let mut b = state[1]" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_let_array_mixed_mut" {
  match @moonmacro.expand_builtin("let_array", "mut a, b, mut c = data") {
    None => abort("expected Some")
    Some(code) => {
      if code != "let mut a = data[0]; let b = data[1]; let mut c = data[2]" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_let_array_with_start" {
  match @moonmacro.expand_builtin("let_array", "a, b = items, start: 3") {
    None => abort("expected Some")
    Some(code) => {
      if code != "let a = items[3]; let b = items[4]" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_let_array_single_var" {
  match @moonmacro.expand_builtin("let_array", "x = get_array()") {
    None => abort("expected Some")
    Some(code) => {
      if code != "let x = get_array()[0]" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_let_array_no_eq" {
  let result = @moonmacro.expand_builtin("let_array", "a, b, c")
  if result is Some(_) { abort("expected None without =") }
}

test "expand_builtin_let_array_no_vars" {
  let result = @moonmacro.expand_builtin("let_array", " = arr")
  if result is Some(_) { abort("expected None without vars") }
}

test "expand_builtin_let_array_start_zero" {
  match @moonmacro.expand_builtin("let_array", "a, b = xs, start: 0") {
    None => abort("expected Some")
    Some(code) => {
      if code != "let a = xs[0]; let b = xs[1]" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_call_each_simple" {
  match @moonmacro.expand_builtin("call_each", "m.add, a, b, bc") {
    None => abort("expected Some")
    Some(code) => {
      if code != "m.add(a); m.add(b); m.add(bc)" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_call_each_quoted_args" {
  let args = "m.add, \"a\", \"b\", \"bc\""
  match @moonmacro.expand_builtin("call_each", args) {
    None => abort("expected Some")
    Some(code) => {
      let expected = "m.add(\"a\"); m.add(\"b\"); m.add(\"bc\")"
      if code != expected { abort("unexpected: " + code + " expected: " + expected) }
    }
  }
}

test "expand_builtin_call_each_single_arg" {
  match @moonmacro.expand_builtin("call_each", "f, x") {
    None => abort("expected Some")
    Some(code) => {
      if code != "f(x)" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_call_each_no_args" {
  let result = @moonmacro.expand_builtin("call_each", "f")
  if result is Some(_) { abort("expected None without comma") }
}

test "expand_builtin_call_each_empty_args" {
  let result = @moonmacro.expand_builtin("call_each", "f,  ")
  if result is Some(_) { abort("expected None with only whitespace args") }
}

test "expand_builtin_call_each_multi_arg" {
  let args = "map.insert, (\"k1\", 1), (\"k2\", 2)"
  match @moonmacro.expand_builtin("call_each", args) {
    None => abort("expected Some")
    Some(code) => {
      let expected = "map.insert(\"k1\", 1); map.insert(\"k2\", 2)"
      if code != expected { abort("unexpected: " + code + " expected: " + expected) }
    }
  }
}

test "expand_builtin_call_each_mixed_arity" {
  let args = "f, a, (b, c), d"
  match @moonmacro.expand_builtin("call_each", args) {
    None => abort("expected Some")
    Some(code) => {
      if code != "f(a); f(b, c); f(d)" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_repeat_simple" {
  match @moonmacro.expand_builtin("repeat", "Array::make(4, 0), 4") {
    None => abort("expected Some")
    Some(code) => {
      let expected = "Array::make(4, 0), Array::make(4, 0), Array::make(4, 0), Array::make(4, 0)"
      if code != expected { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_repeat_twice" {
  match @moonmacro.expand_builtin("repeat", "42, 2") {
    None => abort("expected Some")
    Some(code) => {
      if code != "42, 42" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_repeat_custom_sep" {
  match @moonmacro.expand_builtin("repeat", "x, 3, +") {
    None => abort("expected Some")
    Some(code) => {
      if code != "x+x+x" { abort("unexpected code: [" + code + "]") }
    }
  }
}

test "expand_builtin_repeat_once" {
  match @moonmacro.expand_builtin("repeat", "hello, 1") {
    None => abort("expected Some")
    Some(code) => {
      if code != "hello" { abort("unexpected: " + code) }
    }
  }
}

test "expand_builtin_repeat_zero" {
  let result = @moonmacro.expand_builtin("repeat", "x, 0")
  if result is Some(_) { abort("expected None for count 0") }
}

test "expand_builtin_repeat_negative" {
  let result = @moonmacro.expand_builtin("repeat", "x, -1")
  if result is Some(_) { abort("expected None for negative count") }
}

test "expand_builtin_repeat_no_count" {
  let result = @moonmacro.expand_builtin("repeat", "x")
  if result is Some(_) { abort("expected None without count") }
}

test "expand_builtin_call_each_triple_arg" {
  let args = "f, (1, 2, 3), (4, 5, 6)"
  match @moonmacro.expand_builtin("call_each", args) {
    None => abort("expected Some")
    Some(code) => {
      if code != "f(1, 2, 3); f(4, 5, 6)" { abort("unexpected: " + code) }
    }
  }
}
