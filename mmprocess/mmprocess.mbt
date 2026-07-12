fn main {
  let args = @env.args()
  if args.length() > 1 && args[1] == "--demo" {
    demo_walkthrough()
    return
  }
  if args.length() < 2 {
    println("Usage: " + args[0] + " <source_text>")
    println("       " + args[0] + " --demo")
    return
  }
  let source = args[1]
  let defs = @moonmacro.find_macro_defs(source)
  let expanded = @moonmacro.expand_file(source, defs)
  println(@moonmacro.strip_macro_defs(expanded))
}
