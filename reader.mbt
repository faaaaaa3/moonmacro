pub(all) struct MacroDef {
  name : String
  patterns : Array[MacroRule]
}

pub(all) struct MacroRule {
  pattern : String
  template : String
}

pub(all) struct DeriveDef {
  name : String
  template : String
}

pub(all) enum MacroInvocation {
  FuncCall(String, String, String, Int, Int)
  Derive(Array[String], String, String, String, String, Int, Int)
}

pub fn invocation_start(inv : MacroInvocation) -> Int {
  match inv {
    FuncCall(_, _, _, s, _) => s
    Derive(_, _, _, _, _, s, _) => s
  }
}

pub fn invocation_end(inv : MacroInvocation) -> Int {
  match inv {
    FuncCall(_, _, _, _, e) => e
    Derive(_, _, _, _, _, _, e) => e
  }
}

fn skip_non_code(s : String, start : Int) -> Int {
  let mut pos = start
  let len = s.length()
  while pos < len {
    // line comment
    if pos + 1 < len && s[pos] == ('/' : UInt16) && s[pos + 1] == ('/' : UInt16) {
      while pos < len && s[pos] != ('\n' : UInt16) { pos = pos + 1 }
      continue
    }
    // multi-line string #| ... |#
    if pos + 1 < len && s[pos] == ('#' : UInt16) && s[pos + 1] == ('|' : UInt16) {
      pos = pos + 2
      while pos + 1 < len && !(s[pos] == ('|' : UInt16) && s[pos + 1] == ('#' : UInt16)) { pos = pos + 1 }
      if pos + 1 < len { pos = pos + 2 }
      continue
    }
    // multi-line string $| ... |#
    if pos + 1 < len && s[pos] == ('$' : UInt16) && s[pos + 1] == ('|' : UInt16) {
      pos = pos + 2
      while pos + 1 < len && !(s[pos] == ('|' : UInt16) && s[pos + 1] == ('#' : UInt16)) { pos = pos + 1 }
      if pos + 1 < len { pos = pos + 2 }
      continue
    }
    // single-line string
    if s[pos] == ('"' : UInt16) { pos = skip_string(s, pos); continue }
    break
  }
  pos
}

pub fn find_macro_defs(source : String) -> Array[MacroDef] {
  let defs : Array[MacroDef] = []
  let mut pos : Int = 0
  let len = source.length()
  while pos < len {
    pos = skip_non_code(source, pos)
    if pos >= len { break }
    if is_at(source, pos, "macro_rules!") {
      pos = pos + "macro_rules!".length()
      pos = skip_ws(source, pos)
      let name_res = read_ident(source, pos)
      pos = name_res.1
      pos = skip_ws(source, pos)
      let body_res = read_balanced(source, pos)
      pos = body_res.1
      let rules = parse_macro_body(body_res.0)
      defs.push({ name: name_res.0, patterns: rules })
    } else {
      pos = pos + 1
    }
  }
  defs
}

pub fn find_derive_defs(source : String) -> Array[DeriveDef] {
  let defs : Array[DeriveDef] = []
  let mut pos : Int = 0
  let len = source.length()
  while pos < len {
    pos = skip_non_code(source, pos)
    if pos >= len { break }
    if is_at(source, pos, "macro_derive!") {
      pos = pos + "macro_derive!".length()
      pos = skip_ws(source, pos)
      let name_res = read_ident(source, pos)
      if name_res.0 == "" { pos = pos + 1; continue }
      pos = name_res.1
      pos = skip_ws(source, pos)
      let body_res = read_balanced(source, pos)
      pos = body_res.1
      let tmpl_body = body_res.0
      if tmpl_body.length() >= 2 {
        defs.push({ name: name_res.0, template: tmpl_body[1:tmpl_body.length() - 1].to_owned() })
      }
    } else {
      pos = pos + 1
    }
  }
  defs
}

pub fn find_macro_invocations(source : String, _defs : Array[MacroDef]) -> Array[MacroInvocation] {
  let invs : Array[MacroInvocation] = []
  let mut pos : Int = 0
  let len = source.length()
  while pos < len {
    pos = skip_non_code(source, pos)
    if pos >= len { break }
    if is_at(source, pos, "#[macro_derive(") {
      let derive_start = pos
      let all_traits = collect_derive_traits(source, pos)
      pos = all_traits.1
      let remaining = source[pos:].to_owned()
      let header_res = parse_struct_or_enum_header(remaining)
      let block_res = read_next_block(remaining, header_res.3)
      pos = pos + block_res.1
      invs.push(Derive(all_traits.0, header_res.0, header_res.1, header_res.2, block_res.0, derive_start, pos))
    } else if is_ident_start_at(source, pos) {
      let call_start = pos
      let ident_res = read_ident(source, pos)
      let name = ident_res.0
      pos = ident_res.1
      if pos < len && source[pos] == ('!' : UInt16) {
        pos = pos + 1
        if pos < len {
          let open_delim = source[pos:pos + 1].to_owned()
          let args_res = read_delimited(source, pos)
          if args_res.0 is Some(arg) {
            invs.push(FuncCall(name, arg, open_delim, call_start, args_res.1))
            pos = args_res.1
          }
        }
      }
    } else {
      pos = pos + 1
    }
  }
  invs
}

fn collect_derive_traits(source : String, start : Int) -> (Array[String], Int) {
  let all_traits : Array[String] = []
  let mut pos = start
  while is_at(source, pos, "#[macro_derive(") {
    let after = read_balanced(source, pos + 1)
    let inner = after.0[1:after.0.length() - 1].to_owned()
    pos = after.1
    let trait_body = inner["macro_derive".length():]
    let cleaned = trait_body[1:trait_body.length() - 1].to_owned()
    let traits_arr = parse_comma_list(cleaned)
    for t in traits_arr { all_traits.push(t) }
    pos = skip_ws(source, pos)
  }
  (all_traits, pos)
}

fn parse_comma_list(s : String) -> Array[String] {
  let result : Array[String] = []
  let mut pos : Int = 0
  let len = s.length()
  let mut depth = 0
  let mut start = 0
  while pos < len {
    let c = s[pos]
    if c == ('"' : UInt16) { pos = skip_string(s, pos) - 1 }
    else if c == ('(' : UInt16) || c == ('<' : UInt16) || c == ('[' : UInt16) { depth = depth + 1 }
    else if c == (')' : UInt16) || c == ('>' : UInt16) || c == (']' : UInt16) { depth = depth - 1 }
    else if c == (',' : UInt16) && depth == 0 {
      let elem = s[start:pos].trim().to_owned()
      if elem.length() > 0 { result.push(elem) }
      start = pos + 1
    }
    pos = pos + 1
  }
  if start < len {
    let last = s[start:len].trim().to_owned()
    if last.length() > 0 { result.push(last) }
  }
  result
}

fn derive_field_names(body : String) -> String {
  let fields = parse_struct_fields(body)
  fields.map(fn(f) { f.0 }).join(", ")
}

fn derive_field_types(body : String) -> String {
  let fields = parse_struct_fields(body)
  fields.map(fn(f) { f.1 }).join(", ")
}

fn derive_variant_names(body : String) -> String {
  let variants = parse_enum_variants(body)
  variants.map(fn(v) { v.name }).join(", ")
}

fn derive_enum_field_types(body : String) -> String {
  let variants = parse_enum_variants(body)
  let all_types : Array[String] = []
  for v in variants {
    for t in v.field_types {
      all_types.push(t)
    }
  }
  all_types.join(", ")
}


pub fn expand_derive_template(template : String, type_name : String, kind : String, generics : String, body : String) -> String {
  let field_names = if kind == "struct" { derive_field_names(body) } else { "" }
  let field_types = if kind == "enum" { derive_enum_field_types(body) } else if kind == "struct" { derive_field_types(body) } else { "" }
  let variant_names = if kind == "enum" { derive_variant_names(body) } else { "" }
  let result = StringBuilder()
  let mut pos : Int = 0
  let len = template.length()
  while pos < len {
    if template[pos] == ('$' : UInt16) {
      if is_at(template, pos, "$T") { result.write_string(type_name); pos = pos + 2 }
      else if is_at(template, pos, "$type") { result.write_string(type_name); pos = pos + 5 }
      else if is_at(template, pos, "$body") { result.write_string(body); pos = pos + 5 }
      else if is_at(template, pos, "$kind") { result.write_string(kind); pos = pos + 5 }
      else if is_at(template, pos, "$generics") { result.write_string(generics); pos = pos + 9 }
      else if is_at(template, pos, "$Name") { result.write_string(pascal_case(type_name)); pos = pos + 5 }
      else if is_at(template, pos, "$fields") { result.write_string(field_names); pos = pos + 7 }
      else if is_at(template, pos, "$field_types") { result.write_string(field_types); pos = pos + 12 }
      else if is_at(template, pos, "$variants") { result.write_string(variant_names); pos = pos + 9 }
      else { result.write_char(('$' : UInt16).to_int().unsafe_to_char()); pos = pos + 1 }
    } else {
      result.write_char(template[pos].to_int().unsafe_to_char())
      pos = pos + 1
    }
  }
  result.to_string()
}

pub fn expand_macro_call(name : String, args : String, defs : Array[MacroDef]) -> String? {
  for d in defs {
    if d.name == name {
      for rule in d.patterns {
        let matched = match_pattern(rule.pattern, args)
        if matched is Some(captures) {
          let expanded = expand_template(rule.template, captures)
          return Some(expanded)
        }
      }
    }
  }
  None
}

fn parse_macro_body(body : String) -> Array[MacroRule] {
  let rules : Array[MacroRule] = []
  let mut pos : Int = 0
  let len = body.length()
  while pos < len {
    pos = skip_ws(body, pos)
    if pos >= len { break }
    if body[pos] == ('(' : UInt16) {
      let pattern_res = read_balanced(body, pos)
      pos = pattern_res.1
      pos = skip_ws(body, pos)
      if pos + 1 < len && body[pos] == ('=' : UInt16) && body[pos + 1] == ('>' : UInt16) {
        pos = pos + 2
      }
      pos = skip_ws(body, pos)
      if pos >= len { break }
      if body[pos] == ('{' : UInt16) || body[pos] == ('(' : UInt16) {
        let template_res = read_balanced(body, pos)
        pos = template_res.1
        let raw = template_res.0
        if raw.length() >= 2 {
          let pat = pattern_res.0[1:pattern_res.0.length() - 1].to_owned()
          let tmpl = raw[1:raw.length() - 1].to_owned()
          rules.push({ pattern: pat, template: tmpl })
        }
      }
    }
    if pos >= len { break }
    pos = pos + 1
  }
  rules
}

fn read_balanced(s : String, start : Int) -> (String, Int) {
  if start >= s.length() { return ("", start) }
  let open_ch = s[start]
  let close_ch : UInt16 =
    if open_ch == ('{' : UInt16) { ('}' : UInt16) }
    else if open_ch == ('(' : UInt16) { (')' : UInt16) }
    else if open_ch == ('[' : UInt16) { (']' : UInt16) }
    else { return ("", start + 1) }
  let mut depth = 1
  let mut pos = start + 1
  let len = s.length()
  while pos < len && depth > 0 {
    let c = s[pos]
    if c == open_ch { depth = depth + 1 }
    else if c == close_ch { depth = depth - 1 }
    else if c == ('"' : UInt16) { pos = skip_string(s, pos) - 1 }
    pos = pos + 1
  }
  (s[start:pos].to_owned(), pos)
}

fn read_delimited(s : String, start : Int) -> (Option[String], Int) {
  if start >= s.length() { return (None, start) }
  let c = s[start]
  if c == ('{' : UInt16) || c == ('(' : UInt16) || c == ('[' : UInt16) {
    let res = read_balanced(s, start)
    let inner = res.0
    if inner.length() >= 2 {
      (Some(inner[1:inner.length() - 1].to_owned()), res.1)
    } else {
      (None, res.1)
    }
  } else {
    (None, start)
  }
}

fn read_ident(s : String, start : Int) -> (String, Int) {
  let mut pos = start
  let len = s.length()
  while pos < len {
    let c = s[pos]
    let is_valid = (c >= ('a' : UInt16) && c <= ('z' : UInt16)) ||
      (c >= ('A' : UInt16) && c <= ('Z' : UInt16)) ||
      c == ('_' : UInt16) ||
      (pos > start && c >= ('0' : UInt16) && c <= ('9' : UInt16))
    if is_valid { pos = pos + 1 } else { break }
  }
  (s[start:pos].to_owned(), pos)
}

fn skip_ws(s : String, start : Int) -> Int {
  let mut pos = start
  let len = s.length()
  while pos < len {
    let c = s[pos]
    if c == (' ' : UInt16) || c == ('\t' : UInt16) || c == ('\n' : UInt16) || c == ('\r' : UInt16) {
      pos = pos + 1
    } else { break }
  }
  pos
}

fn skip_string(s : String, start : Int) -> Int {
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

fn is_ident_start_at(s : String, pos : Int) -> Bool {
  if pos >= s.length() { false }
  else {
    let c = s[pos]
    (c >= ('a' : UInt16) && c <= ('z' : UInt16)) ||
      (c >= ('A' : UInt16) && c <= ('Z' : UInt16)) ||
      c == ('_' : UInt16)
  }
}

fn is_at(s : String, pos : Int, target : String) -> Bool {
  if pos + target.length() > s.length() { false }
  else { s[pos:pos + target.length()].to_owned() == target }
}

fn parse_struct_or_enum_header(s : String) -> (String, String, String, Int) {
  let mut pos = skip_ws(s, 0)
  let kind = if is_at(s, pos, "struct") {
    pos = pos + "struct".length()
    "struct"
  } else if is_at(s, pos, "enum") {
    pos = pos + "enum".length()
    "enum"
  } else {
    return ("", "", "", 0)
  }
  pos = skip_ws(s, pos)
  let name_res = read_ident(s, pos)
  pos = name_res.1
    pos = skip_ws(s, pos)
    let generics = if pos < s.length() && s[pos] == ('[' : UInt16) {
      let res = read_balanced(s, pos)
      pos = res.1
      pos = skip_ws(s, pos)
      res.0
  } else { "" }
  (name_res.0, kind, generics, pos)
}

fn read_next_block(s : String, start : Int) -> (String, Int) {
  let pos = skip_ws(s, start)
  if pos >= s.length() { return ("", pos) }
  let res = read_balanced(s, pos)
  (res.0, res.1)
}
