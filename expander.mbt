pub fn expand_template(template : String, captures : Map[String, Array[String]]) -> String {
  let frags = parse_pattern(template)
  expand_fragments(frags, captures, 0)
}

fn expand_fragments(frags : Array[PatternFragment], captures : Map[String, Array[String]], iteration : Int) -> String {
  let result = StringBuilder()
  for frag in frags {
    match frag {
      Lit(s) => result.write_string(s)
      Capture(name, _kind) => {
        if captures.contains(name) {
          let vals = captures[name]
          if iteration < vals.length() {
            result.write_string(vals[iteration])
          } else if vals.length() > 0 {
            result.write_string(vals[0])
          }
        }
      }
      Repetition(inner, rep_sep, _op) => {
        let count = get_repetition_count(inner, captures)
        for i in 0..<count {
          if i > 0 { result.write_string(rep_sep) }
          let expanded = expand_fragments(inner, captures, i)
          result.write_string(expanded)
        }
      }
    }
  }
  result.to_string()
}

fn get_repetition_count(inner : Array[PatternFragment], captures : Map[String, Array[String]]) -> Int {
  find_max_capture(inner, captures)
}

fn find_max_capture(frags : Array[PatternFragment], captures : Map[String, Array[String]]) -> Int {
  let mut max = 0
  for f in frags {
    match f {
      Capture(name, _kind) => {
        if captures.contains(name) {
          let len = captures[name].length()
          if len > max { max = len }
        }
      }
      Repetition(inner, _sep, _op) => {
        let inner_max = find_max_capture(inner, captures)
        if inner_max > max { max = inner_max }
      }
      _ => ()
    }
  }
  max
}

pub fn expand_file(source : String, defs : Array[MacroDef]) -> String {
  let mut result = source
  let max_passes = 10
  for _pass in 0..<max_passes {
    let before = result
    result = expand_pass(result, defs)
    if result == before { break }
  }
  result
}

fn expand_pass(source : String, defs : Array[MacroDef]) -> String {
  let invocations = find_macro_invocations(source, defs)
  if invocations.length() == 0 { return source }
  let sorted = sort_invocations_by_pos(invocations)
  let mut result = source
  let mut result_len = result.length()
  for inv in sorted {
    let s = invocation_start(inv)
    let e = invocation_end(inv)
    if s < 0 || e > result_len || s >= e { continue }
    let before = result[0:s].to_owned()
    let after = result[e:result_len].to_owned()
    let replacement = match inv {
      FuncCall(name, args, _delim, _s, _e) => {
        let expanded = match expand_macro_call(name, args, defs) {
          Some(code) => Some(code)
          None => expand_builtin(name, args)
        }
        match expanded {
          None => result[s:e].to_owned()
          Some(code) => code
        }
      }
      Derive(_traits, name, kind, generics, body, _s, _e) => {
        let impls = generate_derives(_traits, name, kind, generics, body)
        kind + " " + name + generics + " " + body + "\n" + impls
      }
    }
    result = before + replacement + after
    result_len = result.length()
  }
  result
}

pub fn strip_macro_defs(source : String) -> String {
  let ranges : Array[(Int, Int)] = []
  let mut pos : Int = 0
  let len = source.length()
  while pos < len {
    if is_at(source, pos, "macro_rules!") {
      let start = pos
      pos = pos + "macro_rules!".length()
      pos = skip_ws(source, pos)
      let _name_res = read_ident(source, pos)
      pos = _name_res.1
      pos = skip_ws(source, pos)
      let body_res = read_balanced(source, pos)
      pos = body_res.1
      ranges.push((start, pos))
    } else {
      pos = pos + 1
    }
  }
  let n = ranges.length()
  let mut i = 1
  while i < n {
    let key = ranges[i]
    let mut j : Int = i
    while j > 0 && ranges[j - 1].0 < key.0 {
      ranges[j] = ranges[j - 1]
      j = j - 1
    }
    ranges[j] = key
    i = i + 1
  }
  let mut result = source
  for r in ranges {
    let s = r.0
    let e = r.1
    let before = result[0:s].to_owned()
    let after = result[e:].to_owned()
    result = before + after
  }
  result
}

fn sort_invocations_by_pos(invs : Array[MacroInvocation]) -> Array[MacroInvocation] {
  let sorted = invs
  let n = sorted.length()
  let mut i = 1
  while i < n {
    let key = sorted[i]
    let key_start = invocation_start(key)
    let mut j : Int = i
    while j > 0 && invocation_start(sorted[j - 1]) < key_start {
      sorted[j] = sorted[j - 1]
      j = j - 1
    }
    sorted[j] = key
    i = i + 1
  }
  sorted
}


