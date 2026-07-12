pub fn expand_builtin(name : String, args : String) -> String? {
  match name {
    "vec" => Some("[" + args + "]")
    "println" => Some("println(" + args + ")")
    "eprintln" => Some("eprintln(" + args + ")")
    "assert" => Some("if !(" + args + ") { abort(\"assertion failed: " + args + "\") }")
    "todo" => Some("abort(\"not implemented\")")
    "unreachable" => Some("abort(\"unreachable\")")
    "concat" => {
      let parts = parse_comma_list(args)
      let out = StringBuilder()
      for p in parts {
        let trimmed = p.trim().to_owned()
        if trimmed.length() >= 2 && trimmed[0:1].to_owned() == "\"" && trimmed[trimmed.length() - 1:trimmed.length()].to_owned() == "\"" {
          out.write_string(trimmed[1:trimmed.length() - 1].to_owned())
        } else {
          out.write_string(trimmed)
        }
      }
      Some("\"" + out.to_string() + "\"")
    }
    "stringify" => Some("\"" + args + "\"")
    "compile_error" => Some("abort(" + args + ")")
    "include_str" => Some("\"<inlined from " + args + ">\"")
    _ => None
  }
}
