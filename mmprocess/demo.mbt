fn demo_walkthrough() -> Unit {
  let parts = demo_parts()
  println("=== 1. Basic macro: greet! ===\n")

  let src1 = parts[0]
  println("Input:")
  println(src1)
  let d1 = @moonmacro.find_macro_defs(src1)
  let r1 = @moonmacro.expand_file(src1, d1)
  println("Output:")
  println(@moonmacro.strip_macro_defs(r1))
  println("")

  println("=== 2. Repetition: make_tuple! ===\n")
  let src2 = parts[1]
  println("Input:")
  println(src2)
  let d2 = @moonmacro.find_macro_defs(src2)
  let r2 = @moonmacro.expand_file(src2, d2)
  println("Output:")
  println(@moonmacro.strip_macro_defs(r2))
  println("")

  println("=== 3. Builtin vec! ===\n")
  let src3 = parts[2]
  println("Input:")
  println(src3)
  let d3 = @moonmacro.find_macro_defs(src3)
  let r3 = @moonmacro.expand_file(src3, d3)
  println("Output:")
  println(@moonmacro.strip_macro_defs(r3))
  println("")

  println("=== 4. Nested expansion ===\n")
  let src4 = parts[3]
  println("Input:")
  println(src4)
  let d4 = @moonmacro.find_macro_defs(src4)
  let r4 = @moonmacro.expand_file(src4, d4)
  println("Output:")
  println(@moonmacro.strip_macro_defs(r4))
  println("")

  println("=== 5. Derive Show + Eq for struct ===\n")
  let src5 = parts[4]
  println("Input:")
  println(src5)
  let d5 = @moonmacro.find_macro_defs(src5)
  let r5 = @moonmacro.expand_file(src5, d5)
  println("Output:")
  println(@moonmacro.strip_macro_defs(r5))
  println("")

  println("=== 6. Derive Show + Eq for enum ===\n")
  let src6 = parts[5]
  println("Input:")
  println(src6)
  let d6 = @moonmacro.find_macro_defs(src6)
  let r6 = @moonmacro.expand_file(src6, d6)
  println("Output:")
  println(@moonmacro.strip_macro_defs(r6))
  println("")

  println("=== 7. Derive Clone + ToJson for generic enum ===\n")
  let src7 = parts[6]
  println("Input:")
  println(src7)
  let d7 = @moonmacro.find_macro_defs(src7)
  let r7 = @moonmacro.expand_file(src7, d7)
  println("Output:")
  println(@moonmacro.strip_macro_defs(r7))
  println("")

  println("=== 8. stringify! and concat! ===\n")
  let src8 = parts[7]
  println("Input:")
  println(src8)
  let d8 = @moonmacro.find_macro_defs(src8)
  let r8 = @moonmacro.expand_file(src8, d8)
  println("Output:")
  println(@moonmacro.strip_macro_defs(r8))
}

fn demo_parts() -> Array[String] {
  [
    "macro_rules! greet {\n  ($name:expr) => {\n    fn greet_$name() -> String { \"Hello, $name!\" }\n  }\n}\ngreet!(World)\n",
    "macro_rules! make_tuple {\n  ($($item:expr),*) => {\n    ($($item),*)\n  }\n}\nlet tup = make_tuple!(1, 2, 3)\n",
    "let nums = vec![1, 2, 3]\n",
    "macro_rules! double { ($x:expr) => { $x * 2 } }\nmacro_rules! apply { ($f:expr) => { double!($f) } }\nlet result = apply!(21)\n",
    "#[macro_derive(Show, Eq)]\nstruct Point {\n  x: Int\n  y: Int\n}\n",
    "#[macro_derive(Show, Eq)]\nenum Color {\n  Red\n  Green(Int)\n  Blue(Int, String)\n}\n",
    "#[macro_derive(Clone, ToJson)]\nenum Option[T] {\n  Some(T)\n  None\n}\n",
    "let s = stringify!(hello world)\nlet msg = concat!(\"Hello, \", \"World!\")\n",
  ]
}
