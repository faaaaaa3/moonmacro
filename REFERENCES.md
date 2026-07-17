# References

MoonMacro is inspired by and references the following projects:

## Rust `macro_rules!` (Declarative Macros)

MoonMacro's syntax and design are directly inspired by Rust's
[declarative macros (`macro_rules!`)](https://doc.rust-lang.org/reference/macros-by-example.html).

Key similarities:
- `macro_rules! name { ($pattern) => { $template } }` syntax
- Pattern matching with `$var:expr` / `$var:ident` matchers
- Repetition with `$($inner),*` syntax
- `#[macro_derive(...)]` attribute-style derive macros (similar to Rust's `#[derive(...)]`)

MoonMacro is a pure-text preprocessor and does **not** use `syn`, `quote`, or `proc_macro`
from the Rust ecosystem. It operates entirely on MoonBit source text with no AST dependency.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file.
