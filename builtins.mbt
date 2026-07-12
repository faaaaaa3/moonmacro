pub fn expand_builtin(name : String, args : String) -> String? {
  match name {
    "assert" => Some("if !(" + args + ") { abort(\"assertion failed: " + args + "\") }")
    "stringify" => Some("\"" + args + "\"")
    _ => None
  }
}
