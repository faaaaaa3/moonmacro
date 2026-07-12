fn demo_walkthrough() -> Unit {
  let parts = demo_parts()

  println("=== 1. Basic macro: greet! ===\n")
  let src1 = parts[0]
  println("Input:")
  println(src1)
  let r1 = @moonmacro.expand_file(src1, @moonmacro.find_macro_defs(src1))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r1))
  println("")

  println("=== 2. Repetition: make_tuple! ===\n")
  let src2 = parts[1]
  println("Input:")
  println(src2)
  let r2 = @moonmacro.expand_file(src2, @moonmacro.find_macro_defs(src2))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r2))
  println("")

  println("=== 3. Nested expansion ===\n")
  let src3 = parts[2]
  println("Input:")
  println(src3)
  let r3 = @moonmacro.expand_file(src3, @moonmacro.find_macro_defs(src3))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r3))
  println("")

  println("=== 4. Derive ToJson for struct ===\n")
  let src4 = parts[3]
  println("Input:")
  println(src4)
  let r4 = @moonmacro.expand_file(src4, @moonmacro.find_macro_defs(src4))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r4))
  println("")

  println("=== 5. Derive ToJson for enum ===\n")
  let src5 = parts[4]
  println("Input:")
  println(src5)
  let r5 = @moonmacro.expand_file(src5, @moonmacro.find_macro_defs(src5))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r5))
  println("")

  println("=== 6. Derive ToJson for generic enum ===\n")
  let src6 = parts[5]
  println("Input:")
  println(src6)
  let r6 = @moonmacro.expand_file(src6, @moonmacro.find_macro_defs(src6))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r6))
  println("")

  println("=== 7. stringify! ===\n")
  let src7 = parts[6]
  println("Input:")
  println(src7)
  let r7 = @moonmacro.expand_file(src7, @moonmacro.find_macro_defs(src7))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r7))
  println("")

  println("=== 8. assert! ===\n")
  let src8 = parts[7]
  println("Input:")
  println(src8)
  let r8 = @moonmacro.expand_file(src8, @moonmacro.find_macro_defs(src8))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r8))
}

fn demo_parts() -> Array[String] {
  [
    "macro_rules! greet {\n  ($name:expr) => {\n    fn greet_$name() -> String { \"Hello, $name!\" }\n  }\n}\ngreet!(World)\n",
    "macro_rules! make_tuple {\n  ($($item:expr),*) => {\n    ($($item),*)\n  }\n}\nlet tup = make_tuple!(1, 2, 3)\n",
    "macro_rules! double { ($x:expr) => { $x * 2 } }\nmacro_rules! apply { ($f:expr) => { double!($f) } }\nlet result = apply!(21)\n",
    "#[macro_derive(ToJson)]\nstruct Point {\n  x: Int\n  y: Int\n}\n",
    "#[macro_derive(ToJson)]\nenum Color {\n  Red\n  Green(Int)\n  Blue(Int, String)\n}\n",
    "#[macro_derive(ToJson)]\nenum Option[T] {\n  Some(T)\n  None\n}\n",
    "let s = stringify!(hello world)\n",
    "assert!(x > 0)\n",
  ]
}
