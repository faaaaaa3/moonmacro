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

  println("=== 4. Derive Constructor for struct ===\n")
  let src4 = parts[3]
  println("Input:")
  println(src4)
  let r4 = @moonmacro.expand_file(src4, @moonmacro.find_macro_defs(src4))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r4))
  println("")

  println("=== 5. Derive Getters for struct ===\n")
  let src5 = parts[4]
  println("Input:")
  println(src5)
  let r5 = @moonmacro.expand_file(src5, @moonmacro.find_macro_defs(src5))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r5))
  println("")

  println("=== 6. Derive EnumFromStr for enum ===\n")
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
  println("")

  println("=== 9. dbg! ===\n")
  let src9 = parts[8]
  println("Input:")
  println(src9)
  let r9 = @moonmacro.expand_file(src9, @moonmacro.find_macro_defs(src9))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r9))
  println("")

  println("=== 10. let_array! ===\n")
  let src10 = parts[9]
  println("Input:")
  println(src10)
  let r10 = @moonmacro.expand_file(src10, @moonmacro.find_macro_defs(src10))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r10))
  println("")

  println("=== 11. call_each! ===\n")
  let src11 = parts[10]
  println("Input:")
  println(src11)
  let r11 = @moonmacro.expand_file(src11, @moonmacro.find_macro_defs(src11))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r11))
  println("")

  println("=== 12. repeat! ===\n")
  let src12 = parts[11]
  println("Input:")
  println(src12)
  let r12 = @moonmacro.expand_file(src12, @moonmacro.find_macro_defs(src12))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r12))
  println("")

  println("=== 13. inspect! ===\n")
  let src13 = parts[12]
  println("Input:")
  println(src13)
  let r13 = @moonmacro.expand_file(src13, @moonmacro.find_macro_defs(src13))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r13))
  println("")

  println("=== 14. echo! ===\n")
  let src14 = parts[13]
  println("Input:")
  println(src14)
  let r14 = @moonmacro.expand_file(src14, @moonmacro.find_macro_defs(src14))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r14))
  println("")

  println("=== 15. logger! ===\n")
  let src15 = parts[14]
  println("Input:")
  println(src15)
  let r15 = @moonmacro.expand_file(src15, @moonmacro.find_macro_defs(src15))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r15))
  println("")

  println("=== 16. timeit! ===\n")
  let src16 = parts[15]
  println("Input:")
  println(src16)
  let r16 = @moonmacro.expand_file(src16, @moonmacro.find_macro_defs(src16))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r16))
  println("")

  println("=== 17. tryn! ===\n")
  let src17 = parts[16]
  println("Input:")
  println(src17)
  let r17 = @moonmacro.expand_file(src17, @moonmacro.find_macro_defs(src17))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r17))
  println("")

  println("=== 18. Custom derive marker ===\n")
  let src18 = parts[17]
  println("Input:")
  println(src18)
  let r18 = @moonmacro.expand_file(src18, @moonmacro.find_macro_defs(src18))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r18))
  println("")

  println("=== 19. Custom derive ToTuple ===\n")
  let src19 = parts[18]
  println("Input:")
  println(src19)
  let r19 = @moonmacro.expand_file(src19, @moonmacro.find_macro_defs(src19))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r19))
  println("")

  println("=== 20. Custom derive EnumInfo ===\n")
  let src20 = parts[19]
  println("Input:")
  println(src20)
  let r20 = @moonmacro.expand_file(src20, @moonmacro.find_macro_defs(src20))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r20))
  println("")

  println("=== 21. Custom derive FieldNames ===\n")
  let src21 = parts[20]
  println("Input:")
  println(src21)
  let r21 = @moonmacro.expand_file(src21, @moonmacro.find_macro_defs(src21))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r21))
  println("")

  println("=== 22. Custom derive AllMeta ===\n")
  let src22 = parts[21]
  println("Input:")
  println(src22)
  let r22 = @moonmacro.expand_file(src22, @moonmacro.find_macro_defs(src22))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r22))
  println("")

  println("=== 23. Custom derive ShowType ===\n")
  let src23 = parts[22]
  println("Input:")
  println(src23)
  let r23 = @moonmacro.expand_file(src23, @moonmacro.find_macro_defs(src23))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r23))
  println("")

  println("=== 24. Custom derive StructInfo ===\n")
  let src24 = parts[23]
  println("Input:")
  println(src24)
  let r24 = @moonmacro.expand_file(src24, @moonmacro.find_macro_defs(src24))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r24))
  println("")

  println("=== 25. Custom derive EnumMeta ===\n")
  let src25 = parts[24]
  println("Input:")
  println(src25)
  let r25 = @moonmacro.expand_file(src25, @moonmacro.find_macro_defs(src25))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r25))
  println("")

  println("=== 26. Custom derive FullInfo ===\n")
  let src26 = parts[25]
  println("Input:")
  println(src26)
  let r26 = @moonmacro.expand_file(src26, @moonmacro.find_macro_defs(src26))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r26))
  println("")

  println("=== 27. Enum field_types with fielded variants ===\n")
  let src27 = parts[26]
  println("Input:")
  println(src27)
  let r27 = @moonmacro.expand_file(src27, @moonmacro.find_macro_defs(src27))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r27))
  println("")

  println("=== 28. matches! ===\n")
  let src28 = parts[27]
  println("Input:")
  println(src28)
  let r28 = @moonmacro.expand_file(src28, @moonmacro.find_macro_defs(src28))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r28))
  println("")

  println("=== 29. todo! ===\n")
  let src29 = parts[28]
  println("Input:")
  println(src29)
  let r29 = @moonmacro.expand_file(src29, @moonmacro.find_macro_defs(src29))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r29))
  println("")

  println("=== 30. Macro with [] and {} delimiters ===\n")
  let src30 = parts[29]
  println("Input:")
  println(src30)
  let r30 = @moonmacro.expand_file(src30, @moonmacro.find_macro_defs(src30))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r30))
  println("")

  println("=== 31. Derive on generic struct ===\n")
  let src31 = parts[30]
  println("Input:")
  println(src31)
  let r31 = @moonmacro.expand_file(src31, @moonmacro.find_macro_defs(src31))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r31))
  println("")

  println("=== 32. No expansion inside strings/comments ===\n")
  let src32 = parts[31]
  println("Input:")
  println(src32)
  let r32 = @moonmacro.expand_file(src32, @moonmacro.find_macro_defs(src32))
  println("Output:")
  println(@moonmacro.strip_macro_defs(r32))
}

fn demo_parts() -> Array[String] {
  [
    "macro_rules! greet {\n  ($name:expr) => {\n    fn greet_$name() -> String { \"Hello, $name!\" }\n  }\n}\ngreet!(World)\n",
    "macro_rules! make_tuple {\n  ($($item:expr),*) => {\n    ($($item),*)\n  }\n}\nlet tup = make_tuple!(1, 2, 3)\n",
    "macro_rules! double { ($x:expr) => { $x * 2 } }\nmacro_rules! apply { ($f:expr) => { double!($f) } }\nlet result = apply!(21)\n",
    "#[macro_derive(Constructor)]\nstruct Point {\n  x: Int\n  y: Int\n}\n",
    "#[macro_derive(Getters)]\nstruct Point {\n  x: Int\n  y: Int\n}\n",
    "#[macro_derive(EnumFromStr)]\nenum Color {\n  Red\n  Green\n  Blue\n}\n",
    "let s = stringify!(hello world)\n",
    "assert!(x > 0)\nassert!(x > 0 && y < 10 || z == 0)\n",
    "fn main {\n  let x = 42\n  let y = dbg!(x + 1)\n  println(y.to_string())\n}\n",
    "let_array!(mut a, mut b, c = state, start: 1)\n",
    "call_each!(m.add, \"a\", \"b\", \"bc\")\ncall_each!(map.insert, (\"k1\", 1), (\"k2\", 2))\n",
    "let state = [repeat!(Array::make(4, 0), 4)]\n",
    "inspect!(m.get(\"C\"), \"Some(1)\")\n",
    "echo!(x, y)\necho!(1 + 2, fn(v) { v * 2 })\n",
    "logger!(fn add(x: Int, y: Int) -> Int {\n  x + y\n})\n",
    "timeit!(fn compute() -> Int {\n  99\n})\n",
    "tryn!(read_line(), 3)\n",
    "macro_derive! MyMarker {\n  pub fn $T::is_active(self: $T) -> Bool { true }\n}\n#[macro_derive(MyMarker)]\nstruct Config {\n  debug: Bool\n}\n",
    "macro_derive! ToTuple {\n  pub fn $T::to_tuple(self: $T) -> ($field_types) { ($fields) }\n}\n#[macro_derive(ToTuple)]\nstruct Point {\n  x: Int\n  y: Int\n}\n",
    "macro_derive! EnumInfo {\n  pub fn $T::variant_count() -> Int { \"$variants\".split(\", \").length() }\n  pub fn $T::kind() -> String { \"$kind\" }\n}\n#[macro_derive(EnumInfo)]\nenum Color {\n  Red\n  Green\n  Blue\n}\n",
    "macro_derive! FieldNames {\n  pub fn $T::field_names() -> Array[String] { [\"$fields\"].flat_map(fn(s) { s.split(\", \") }) }\n}\n#[macro_derive(FieldNames)]\nstruct Point {\n  x: Int\n  y: Int\n}\n",
    "macro_derive! AllMeta {\n  pub fn $T::type_name() -> String { \"$T\" }\n  pub fn $T::kind() -> String { \"$kind\" }\n  pub fn $T::generics_str() -> String { \"$generics\" }\n  pub fn $T::fields_str() -> String { \"$fields\" }\n  pub fn $T::field_types_str() -> String { \"$field_types\" }\n  pub fn $T::variants_str() -> String { \"$variants\" }\n  pub fn $T::body_str() -> String { \"$body\" }\n  pub fn $T::display_name() -> String { \"$Name\" }\n}\n#[macro_derive(AllMeta)]\nstruct Point {\n  x: Int\n  y: String\n}\n",
    "macro_derive! ShowType {\n  pub fn $T::show_type() -> String { \"$kind $T$generics\" }\n}\n#[macro_derive(ShowType)]\nstruct Wrap {\n  value: Int\n}\n",
    "macro_derive! StructInfo {\n  pub fn $T::field_names() -> String { \"$fields\" }\n  pub fn $T::field_type_str() -> String { \"$field_types\" }\n  pub fn $T::struct_body() -> String { \"$body\" }\n}\n#[macro_derive(StructInfo)]\nstruct Point {\n  x: Int\n  y: String\n}\n",
    "macro_derive! EnumMeta {\n  pub fn $T::variant_names() -> String { \"$variants\" }\n  pub fn $T::is_enum() -> Bool { \"$kind\" == \"enum\" }\n}\n#[macro_derive(EnumMeta)]\nenum Color {\n  Red\n  Green\n  Blue\n}\n",
    "macro_derive! FullInfo {\n  pub fn $T::full_type_name() -> String { \"$Name ($T)\" }\n  pub fn $T::kind_str() -> String { \"$kind\" }\n  pub fn $T::generics_str() -> String { \"$generics\" }\n  pub fn $T::fields_str() -> String { \"$fields\" }\n  pub fn $T::field_types_str() -> String { \"$field_types\" }\n  pub fn $T::variants_str() -> String { \"$variants\" }\n  pub fn $T::body_str() -> String { \"$body\" }\n}\n#[macro_derive(FullInfo)]\nstruct Point {\n  x: Int\n  y: String\n}\n",
    "macro_derive! FieldTypes {\n  pub fn $T::field_types_str() -> String { \"$field_types\" }\n}\n#[macro_derive(FieldTypes)]\nenum Result {\n  Ok(Int)\n  Err(String)\n}\n",
    "matches!(result, Ok(val))\nmatches!(x, Some(y) if y > 0)\n",
    "todo!()\ntodo!(\"need to implement this\")\n",
    "macro_rules! foo { ($($x:expr),*) => { ($($x),*) } }\nmacro_rules! bar { ($a:expr, $b:expr) => { $a + $b } }\nfoo![1, 2, 3]\nbar!{a, b}\n",
    "#[macro_derive(Constructor)]\nstruct Wrap[T] {\n  value: T\n}\n",
    "macro_rules! skip_test { ($x:expr) => { fn skip_$x() {} } }\nprintln(\"skip_test!(me) inside string\")\n// skip_test!(me) in comment\nskip_test!(me)\n",
  ]
}
