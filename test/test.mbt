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
  let source = "#[macro_derive(ToJson)]\nstruct Point { x: Int, y: Int }\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { abort("expected 1 invocation") }
  match invs[0] {
    @moonmacro.Derive(traits, name, kind, _generics, _body, _s, _e) => {
      if traits.length() != 1 { abort("expected 1 trait, got " + traits.length().to_string()) }
      if traits[0] != "ToJson" { abort("expected ToJson, got " + traits[0]) }
      if name != "Point" { abort("expected Point") }
      if kind != "struct" { abort("expected struct") }
    }
    _ => abort("expected Derive")
  }
}

test "derive_with_braces" {
  let source = "#[macro_derive(ToJson)]\nstruct Point {\n  x: Int\n  y: Int\n}"
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

test "generate_derive_to_json_enum_unit" {
  let result = @moonmacro.generate_derives(["ToJson"], "Color", "enum", "", "{\n  Red\n  Green\n}")
  if result.find("to_json") is None { abort("expected to_json") }
  if result.find("Red") is None { abort("expected Red variant") }
}

test "generate_derive_to_json_enum_tuple" {
  let result = @moonmacro.generate_derives(["ToJson"], "Expr", "enum", "", "{\n  Int(Int)\n  Add(Int, Int)\n}")
  if result.find(".to_json()") is None { abort("expected to_json calls") }
}

test "stacked_derive_same_struct" {
  let source = "#[macro_derive(ToJson)]\n#[macro_derive(ToJson)]\nstruct Point { x: Int }\n"
  let defs : Array[@moonmacro.MacroDef] = []
  let invs = @moonmacro.find_macro_invocations(source, defs)
  if invs.length() != 1 { abort("expected 1 invocation, got " + invs.length().to_string()) }
  match invs[0] {
    @moonmacro.Derive(traits, name, _kind, _generics, _body, _s, _e) => {
      if traits.length() != 2 { abort("expected 2 merged traits, got " + traits.length().to_string()) }
      if traits[0] != "ToJson" { abort("expected ToJson") }
      if traits[1] != "ToJson" { abort("expected ToJson") }
      if name != "Point" { abort("expected Point") }
    }
    _ => abort("expected Derive")
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
