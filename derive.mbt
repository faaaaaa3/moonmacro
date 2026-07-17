pub fn generate_derives(traits : Array[String], name : String, kind : String, generics : String, body : String, custom_derives : Array[DeriveDef]) -> String {
  let result = StringBuilder()
  for t in traits {
    let code = generate_derive_impl(t.trim().to_owned(), name, kind, generics, body, custom_derives)
    result.write_string(code)
    result.write_string("\n")
  }
  result.to_string()
}

fn generate_derive_impl(trait_name : String, name : String, kind : String, generics : String, body : String, custom_derives : Array[DeriveDef]) -> String {
  match trait_name {
    "Constructor" => generate_constructor(name, kind, generics, body)
    "Getters" => generate_getters(name, kind, generics, body)
    "EnumFromStr" => generate_enum_from_str(name, kind, generics, body)
    _ => {
      for d in custom_derives {
        if d.name == trait_name {
          return expand_derive_template(d.template, name, kind, generics, body)
        }
      }
      "// unknown derive: " + trait_name + " for " + name + "\n"
    }
  }
}

fn generate_constructor(name : String, kind : String, generics : String, body : String) -> String {
  if kind != "struct" { return "// Constructor only supports structs\n" }
  let fields = parse_struct_fields(body)
  if fields.length() == 0 { return "// Constructor requires at least one field\n" }
  let full = type_with_generics(name, generics)
  let params = fields.map(fn(f) { f.0 + ": " + f.1 }).join(", ")
  let assigns = fields.map(fn(f) { f.0 }).join(", ")
  let gen_list = if generics.length() > 0 { generics } else { "" }
  "pub fn" + gen_list + " " + name + "::new(" + params + ") -> " + full + " { { " + assigns + " } }\n"
}

fn generate_getters(name : String, kind : String, generics : String, body : String) -> String {
  if kind != "struct" { return "// Getters only supports structs\n" }
  let fields = parse_struct_fields(body)
  if fields.length() == 0 { return "// Getters requires at least one field\n" }
  let full = type_with_generics(name, generics)
  let gen_list = if generics.length() > 0 { generics } else { "" }
  let buf = StringBuilder()
  for f in fields {
    buf.write_string("pub fn" + gen_list + " " + name + "::" + f.0 + "(self: " + full + ") -> " + f.1 + " { self." + f.0 + " }\n")
  }
  buf.to_string()
}

fn pascal_case(s : String) -> String {
  if s.length() == 0 { return s }
  let first = s[0]
  let upper = if first >= ('a' : UInt16) && first <= ('z' : UInt16) {
    (first - 32 : UInt16)
  } else { first }
  let result = StringBuilder()
  result.write_char(upper.to_int().unsafe_to_char())
  if s.length() > 1 { result.write_string(s[1:].to_owned()) }
  result.to_string()
}

fn generate_enum_from_str(name : String, kind : String, generics : String, body : String) -> String {
  if kind != "enum" { return "// EnumFromStr only supports enums\n" }
  let variants = parse_enum_variants(body)
  let unit = variants.filter(fn(v) { v.field_types.length() == 0 })
  if unit.length() == 0 { return "// EnumFromStr requires at least one unit variant\n" }
  let full = type_with_generics(name, generics)
  let buf = StringBuilder()
  let gen_list = if generics.length() > 0 { generics } else { "" }
  buf.write_string("pub fn" + gen_list + " " + name + "::from_string(s: String) -> " + full + "? {\n")
  buf.write_string("  match s {\n")
  for v in unit {
    buf.write_string("    \"" + v.name + "\" => Some(" + name + "::" + v.name + ")\n")
  }
  buf.write_string("    _ => None\n")
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

fn type_with_generics(name : String, generics : String) -> String {
  if generics.length() > 0 { name + generics } else { name }
}

fn parse_struct_fields(body : String) -> Array[(String, String)] {
  let fields : Array[(String, String)] = []
  let mut pos : Int = 0
  let len = body.length()
  pos = skip_ws(body, pos)
  if pos >= len { return fields }
  if body[pos] != ('{' : UInt16) { return fields }
  pos = pos + 1
  while pos < len {
    pos = skip_ws(body, pos)
    if pos >= len { break }
    if body[pos] == ('}' : UInt16) { break }
    let name_res = read_field_ident(body, pos)
    if name_res.0 == "" { pos = pos + 1; continue }
    pos = name_res.1
    pos = skip_ws(body, pos)
    if pos < len && body[pos] == (':' : UInt16) {
      pos = pos + 1
      pos = skip_ws(body, pos)
      let ty_res = read_type(body, pos)
      fields.push((name_res.0, ty_res.0))
      pos = ty_res.1
    }
    pos = skip_ws(body, pos)
    if pos < len && (body[pos] == (',' : UInt16) || body[pos] == (';' : UInt16)) { pos = pos + 1 }
  }
  fields
}

priv struct EnumVariant {
  name : String
  field_types : Array[String]
}

fn parse_enum_variants(body : String) -> Array[EnumVariant] {
  let variants : Array[EnumVariant] = []
  let mut pos : Int = 0
  let len = body.length()
  pos = skip_ws(body, pos)
  if pos >= len || body[pos] != ('{' : UInt16) { return variants }
  pos = pos + 1
  while pos < len {
    pos = skip_ws(body, pos)
    if pos >= len || body[pos] == ('}' : UInt16) { break }
    let name_res = read_field_ident(body, pos)
    if name_res.0 == "" { pos = pos + 1; continue }
    pos = name_res.1
    pos = skip_ws(body, pos)
    if pos < len && body[pos] == ('(' : UInt16) {
      let types = read_comma_types(body, pos)
      pos = types.1
      variants.push({ name: name_res.0, field_types: types.0 })
    } else if pos < len && body[pos] == ('{' : UInt16) {
      let fields_res = read_record_fields(body, pos)
      pos = fields_res.1
      let types = fields_res.0.map(fn(f) { f.1 })
      variants.push({ name: name_res.0, field_types: types })
    } else {
      variants.push({ name: name_res.0, field_types: [] })
    }
    pos = skip_ws(body, pos)
    if pos < len && body[pos] == (',' : UInt16) { pos = pos + 1 }
  }
  variants
}

fn read_comma_types(s : String, start : Int) -> (Array[String], Int) {
  let types : Array[String] = []
  if start >= s.length() { return (types, start) }
  if s[start] != ('(' : UInt16) { return (types, start) }
  let mut pos = start + 1
  let len = s.length()
  let mut depth = 1
  let mut type_start = pos
  while pos < len && depth > 0 {
    let c = s[pos]
    if c == ('(' : UInt16) || c == ('<' : UInt16) || c == ('[' : UInt16) { depth = depth + 1 }
    else if c == (')' : UInt16) || c == ('>' : UInt16) || c == (']' : UInt16) { depth = depth - 1 }
    else if c == (',' : UInt16) && depth == 1 {
      let t = s[type_start:pos].trim().to_owned()
      if t.length() > 0 { types.push(t) }
      type_start = pos + 1
    }
    pos = pos + 1
  }
  if type_start < pos - 1 {
    let t = s[type_start:pos - 1].trim().to_owned()
    if t.length() > 0 { types.push(t) }
  }
  (types, pos)
}

fn read_record_fields(s : String, start : Int) -> (Array[(String, String)], Int) {
  let fields : Array[(String, String)] = []
  if start >= s.length() { return (fields, start) }
  if s[start] != ('{' : UInt16) { return (fields, start) }
  let mut pos = start + 1
  let len = s.length()
  while pos < len {
    pos = skip_ws(s, pos)
    if pos >= len || s[pos] == ('}' : UInt16) { break }
    let name_res = read_field_ident(s, pos)
    if name_res.0 == "" { pos = pos + 1; continue }
    pos = name_res.1
    pos = skip_ws(s, pos)
    if pos < len && s[pos] == (':' : UInt16) {
      pos = pos + 1
      pos = skip_ws(s, pos)
      let ty_res = read_type(s, pos)
      fields.push((name_res.0, ty_res.0))
      pos = ty_res.1
    }
    if pos < len && (s[pos] == (',' : UInt16) || s[pos] == (';' : UInt16)) { pos = pos + 1 }
  }
  if pos < len { pos = pos + 1 }
  (fields, pos)
}

fn read_field_ident(s : String, start : Int) -> (String, Int) {
  let mut pos = start
  let len = s.length()
  if pos + 3 < len && s[pos:pos + 4].to_owned() == "mut " {
    pos = pos + 4
  }
  let start_pos = pos
  while pos < len {
    let c = s[pos]
    let is_valid = (c >= ('a' : UInt16) && c <= ('z' : UInt16)) ||
      (c >= ('A' : UInt16) && c <= ('Z' : UInt16)) ||
      c == ('_' : UInt16) ||
      (pos > start_pos && c >= ('0' : UInt16) && c <= ('9' : UInt16))
    if is_valid { pos = pos + 1 } else { break }
  }
  if pos == start_pos { ("", start) }
  else { (s[start_pos:pos].to_owned(), pos) }
}

fn read_type(s : String, start : Int) -> (String, Int) {
  let mut pos = start
  let len = s.length()
  let mut depth = 0
  while pos < len {
    let c = s[pos]
    if (c == (',' : UInt16) || c == (';' : UInt16) || c == ('}' : UInt16) || c == ('\n' : UInt16) || c == ('\r' : UInt16) || c == ('\t' : UInt16)) && depth == 0 { break }
    if c == ('<' : UInt16) || c == ('[' : UInt16) || c == ('(' : UInt16) { depth = depth + 1 }
    if c == ('>' : UInt16) || c == (']' : UInt16) || c == (')' : UInt16) { depth = depth - 1 }
    pos = pos + 1
  }
  (s[start:pos].trim().to_owned(), pos)
}
