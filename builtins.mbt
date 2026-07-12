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
    _ => None
  }
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
