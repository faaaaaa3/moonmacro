pub(all) enum PatternFragment {
  Lit(String)
  Capture(String, String)
  Repetition(Array[PatternFragment], String, RepeatOp)
}

pub(all) enum RepeatOp {
  ZeroOrMore
  OneOrMore
}

pub fn parse_pattern(s : String) -> Array[PatternFragment] {
  let frags : Array[PatternFragment] = []
  let mut pos : Int = 0
  let len = s.length()
  let mut literal_start : Int = 0
  while pos < len {
    if pos + 1 < len && s[pos] == ('$' : UInt16) && s[pos + 1] == ('(' : UInt16) {
      if literal_start < pos {
        frags.push(Lit(s[literal_start:pos].to_owned()))
      }
      pos = pos + 2
      let inner_res = read_balanced(s, pos - 1)
      let inner_raw = inner_res.0
      pos = inner_res.1
      let sep_start = pos
      while pos < len && s[pos] != ('*' : UInt16) && s[pos] != ('+' : UInt16) {
        pos = pos + 1
      }
      let sep = s[sep_start:pos].to_owned()
      let op = if pos < len && s[pos] == ('+' : UInt16) { OneOrMore } else { ZeroOrMore }
      if pos < len { pos = pos + 1 }
      if inner_raw.length() >= 2 {
        let inner_pat = inner_raw[1:inner_raw.length() - 1].to_owned()
        let inner_frags = parse_pattern(inner_pat)
        frags.push(Repetition(inner_frags, sep, op))
      }
      literal_start = pos
    } else if pos + 1 < len && s[pos] == ('$' : UInt16) && s[pos + 1] != ('$' : UInt16) {
      if literal_start < pos {
        frags.push(Lit(s[literal_start:pos].to_owned()))
      }
      pos = pos + 1
      let name_start = pos
      while pos < len {
        let c = s[pos]
        let is_valid = (c >= ('a' : UInt16) && c <= ('z' : UInt16)) ||
          (c >= ('A' : UInt16) && c <= ('Z' : UInt16)) ||
          c == ('_' : UInt16) ||
          (pos > name_start && c >= ('0' : UInt16) && c <= ('9' : UInt16))
        if is_valid { pos = pos + 1 } else { break }
      }
      let name = s[name_start:pos].to_owned()
      if pos < len && s[pos] == (':' : UInt16) {
        pos = pos + 1
        let kind_start = pos
        while pos < len {
          let c = s[pos]
          let is_kind = (c >= ('a' : UInt16) && c <= ('z' : UInt16)) ||
            (c >= ('A' : UInt16) && c <= ('Z' : UInt16)) ||
            c == ('_' : UInt16)
          if is_kind { pos = pos + 1 } else { break }
        }
        frags.push(Capture(name, s[kind_start:pos].to_owned()))
      } else {
        frags.push(Capture(name, "expr"))
      }
      literal_start = pos
    } else if pos + 1 < len && s[pos] == ('$' : UInt16) && s[pos + 1] == ('$' : UInt16) {
      if literal_start < pos {
        frags.push(Lit(s[literal_start:pos].to_owned()))
      }
      frags.push(Lit("$"))
      pos = pos + 2
      literal_start = pos
    } else {
      pos = pos + 1
    }
  }
  if literal_start < len {
    frags.push(Lit(s[literal_start:len].to_owned()))
  }
  frags
}

pub fn match_pattern(pattern : String, input : String) -> Map[String, Array[String]]? {
  let fragments = parse_pattern(pattern)
  let captures : Map[String, Array[String]] = {}
  let input_str = input.trim().to_owned()
  let result = match_fragments(fragments, captures, input_str, 0)
  match result {
    None => None
    Some((final_captures, end_pos)) => {
      if end_pos < input_str.length() { None }
      else { Some(final_captures) }
    }
  }
}

fn match_fragments(
  frags : Array[PatternFragment],
  captures : Map[String, Array[String]],
  input : String,
  start : Int
) -> (Map[String, Array[String]], Int)? {
  let mut cap = captures
  let mut pos = start
  let len = input.length()
  for frag in frags {
    match frag {
      Lit(lit) => {
        let trimmed = lit.trim()
        if trimmed.length() > 0 {
          let view = input[pos:len]
          match view.find(trimmed) {
            None => { return None }
            Some(found_pos) => {
              if found_pos != 0 { return None }
              pos = pos + found_pos + trimmed.length()
            }
          }
        }
      }
      Capture(name, _kind) => {
        let after_frags = fragments_after(frags, frag)
        let raw_delim = next_literal_text(after_frags)
        let delim = raw_delim.trim().to_owned()
        let captured = if delim.length() > 0 {
          let view = input[pos:len]
          match view.find(delim) {
            None => {
              if pos < len { input[pos:len].to_owned() } else { return None }
            }
            Some(end_pos) => { input[pos:pos + end_pos].to_owned() }
          }
        } else {
          if pos < len { input[pos:len].to_owned() } else { return None }
        }
        let trimmed_val = captured.trim().to_owned()
        if cap.contains(name) {
          cap[name].push(trimmed_val)
        } else {
          cap[name] = [trimmed_val]
        }
        pos = if delim.length() > 0 {
          let view = input[pos:len]
          match view.find(delim) {
            None => len
            Some(p) => pos + p
          }
        } else { len }
      }
      Repetition(inner, sep, op) => {
        let trimmed_sep = sep.trim().to_owned()
        let after_frags = fragments_after(frags, frag)
        let stop_delim = next_literal_text(after_frags)
        let portion_end = if stop_delim.length() > 0 {
          let view = input[pos:len]
          match view.find(stop_delim) {
            None => len
            Some(p) => pos + p
          }
        } else { len }
        let portion = input[pos:portion_end].to_owned()
        let parts = if trimmed_sep.length() > 0 {
          split_balanced(portion, trimmed_sep, 0)
        } else {
          if portion.trim().length() > 0 { [portion.trim().to_owned()] } else { [] }
        }
        if parts.length() == 0 && op is OneOrMore { return None }
        if parts.length() == 0 {
          let inner_names = collect_capture_names(inner)
          for n in inner_names {
            if !cap.contains(n) { cap[n] = [] }
          }
        } else {
          for part in parts {
            let inner_result = match_fragments(inner, cap, part, 0)
            match inner_result {
              None => { if op is OneOrMore { return None } }
              Some((new_cap, _end)) => {
                cap = new_cap
              }
            }
          }
        }
        pos = portion_end
      }
    }
  }
  Some((cap, pos))
}

fn split_balanced(s : String, sep : String, start : Int) -> Array[String] {
  let result : Array[String] = []
  let mut pos = start
  let len = s.length()
  let mut depth = 0
  let mut segment_start = start
  while pos < len {
    let c = s[pos]
    if c == ('(' : UInt16) || c == ('[' : UInt16) || c == ('{' : UInt16) { depth = depth + 1 }
    else if c == (')' : UInt16) || c == (']' : UInt16) || c == ('}' : UInt16) { depth = depth - 1 }
    else if depth == 0 {
      let is_sep = if pos + sep.length() <= len {
        s[pos:pos + sep.length()].to_owned() == sep
      } else { false }
      if is_sep {
        result.push(s[segment_start:pos].trim().to_owned())
        pos = pos + sep.length()
        segment_start = pos
        // skip leading whitespace after separator
        while segment_start < len {
          let ch = s[segment_start]
          if ch == (' ' : UInt16) || ch == ('\t' : UInt16) || ch == ('\n' : UInt16) || ch == ('\r' : UInt16) { segment_start = segment_start + 1 } else { break }
        }
        pos = segment_start
        continue
      }
    }
    pos = pos + 1
  }
  if segment_start < len {
    let last = s[segment_start:len].trim().to_owned()
    if last.length() > 0 { result.push(last) }
  }
  result
}

fn collect_capture_names(frags : Array[PatternFragment]) -> Array[String] {
  let names : Array[String] = []
  for f in frags {
    match f {
      Capture(n, _) => names.push(n)
      Repetition(inner, _, _) => {
        let inner_names = collect_capture_names(inner)
        for n in inner_names { names.push(n) }
      }
      _ => ()
    }
  }
  names
}

fn fragments_after(frags : Array[PatternFragment], current : PatternFragment) -> Array[PatternFragment] {
  let mut found = false
  let result : Array[PatternFragment] = []
  for f in frags {
    if found {
      result.push(f)
    } else {
      if fragment_equal(f, current) { found = true }
    }
  }
  result
}

fn next_literal_text(frags : Array[PatternFragment]) -> String {
  for f in frags {
    match f {
      Lit(s) => {
        let t = s.trim()
        if t.length() > 0 { return t.to_owned() }
      }
      _ => ()
    }
  }
  ""
}

fn repeat_op_equal(a : RepeatOp, b : RepeatOp) -> Bool {
  match (a, b) {
    (ZeroOrMore, ZeroOrMore) => true
    (OneOrMore, OneOrMore) => true
    _ => false
  }
}

fn fragment_equal(a : PatternFragment, b : PatternFragment) -> Bool {
  match (a, b) {
    (Lit(s1), Lit(s2)) => s1 == s2
    (Capture(n1, k1), Capture(n2, k2)) => n1 == n2 && k1 == k2
    (Repetition(i1, s1, o1), Repetition(i2, s2, o2)) => s1 == s2 && repeat_op_equal(o1, o2) && i1.length() == i2.length()
    _ => false
  }
}


