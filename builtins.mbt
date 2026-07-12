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
