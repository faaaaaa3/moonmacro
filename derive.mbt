pub fn generate_derives(traits : Array[String], name : String, kind : String, generics : String, body : String) -> String {
  let result = StringBuilder()
  for t in traits {
    let code = generate_derive_impl(t.trim().to_owned(), name, kind, generics, body)
    result.write_string(code)
    result.write_string("\n")
  }
  result.to_string()
}

fn generate_derive_impl(trait_name : String, name : String, kind : String, generics : String, body : String) -> String {
  match trait_name {
    "Show" => generate_show(name, kind, generics, body)
    "Debug" => generate_show(name, kind, generics, body)
    "Eq" => generate_eq(name, kind, generics, body)
    "ToJson" => generate_to_json(name, kind, generics, body)
    "Clone" => generate_clone(name, kind, generics, body)
    _ => "// unknown derive: " + trait_name + " for " + name + "\n"
  }
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
    if pos < len && body[pos] == (',' : UInt16) { pos = pos + 1 }
  }
  fields
}

priv struct EnumVariant {
  name : String
  field_types : Array[String]
  is_tuple : Bool
  field_names : Array[String]
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
      let gen_names = gen_field_names(types.0.length())
      variants.push({ name: name_res.0, field_types: types.0, is_tuple: true, field_names: gen_names })
    } else if pos < len && body[pos] == ('{' : UInt16) {
      let fields_res = read_record_fields(body, pos)
      pos = fields_res.1
      let names = fields_res.0.map(fn(f) { f.0 })
      let types = fields_res.0.map(fn(f) { f.1 })
      variants.push({ name: name_res.0, field_types: types, is_tuple: false, field_names: names })
    } else {
      variants.push({ name: name_res.0, field_types: [], is_tuple: false, field_names: [] })
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
    if pos < len && s[pos] == (',' : UInt16) { pos = pos + 1 }
  }
  if pos < len { pos = pos + 1 }
  (fields, pos)
}

fn gen_field_names(count : Int) -> Array[String] {
  let names : Array[String] = []
  let letters = "abcdefghijklmnopqrstuvwxyz"
  for i in 0..<count {
    if i < 26 {
      names.push(letters[i:i + 1].to_owned())
    } else {
      names.push("x" + i.to_string())
    }
  }
  names
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
    if (c == (',' : UInt16) || c == ('}' : UInt16) || c == ('\n' : UInt16) || c == ('\r' : UInt16) || c == ('\t' : UInt16)) && depth == 0 { break }
    if c == ('<' : UInt16) || c == ('[' : UInt16) || c == ('(' : UInt16) { depth = depth + 1 }
    if c == ('>' : UInt16) || c == (']' : UInt16) || c == (')' : UInt16) { depth = depth - 1 }
    pos = pos + 1
  }
  (s[start:pos].trim().to_owned(), pos)
}

fn generate_show(name : String, kind : String, generics : String, body : String) -> String {
  let full_name = type_with_generics(name, generics)
  if kind == "enum" {
    return generate_show_enum(name, generics, full_name, body)
  }
  let fields = parse_struct_fields(body)
  if fields.length() == 0 {
    return "pub fn " + name + "::to_string(self : " + full_name + ") -> String { \"" + name + "\" }\n"
  }
  let buf = StringBuilder()
  buf.write_string("pub fn " + name + "::to_string(self : " + full_name + ") -> String {\n")
  buf.write_string("  let parts : Array[String] = [\n")
  for f in fields {
    buf.write_string("    \"" + f.0 + "=\" + self." + f.0 + ".to_string(),\n")
  }
  buf.write_string("  ]\n")
  buf.write_string("  \"" + name + "(\" + parts.join(\", \") + \")\"\n")
  buf.write_string("}\n")
  buf.to_string()
}

fn generate_show_enum(name : String, _generics : String, full_name : String, body : String) -> String {
  let variants = parse_enum_variants(body)
  if variants.length() == 0 {
    return "pub fn " + name + "::to_string(self : " + full_name + ") -> String { \"" + name + "\" }\n"
  }
  let buf = StringBuilder()
  buf.write_string("pub fn " + name + "::to_string(self : " + full_name + ") -> String {\n")
  buf.write_string("  match self {\n")
  for v in variants {
    buf.write_string("    ")
    if v.field_types.length() == 0 {
      buf.write_string(v.name + " => \"" + v.name + "\"\n")
    } else if v.is_tuple {
      let params = v.field_names.join(", ")
      let parts : Array[String] = v.field_names.map(fn(n) { n + ".to_string()" })
      buf.write_string(v.name + "(" + params + ") => \"" + v.name + "(\" + " + parts.join(" + \", \" + ") + " + \")\"\n")
    } else {
      let names = v.field_names
      let parts : Array[String] = names.map(fn(n) { "\"" + n + "=\" + " + n + ".to_string()" })
      let pat = "{ " + names.join(", ") + " }"
      buf.write_string(pat + " => \"" + v.name + "(\" + " + parts.join(" + \", \" + ") + " + \")\"\n")
    }
  }
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

fn generate_eq(name : String, kind : String, generics : String, body : String) -> String {
  let full_name = type_with_generics(name, generics)
  if kind == "enum" {
    return generate_eq_enum(name, generics, full_name, body)
  }
  let fields = parse_struct_fields(body)
  if fields.length() == 0 {
    return "pub fn " + name + "::op_equal(self : " + full_name + ", other : " + full_name + ") -> Bool { true }\n"
  }
  let buf = StringBuilder()
  buf.write_string("pub fn " + name + "::op_equal(self : " + full_name + ", other : " + full_name + ") -> Bool {\n")
  let conds : Array[String] = fields.map(fn(f) { "self." + f.0 + " == other." + f.0 })
  buf.write_string("  " + conds.join(" && ") + "\n")
  buf.write_string("}\n")
  buf.to_string()
}

fn generate_eq_enum(name : String, _generics : String, full_name : String, body : String) -> String {
  let variants = parse_enum_variants(body)
  let buf = StringBuilder()
  buf.write_string("pub fn " + name + "::op_equal(self : " + full_name + ", other : " + full_name + ") -> Bool {\n")
  buf.write_string("  match (self, other) {\n")
  for v in variants {
    if v.field_types.length() == 0 {
      buf.write_string("    (" + v.name + ", " + v.name + ") => true\n")
    } else if v.is_tuple {
      let conds : Array[String] = v.field_names.map(fn(n) { n + "0 == " + n + "1" })
      buf.write_string("    (" + v.name + "(" + v.field_names.map(fn(n) { n + "0" }).join(", ") + "), " +
        v.name + "(" + v.field_names.map(fn(n) { n + "1" }).join(", ") + ")) => " +
        conds.join(" && ") + "\n")
    } else {
      let names = v.field_names
      let conds : Array[String] = names.map(fn(n) { n + "0 == " + n + "1" })
      let pat0 = "{ " + names.map(fn(n) { n + ": " + n + "0" }).join(", ") + " }"
      let pat1 = "{ " + names.map(fn(n) { n + ": " + n + "1" }).join(", ") + " }"
      buf.write_string("    (" + pat0 + ", " + pat1 + ") => " + conds.join(" && ") + "\n")
    }
  }
  buf.write_string("    _ => false\n")
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

fn generate_to_json(name : String, kind : String, generics : String, body : String) -> String {
  let full_name = type_with_generics(name, generics)
  if kind == "enum" {
    return generate_to_json_enum(name, generics, full_name, body)
  }
  let fields = parse_struct_fields(body)
  if fields.length() == 0 {
    return "pub fn " + name + "::to_json(self : " + full_name + ") -> Json { { \"type\": \"" + name + "\" } }\n"
  }
  let buf = StringBuilder()
  buf.write_string("pub fn " + name + "::to_json(self : " + full_name + ") -> Json {\n")
  buf.write_string("  {\n")
  for f in fields {
    buf.write_string("    \"" + f.0 + "\": self." + f.0 + ".to_json(),\n")
  }
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

fn generate_to_json_enum(name : String, _generics : String, full_name : String, body : String) -> String {
  let variants = parse_enum_variants(body)
  if variants.length() == 0 {
    return "pub fn " + name + "::to_json(self : " + full_name + ") -> Json { { \"type\": \"" + name + "\" } }\n"
  }
  let buf = StringBuilder()
  buf.write_string("pub fn " + name + "::to_json(self : " + full_name + ") -> Json {\n")
  buf.write_string("  match self {\n")
  for v in variants {
    if v.field_types.length() == 0 {
      buf.write_string("    " + v.name + " => { \"type\": \"" + v.name + "\" },\n")
    } else if v.is_tuple {
      let params = v.field_names.join(", ")
      let values = v.field_names.map(fn(n) { n + ".to_json()" })
      buf.write_string("    " + v.name + "(" + params + ") => { \"type\": \"" + v.name + "\", \"value\": " + values.join(", ") + " },\n")
    } else {
      let pat = "{ " + v.field_names.join(", ") + " }"
      let values = v.field_names.map(fn(n) { "\"" + n + "\": " + n + ".to_json()" })
      buf.write_string("    " + pat + " => { \"type\": \"" + v.name + "\", " + values.join(", ") + " },\n")
    }
  }
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

fn generate_clone(name : String, kind : String, generics : String, body : String) -> String {
  let full_name = type_with_generics(name, generics)
  if kind == "enum" {
    return generate_clone_enum(name, generics, full_name, body)
  }
  let fields = parse_struct_fields(body)
  if fields.length() == 0 {
    return "pub fn " + name + "::clone(self : " + full_name + ") -> " + full_name + " { " + name + " }\n"
  }
  let buf = StringBuilder()
  buf.write_string("pub fn " + name + "::clone(self : " + full_name + ") -> " + full_name + " {\n")
  let assigns : Array[String] = fields.map(fn(f) { f.0 + ": self." + f.0 + ".clone()" })
  buf.write_string("  { " + assigns.join(", ") + " }\n")
  buf.write_string("}\n")
  buf.to_string()
}

fn generate_clone_enum(name : String, _generics : String, full_name : String, body : String) -> String {
  let variants = parse_enum_variants(body)
  let buf = StringBuilder()
  buf.write_string("pub fn " + name + "::clone(self : " + full_name + ") -> " + full_name + " {\n")
  buf.write_string("  match self {\n")
  for v in variants {
    if v.field_types.length() == 0 {
      buf.write_string("    " + v.name + " => " + v.name + ",\n")
    } else if v.is_tuple {
      let params = v.field_names.join(", ")
      let cloned = v.field_names.map(fn(n) { n + ".clone()" })
      buf.write_string("    " + v.name + "(" + params + ") => " + v.name + "(" + cloned.join(", ") + "),\n")
    } else {
      let pat = "{ " + v.field_names.join(", ") + " }"
      let cloned = v.field_names.map(fn(n) { n + ": " + n + ".clone()" })
      buf.write_string("    " + pat + " => { " + cloned.join(", ") + " },\n")
    }
  }
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}
