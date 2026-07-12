pub fn expand_builtin(name : String, args : String) -> String? {
  match name {
    "assert" => Some("if !(" + args + ") { abort(\"assertion failed: " + args + "\") }")
    "stringify" => Some("\"" + args + "\"")
    "matches" => {
      let split = split_at_top_level_comma(args)
      match split {
        Some((expr, pat)) => Some("match " + expr + " { " + pat + " => true, _ => false }")
        None => None
      }
    }
    "todo" => {
      let msg = args.trim().to_owned()
      if msg.length() > 0 { Some("abort(" + msg + ")") }
      else { Some("abort(\"not implemented\")") }
    }
    "dbg" => Some("{ let __dbg_val = " + args + "; println(\"[dbg] \" + stringify!(" + args + ") + \" = \" + __dbg_val.to_string()); __dbg_val }")
    "let_array" => expand_let_array(args)
    "call_each" => expand_call_each(args)
    "repeat" => expand_repeat(args)
    "inspect" => {
      match split_at_top_level_comma(args) {
        Some((expr, expected)) => {
          Some("@debug.debug_inspect(" + expr + ", content=" + expected.trim().to_owned() + ")")
        }
        None => None
      }
    }
    "echo" => expand_echo(args)
    "logger" => expand_logger(args)
    "timeit" => expand_timeit(args)
    "tryn" => expand_tryn(args)
    _ => None
  }
}

fn expand_let_array(args : String) -> String? {
  let eq_pos = find_top_level_eq(args)
  if eq_pos < 0 { return None }
  let vars_part = args[0:eq_pos].trim().to_owned()
  let rest = args[eq_pos + 1:].trim().to_owned()
  if vars_part.length() == 0 || rest.length() == 0 { return None }

  let start = 0
  let expr = rest
  let comma_start = find_last_top_level_prefix(rest, ", start:")
  let actual_start = if comma_start >= 0 {
    let start_str = rest[comma_start + ", start:".length():].trim().to_owned()
    parse_int_safe(start_str)
  } else { start }
  let actual_expr = if comma_start >= 0 {
    rest[0:comma_start].trim().to_owned()
  } else { expr }

  let vars : Array[String] = []
  let is_mut : Array[Bool] = []
  let mut pos = 0
  let vlen = vars_part.length()
  while pos < vlen {
    let trimmed_start = skip_ws_from(vars_part, pos)
    if trimmed_start >= vlen { break }
    let comma_pos = find_top_level_comma(vars_part, trimmed_start)
    let raw = if comma_pos < 0 {
      vars_part[trimmed_start:].trim().to_owned()
    } else {
      vars_part[trimmed_start:comma_pos].trim().to_owned()
    }
    if raw.length() > 0 {
      if raw.has_prefix("mut ") {
        vars.push(raw[4:].trim().to_owned())
        is_mut.push(true)
      } else {
        vars.push(raw)
        is_mut.push(false)
      }
    }
    pos = if comma_pos < 0 { vlen } else { comma_pos + 1 }
  }

  if vars.length() == 0 { return None }

  let result = StringBuilder()
  for i in 0..<vars.length() {
    if i > 0 { result.write_string("; ") }
    if is_mut[i] { result.write_string("let mut ") } else { result.write_string("let ") }
    result.write_string(vars[i])
    result.write_string(" = ")
    result.write_string(actual_expr)
    result.write_string("[")
    result.write_string((actual_start + i).to_string())
    result.write_string("]")
  }
  Some(result.to_string())
}

fn parse_int_safe(s : String) -> Int {
  let mut result = 0
  let mut i = 0
  let len = s.length()
  while i < len {
    let c = s[i]
    if c >= ('0' : UInt16) && c <= ('9' : UInt16) {
      result = result * 10 + (c.to_int() - ('0' : UInt16).to_int())
    } else { break }
    i = i + 1
  }
  result
}

fn find_top_level_eq(s : String) -> Int {
  let mut depth = 0
  let mut pos = 0
  let len = s.length()
  while pos < len {
    let c = s[pos]
    if c == ('(' : UInt16) || c == ('<' : UInt16) || c == ('[' : UInt16) || c == ('{' : UInt16) {
      depth = depth + 1
    } else if c == (')' : UInt16) || c == ('>' : UInt16) || c == (']' : UInt16) || c == ('}' : UInt16) {
      depth = depth - 1
    } else if c == ('=' : UInt16) && depth == 0 {
      return pos
    }
    pos = pos + 1
  }
  -1
}

fn find_last_top_level_prefix(s : String, prefix : String) -> Int {
  let mut depth = 0
  let mut pos = s.length() - 1
  let plen = prefix.length()
  while pos >= 0 {
    let c = s[pos]
    if c == (')' : UInt16) || c == ('>' : UInt16) || c == (']' : UInt16) || c == ('}' : UInt16) {
      depth = depth + 1
    } else if c == ('(' : UInt16) || c == ('<' : UInt16) || c == ('[' : UInt16) || c == ('{' : UInt16) {
      depth = depth - 1
    } else if depth == 0 && pos + plen <= s.length() && s[pos:pos + plen] == prefix {
      return pos
    }
    pos = pos - 1
  }
  -1
}

fn find_top_level_comma(s : String, from : Int) -> Int {
  let mut depth = 0
  let mut pos = from
  let len = s.length()
  while pos < len {
    let c = s[pos]
    if c == ('(' : UInt16) || c == ('<' : UInt16) || c == ('[' : UInt16) || c == ('{' : UInt16) {
      depth = depth + 1
    } else if c == (')' : UInt16) || c == ('>' : UInt16) || c == (']' : UInt16) || c == ('}' : UInt16) {
      depth = depth - 1
    } else if c == (',' : UInt16) && depth == 0 {
      return pos
    }
    pos = pos + 1
  }
  -1
}

fn skip_ws_from(s : String, from : Int) -> Int {
  let mut pos = from
  let len = s.length()
  while pos < len && (s[pos] == (' ' : UInt16) || s[pos] == ('\t' : UInt16) || s[pos] == ('\n' : UInt16)) {
    pos = pos + 1
  }
  pos
}

fn expand_call_each(args : String) -> String? {
  let split = split_at_top_level_comma(args)
  match split {
    None => None
    Some((prefix, rest)) => {
      let p = prefix
      let r = rest
      if p.length() == 0 || r.length() == 0 { return None }
      let arg_parts = split_all_top_level_commas(r)
      let result = StringBuilder()
      let mut count = 0
      for i in 0..<arg_parts.length() {
        let a = arg_parts[i].trim().to_owned()
        if a.length() == 0 { continue }
        if count > 0 { result.write_string("; ") }
        result.write_string(p)
        result.write_string("(")
        if a.has_prefix("(") && ends_with_paren(a) {
          result.write_string(a[1:a.length() - 1].to_owned())
        } else {
          result.write_string(a)
        }
        result.write_string(")")
        count = count + 1
      }
      if count == 0 { None } else { Some(result.to_string()) }
    }
  }
}

fn expand_repeat(args : String) -> String? {
  let parts = split_all_top_level_commas(args)
  if parts.length() < 2 { return None }
  let expr = parts[0].trim().to_owned()
  if expr.length() == 0 { return None }
  let count_str = parts[1].trim().to_owned()
  let count = parse_int_safe(count_str)
  if count <= 0 { return None }
  let sep = if parts.length() >= 3 {
    parts[2].trim().to_owned()
  } else { ", " }
  let result = StringBuilder()
  for i in 0..<count {
    if i > 0 { result.write_string(sep) }
    result.write_string(expr)
  }
  Some(result.to_string())
}

fn expand_echo(args : String) -> String? {
  let parts = split_all_top_level_commas(args)
  let result = StringBuilder()
  result.write_string("println(\"")
  let mut count = 0
  for p in parts {
    let name = p.trim().to_owned()
    if name.length() == 0 { continue }
    if count > 0 { result.write_string(", ") }
    result.write_string(name)
    result.write_string(" = \\{")
    result.write_string(name)
    result.write_string("}")
    count = count + 1
  }
  if count == 0 { return None }
  result.write_string("\")")
  Some(result.to_string())
}

fn expand_logger(args : String) -> String? {
  let s = args.trim().to_owned()
  if !s.has_prefix("fn ") { return None }

  let len = s.length()
  let name_start = 3
  let mut name_end = name_start
  while name_end < len {
    let c = s[name_end]
    let valid = (c >= ('a' : UInt16) && c <= ('z' : UInt16)) ||
      (c >= ('A' : UInt16) && c <= ('Z' : UInt16)) ||
      c == ('_' : UInt16) ||
      (name_end > name_start && c >= ('0' : UInt16) && c <= ('9' : UInt16))
    if valid { name_end = name_end + 1 } else { break }
  }
  if name_end == name_start { return None }
  let func_name = s[name_start:name_end].to_owned()

  let mut depth = 0
  let mut brace_open = -1
  let mut pos = 0
  while pos < len {
    let c = s[pos]
    if c == ('"' : UInt16) { pos = skip_string_from(s, pos); pos = pos - 1 }
    else if c == ('(' : UInt16) || c == ('<' : UInt16) || c == ('[' : UInt16) || c == ('{' : UInt16) {
      if c == ('{' : UInt16) && depth == 0 { brace_open = pos; break }
      depth = depth + 1
    } else if c == (')' : UInt16) || c == (']' : UInt16) || c == ('}' : UInt16) {
      depth = depth - 1
    } else if c == ('>' : UInt16) && depth > 0 {
      depth = depth - 1
    } else if c == ('-' : UInt16) && pos + 1 < len && s[pos + 1] == ('>' : UInt16) {
      pos = pos + 1
    }
    pos = pos + 1
  }
  if brace_open < 0 { return None }

  let mut d = 1
  let mut brace_close = brace_open + 1
  while brace_close < len && d > 0 {
    let c = s[brace_close]
    if c == ('"' : UInt16) { brace_close = skip_string_from(s, brace_close); brace_close = brace_close - 1 }
    else if c == ('{' : UInt16) { d = d + 1 }
    else if c == ('}' : UInt16) { d = d - 1 }
    brace_close = brace_close + 1
  }
  if d != 0 { return None }
  brace_close = brace_close - 1

  let before = s[0:brace_open + 1].to_owned()
  let body = s[brace_open + 1:brace_close].to_owned()
  let after = s[brace_close:].to_owned()

  let result = StringBuilder()
  result.write_string(before)
  result.write_string("\n  defer { println(\"leaving ")
  result.write_string(func_name)
  result.write_string("\") }")
  result.write_string("\n  println(\"entering ")
  result.write_string(func_name)
  result.write_string("\")")
  let trimmed_body = body.trim().to_owned()
  if trimmed_body.length() > 0 {
    result.write_string("\n  ")
    result.write_string(trimmed_body)
  }
  result.write_string("\n")
  result.write_string(after)
  Some(result.to_string())
}

fn expand_timeit(args : String) -> String? {
  let s = args.trim().to_owned()
  if !s.has_prefix("fn ") { return None }

  let len = s.length()
  let name_start = 3
  let mut name_end = name_start
  while name_end < len {
    let c = s[name_end]
    let valid = (c >= ('a' : UInt16) && c <= ('z' : UInt16)) ||
      (c >= ('A' : UInt16) && c <= ('Z' : UInt16)) ||
      c == ('_' : UInt16) ||
      (name_end > name_start && c >= ('0' : UInt16) && c <= ('9' : UInt16))
    if valid { name_end = name_end + 1 } else { break }
  }
  if name_end == name_start { return None }
  let func_name = s[name_start:name_end].to_owned()

  let mut depth = 0
  let mut brace_open = -1
  let mut pos = 0
  while pos < len {
    let c = s[pos]
    if c == ('"' : UInt16) { pos = skip_string_from(s, pos); pos = pos - 1 }
    else if c == ('(' : UInt16) || c == ('<' : UInt16) || c == ('[' : UInt16) || c == ('{' : UInt16) {
      if c == ('{' : UInt16) && depth == 0 { brace_open = pos; break }
      depth = depth + 1
    } else if c == (')' : UInt16) || c == (']' : UInt16) || c == ('}' : UInt16) {
      depth = depth - 1
    } else if c == ('>' : UInt16) && depth > 0 {
      depth = depth - 1
    } else if c == ('-' : UInt16) && pos + 1 < len && s[pos + 1] == ('>' : UInt16) {
      pos = pos + 1
    }
    pos = pos + 1
  }
  if brace_open < 0 { return None }

  let mut d = 1
  let mut brace_close = brace_open + 1
  while brace_close < len && d > 0 {
    let c = s[brace_close]
    if c == ('"' : UInt16) { brace_close = skip_string_from(s, brace_close); brace_close = brace_close - 1 }
    else if c == ('{' : UInt16) { d = d + 1 }
    else if c == ('}' : UInt16) { d = d - 1 }
    brace_close = brace_close + 1
  }
  if d != 0 { return None }
  brace_close = brace_close - 1

  let before = s[0:brace_open + 1].to_owned()
  let body = s[brace_open + 1:brace_close].to_owned()
  let after = s[brace_close:].to_owned()

  let result = StringBuilder()
  result.write_string(before)
  result.write_string("\n  let __timeit_start = @env.now()")
  result.write_string("\n  defer { println(\"")
  result.write_string(func_name)
  result.write_string(" took \" + (@env.now() - __timeit_start).to_string() + \"ms\") }")
  let trimmed_body = body.trim().to_owned()
  if trimmed_body.length() > 0 {
    result.write_string("\n  ")
    result.write_string(trimmed_body)
  }
  result.write_string("\n")
  result.write_string(after)
  Some(result.to_string())
}

fn expand_tryn(args : String) -> String? {
  let parts = split_all_top_level_commas(args)
  if parts.length() != 2 { return None }
  let expr = parts[0].trim().to_owned()
  let n = parts[1].trim().to_owned()
  let result = StringBuilder()
  result.write_string("{\n  let __tryn_max = ")
  result.write_string(n)
  result.write_string("\n  let mut __tryn_i = 0")
  result.write_string("\n  let __tryn_val = loop {")
  result.write_string("\n    if __tryn_i >= __tryn_max { break None }")
  result.write_string("\n    __tryn_i = __tryn_i + 1")
  result.write_string("\n    let __tryn_cur = ")
  result.write_string(expr)
  result.write_string("\n    if __tryn_cur is Some(_) { break __tryn_cur }")
  result.write_string("\n  }")
  result.write_string("\n  __tryn_val")
  result.write_string("\n}")
  Some(result.to_string())
}

fn skip_string_from(s : String, start : Int) -> Int {
  let mut pos = start + 1
  let len = s.length()
  while pos < len {
    let c = s[pos]
    if c == ('\\' : UInt16) { pos = pos + 2 }
    else if c == ('"' : UInt16) { return pos + 1 }
    else { pos = pos + 1 }
  }
  pos
}

fn ends_with_paren(s : String) -> Bool {
  let len = s.length()
  len > 0 && s[len - 1] == (')' : UInt16)
}

fn split_all_top_level_commas(s : String) -> Array[String] {
  let parts : Array[String] = []
  let mut depth = 0
  let mut start = 0
  let mut pos = 0
  let len = s.length()
  while pos < len {
    let c = s[pos]
    if c == ('(' : UInt16) || c == ('<' : UInt16) || c == ('[' : UInt16) || c == ('{' : UInt16) {
      depth = depth + 1
    } else if c == (')' : UInt16) || c == ('>' : UInt16) || c == (']' : UInt16) || c == ('}' : UInt16) {
      depth = depth - 1
    } else if c == (',' : UInt16) && depth == 0 {
      parts.push(s[start:pos].to_owned())
      start = pos + 1
    }
    pos = pos + 1
  }
  if start < len { parts.push(s[start:].to_owned()) }
  parts
}

fn split_at_top_level_comma(s : String) -> (String, String)? {
  let mut depth = 0
  let mut pos = 0
  let len = s.length()
  while pos < len {
    let c = s[pos]
    if c == ('(' : UInt16) || c == ('<' : UInt16) || c == ('[' : UInt16) || c == ('{' : UInt16) {
      depth = depth + 1
    } else if c == (')' : UInt16) || c == ('>' : UInt16) || c == (']' : UInt16) || c == ('}' : UInt16) {
      depth = depth - 1
    } else if c == (',' : UInt16) && depth == 0 {
      let expr = s[0:pos].trim().to_owned()
      let pat = s[pos + 1:].trim().to_owned()
      return Some((expr, pat))
    }
    pos = pos + 1
  }
  None
}
