# MoonMacro 使用手册

MoonMacro 是一个面向 MoonBit 语言的构建时宏系统（编译期预处理器），
提供声明式 `macro_rules!` 宏定义、模式匹配展开、
`#[macro_derive]` 自动派生以及 13 个内置实用宏。

**版本**: 0.2.2 / **许可证**: MIT / **模块路径**: `faaaaaa3/moonmacro`

[GitHub](https://github.com/faaaaaa3/moonmacro) · [Mooncakes](https://mooncakes.io/docs/faaaaaa3/moonmacro)


## 1. 安装与使用

### 1.1 安装

**前置要求**: 需安装 [MoonBit 工具链](https://www.moonbitlang.com/download/)。

```bash
git clone https://github.com/faaaaaa3/moonmacro
cd moonmacro

# 一键构建并安装到 ~/.local/bin/
./moonmacro.sh install
```

安装后 `~/.local/bin/` 中有两个文件：

| 文件 | 用途 |
|------|------|
| `mmprocess` | 核心二进制，展开宏 |
| `moonmacro.sh` | 批量预处理脚本 |

确保 `~/.local/bin/` 在 `PATH` 中即可全局使用。

### 1.2 mmprocess（核心二进制）

```bash
mmprocess --demo                       # 运行演示
mmprocess "source code here"           # 展开单段源文本如
mmprocess "stringify!(hello)"
# 批量预处理请用 moonmacro.sh（见 1.3 节）
```

### 1.3 moonmacro.sh（批量预处理）

自动查找目录中所有 `.mbt.macro` 文件（递归处理所有子目录）并展开为 `.mbt`：

```bash
moonmacro.sh src/                      # 处理整个目录
moonmacro.sh src/main.mbt.macro        # 处理单个文件
moonmacro.sh                           # 默认处理当前目录
```

### 1.4 构建系统集成

在 Makefile 中添加预处理步骤：

```makefile
preprocess:
    moonmacro.sh src/
build: preprocess
    moon build
```

### 1.5 作为库依赖

在 `moon.pkg` 的 `import` 中添加：

```
import {
  "faaaaaa3/moonmacro",
}
```

同时在 `moon.mod` 中添加依赖声明：

```
import {
  "faaaaaa3/moonmacro@0.2.2",
}
```

#### 核心 API

| 函数 | 说明 |
|------|------|
| `find_macro_defs(source : String) -> Array[MacroDef]` | 扫描源码提取所有 `macro_rules!` 定义 |
| `expand_file(source : String, defs : Array[MacroDef]) -> String` | 展开源码中所有宏调用（多轮直到不动点） |
| `strip_macro_defs(source : String) -> String` | 移除 `macro_rules!` 和 `macro_derive!` 定义声明 |

完整示例（保存为 `main.mbt`，运行 `moon run main`）：

```moonbit
fn main {
  let source = #|macro_rules! greet {
#|  ($name:expr) => {
#|    fn greet_$name() -> String { "Hello, $name!" }
#|  }
#|}
#|
#|greet!(World)
#|
#|#[macro_derive(Constructor, Getters)]
#|struct Point { x: Int; y: Int }
#|
#|macro_rules! double { ($x:expr) => { $x * 2 } }
#|macro_rules! apply { ($f:expr) => { double!($f) } }
#|
#|macro_rules! make_tuple {
#|  ($($item:expr),*) => {
#|    ($($item),*)
#|  }
#|}
#|
#|//inspect!(x, "42")
#|logger!(fn add(x: Int, y: Int) -> Int {
#|  x + y
#|})
#|
#|timeit!(fn minus(x: Int, y: Int) -> Int {
#|  for   i = 0; i < 10000000; i = i + 1{
#|    let _ = x + y
#|  }
#|  x - y
#|})
#|#[macro_derive(EnumFromStr)]
#|enum Color {
#|  Red
#|  Green
#|  Blue
#|}
#|fn print_pair(a:Int,b:Int) -> Unit {
#|  echo!(a,b)
#|}
#|
#|fn main {
#|  call_each!(print_pair, (1,2), (3,4), (5,6))
#|
#|  let c:Color? =  Color::from_string("Red")
#|  println(matches!(c, Some(Red)))
#|  let u = add(2,3)
#|  let u = minus(2,3)
#|  let tup = make_tuple!(1, 2, 3)
#|  let s = stringify!(hello world)
#|  let result = apply!(21)
#|  println(result)
#|  let p = Point::new(1, 2)
#|  println("\{p.x()}, \{p.y()}")
#|  println(greet_World())
#|  let x = 0
#|  let y = 2
#|  let u = "assert!(x>9)"
#|  let b = matches!(Ok(2), Ok(1))
#|  println(b)
#|  let y = dbg!(x + 1)
#|  echo!(y)
#|
#|  let arr = [repeat!(1, 4)]
#|  let_array!(a, b, c = arr)
#|  // -> let a = arr[0]; let b = arr[1]; let c = arr[2]
#|
#|  let state = [repeat!(1, 4)]
#|  let_array!(mut a, mut b = state)
#|  // -> let mut a = state[0]; let mut b = state[1]
#|
#|  let data = [repeat!(1, 4)]
#|  let_array!(mut a, b, mut c = data)
#|  // -> let mut a = data[0]; let b = data[1]; let mut c = data[2]
#|
#|  let items = [repeat!(1, 20)]
#|  let_array!(a, b, c = items, start: 5)
#|  // -> let a = items[5]; let b = items[6]; let c = items[7]
#|
#|  let v = repeat!(a, 3, +)
#|
#|  let x = 42
#|
#|  //todo!("fix later")
#|  //assert!(x > 0)
#|  // -> if !(x > 0) { abort("assertion failed: x > 0") }
#|  //assert!(x > 0 && y < 10)
#|  // -> if !(x > 0 && y < 10) { abort("assertion failed: x > 0 && y < 10") }
#|}
#|
  let defs = @moonmacro.find_macro_defs(source)
  let expanded = @moonmacro.expand_file(source, defs)
  let clean = @moonmacro.strip_macro_defs(expanded)
  println(clean)
}
```


## 2. 工作流程

项目中用 `.mbt.macro` 文件编写含宏的代码，预处理后展开为纯 `.mbt`：

```
项目/
  src/
    main.mbt.macro     # 含 macro_rules! 和 #[macro_derive]
    lib.mbt.macro
    utils.mbt          # 纯 MoonBit，无需预处理

步骤:
  1. 编写 .mbt.macro 文件
  2. moonmacro.sh src/
  3. .mbt.macro → .mbt（宏已展开）
  4. moon build
```

**完整示例**（保存为 `main.mbt.macro`，运行 `moonmacro.sh . && moon run src/main.mbt`）：

```moonbit
macro_rules! greet {
  ($name:expr) => {
    fn greet_$name() -> String { "Hello, $name!" }
  }
}

greet!(World)

#[macro_derive(Constructor, Getters)]
struct Point { x: Int; y: Int }

fn main {
  let p = Point::new(1, 2)
  println("\{p.x()}, \{p.y()}")
  println(greet_World())
}
```

预处理后展开为：

```moonbit
fn greet_World() -> String { "Hello, World!" }

struct Point { x: Int; y: Int }

pub fn Point::new(x: Int, y: Int) -> Point { { x, y } }
pub fn Point::x(self: Point) -> Int { self.x }
pub fn Point::y(self: Point) -> Int { self.y }

fn main {
  let p = Point::new(1, 2)
  println("\{p.x()}, \{p.y()}")
  println(greet_World())
}
```


## 3. 内置宏

无需导入即可使用。在用户定义宏匹配失败后自动尝试内置宏。

### 3.1 assert!

生成带错误消息的断言：

```moonbit
assert!(x > 0)
// -> if !(x > 0) { println("assertion failed: x > 0"); abort("") }

assert!(x > 0 && y < 10)
// -> if !(x > 0 && y < 10) { println("assertion failed: x > 0 && y < 10"); abort("") }
```

### 3.2 stringify!

将参数文本原样字面量化为字符串：

```moonbit
let s = stringify!(hello world)  // -> let s = "hello world"
let op = stringify!(x + y)       // -> let op = "x + y"
```

### 3.3 matches!

模式匹配表达式，返回 `Bool`；表达式与模式类型必须兼容（同 MoonBit `match` 规则）：

```moonbit
let b = matches!(result, Ok(val))
// -> let b = match result { Ok(val) => true; _ => false }
```

参数用逗号分隔：第一个是表达式，第二个是模式。

### 3.4 todo!

占位宏，标记未完成的代码：

```moonbit
fn unimplemented() -> Int {
  todo!()  // -> println("not implemented"); abort("")
}

todo!("fix this later")  // -> println("fix this later"); abort("")
```

### 3.5 dbg!

调试宏：输出 `[dbg] 表达式 = 值`，并返回该值。

```moonbit
fn main {
  let x = 42
  let y = dbg!(x + 1)
}
// 展开为:
// fn main {
//   let x = 42
//   let y = {
//     let __dbg_val = x + 1
//     println("[dbg] " + "x + 1" + " = " + __dbg_val.to_string())
//     __dbg_val
//   }
// }
// 运行时输出: [dbg] x + 1 = 42
```

### 3.6 let_array!

将数组元素展开为多个 `let` 绑定，避免重复手写 `let a = arr[0]; let b = arr[1]` 等代码。支持 `mut` 前缀和起始位置偏移。

```moonbit
let_array!(a, b, c = arr)
// -> let a = arr[0]; let b = arr[1]; let c = arr[2]

let_array!(mut a, mut b = state)
// -> let mut a = state[0]; let mut b = state[1]

let_array!(mut a, b, mut c = data)
// -> let mut a = data[0]; let b = data[1]; let mut c = data[2]

let_array!(a, b, c = items, start: 5)
// -> let a = items[5]; let b = items[6]; let c = items[7]
```

### 3.7 repeat!

重复生成某个表达式多次，用指定分隔符连接，避免手动重复书写相同代码。

```moonbit
let state = [repeat!(Array::make(4, 0), 4)]
// -> [Array::make(4, 0), Array::make(4, 0), Array::make(4, 0), Array::make(4, 0)]

repeat!(42, 3)
// -> 42, 42, 42

repeat!(x, 3, +)
// -> x+x+x

repeat!(x, 3, ; )
// -> x; x; x
```

**参数**:
1. 要重复的表达式
2. 重复次数（必须 ≥ 1）
3. 分隔符（可选，默认为 `, `）

### 3.8 call_each!

批量调用同一个方法，避免重复手写 `m.add("a"); m.add("b"); m.add("bc")` 等代码。支持单参数和多参数两种模式。

**单参数模式**：每个逗号分隔项作为一个参数。

```moonbit
call_each!(m.add, "a", "b", "bc")
// -> m.add("a"); m.add("b"); m.add("bc")

call_each!(m.add, 1, 2, 3)
// -> m.add(1); m.add(2); m.add(3)
```

**多参数模式**：用圆括号 `()` 包裹多个参数，括号内的逗号不会被误解为参数分隔。

```moonbit
call_each!(map.insert, ("k1", 1), ("k2", 2))
// -> map.insert("k1", 1); map.insert("k2", 2)

call_each!(f, (1, 2, 3), (4, 5, 6))
// -> f(1, 2, 3); f(4, 5, 6)
```

### 3.9 inspect!

`inspect!(expr, "expected")` 是 `@debug.debug_inspect(expr, content="expected")` 的简写，用于测试断言。

```moonbit
inspect!(x, "42")
// -> @debug.debug_inspect(x, content="42")

inspect!(m.get("C"), "Some(1)")
// -> @debug.debug_inspect(m.get("C"), content="Some(1)")
```

**参数**:
1. 要检查的表达式
2. 期望值（字符串字面量或表达式），自动作为 `content` 命名参数传入

### 3.10 echo!

`echo!(varname, ...)` 展开为 `println("varname1 = \{varname1}, varname2 = \{varname2}, ...")`，用于调试时快速打印多个变量名和值。

```moonbit
let x = 42
let y = "hello"
echo!(x, y)
// -> println("x = \{x}, y = \{y}")
// Output: x = 42, y = hello
```

**参数**: 一个或多个变量名，逗号分隔

### 3.11 logger!

`logger!(fn funcName(...) -> ReturnType { body })` 在函数体开头插入 `defer` 和日志打印：

```moonbit
logger!(fn add(x: Int, y: Int) -> Int {
  x + y
})
// → fn add(x: Int, y: Int) -> Int {
//     defer { println("leaving add") }
//     println("entering add")
//     x + y
//   }
```

`defer` 保证离开日志在函数退出时执行，不影响返回值。

### 3.12 timeit!

`timeit!(fn funcName(...) -> ReturnType { body })` 测量函数执行耗时：

```moonbit
timeit!(fn compute() -> Int {
  99
})
// → fn compute() -> Int {
//     let __timeit_start = @env.now()
//     defer { println("compute took " + (@env.now() - __timeit_start).to_string() + "ms") }
//     99
//   }
```

### 3.13 tryn!

`tryn!(expr, n)` 尝试执行表达式 `expr` 最多 `n` 次，返回第一个 `Some(val)`；若全部失败则返回 `None`：

```moonbit
tryn!(read_line(), 3)
// → {
//     let __tryn_max = 3
//     let mut __tryn_i = 0
//     let __tryn_val = loop {
//       if __tryn_i >= __tryn_max { break None }
//       __tryn_i = __tryn_i + 1
//       let __tryn_cur = read_line()
//       if __tryn_cur is Some(_) { break __tryn_cur }
//     }
//     __tryn_val
//   }
```

---

## 4. 用户宏（macro_rules!）

### 4.1 基本语法

```moonbit
macro_rules! 宏名 {
  (模式1) => { 模板1 }
  (模式2) => { 模板2 }
}
```

模式支持 `$变量名:类型` 捕获和 `$($inner),*` 重复。

### 4.2 简单示例

```moonbit
macro_rules! greet {
  ($name:expr) => {
    fn greet_$name() -> String { "Hello, $name!" }
  }
}
greet!(World)
// → fn greet_World() -> String { "Hello, World!" }
```

### 4.3 重复匹配

```moonbit
macro_rules! make_tuple {
  ($($item:expr),*) => { ($($item),*) }
}
let tup = make_tuple!(1, 2, 3)
// → let tup = (1, 2, 3)
```

### 4.4 嵌套展开

宏展开支持嵌套：一轮展开产生新的宏调用，下一轮继续展开，最多 10 轮。

```moonbit
macro_rules! double { ($x:expr) => { $x * 2 } }
macro_rules! apply { ($f:expr) => { double!($f) } }
let result = apply!(21)
// → let result = 21 * 2
```

---

## 5. 自动派生 #[macro_derive]

`#[macro_derive(Trait1, Trait2)]` 为 struct 或 enum 自动生成 trait 实现代码。
多个 trait 可以放在同一个 `#[macro_derive(...)]` 中，也可以用连续多行堆叠。

### 5.1 Constructor

为 struct 生成 `new()` 构造函数。**仅支持 struct**，至少需要一个字段。

```moonbit
#[macro_derive(Constructor)]
struct Point {
  x: Int
  y: Int
}
// 生成:
// pub fn Point::new(x: Int, y: Int) -> Point { { x, y } }
```



### 5.2 Getters

为 struct 生成与字段同名的 getter 方法。**仅支持 struct**，至少需要一个字段。

```moonbit
#[macro_derive(Getters)]
struct Point {
  x: Int
  y: String
}
// 生成:
// pub fn Point::x(self: Point) -> Int { self.x }
// pub fn Point::y(self: Point) -> String { self.y }
```



### 5.3 EnumFromStr

为 enum 生成 `from_string` 解析函数。**仅支持 enum**，至少需要一个单元变体。
数据变体（带字段）被自动跳过。

```moonbit
#[macro_derive(EnumFromStr)]
enum Color {
  Red
  Green
  Blue
}
// 生成:
// pub fn Color::from_string(s: String) -> Color? {
//   match s {
//     "Red" => Some(Color::Red)
//     "Green" => Some(Color::Green)
//     "Blue" => Some(Color::Blue)
//     _ => None
//   }
// }
// 
// 使用:
// let c = Color::from_string("Red")   // -> Some(Color::Red)
// let d = Color::from_string("X")     // -> None
```

支持泛型 enum：

```moonbit
#[macro_derive(EnumFromStr)]
enum Box[T] {
  Item(T)
  Empty
}
// 生成:
// pub fn[T] Box::from_string(s: String) -> Box[T]? {
//   match s {
//     "Empty" => Some(Box::Empty)
//     _ => None
//   }
// }
// 
// 使用:
// let o = Box::from_string("Empty")    // -> Some(Box::Empty)
// let p = Box::from_string("Item")     // -> None（Item 是数据变体，被跳过）
```

### 5.4 自定义 derive（macro_derive!）

用 `macro_derive! Name { template }` 自定义派生宏，用 `#[macro_derive(Name)]` 使用。

模板变量：
- `$T` / `$type` — 类型名
- `$body` — 类型体原文
- `$kind` — `"struct"` 或 `"enum"`
- `$generics` — 泛型声明（如 `"[T]"`）
- `$Name` — 首字母大写
- `$fields` — 逗号分隔的字段名列表（仅 struct）
- `$field_types` — 逗号分隔的字段类型列表（struct 和 enum 均可）
- `$variants` — 逗号分隔的变体名列表（仅 enum）

```moonbit
macro_derive! MyMarker {
  pub fn $T::is_active(self: $T) -> Bool { true }
}

#[macro_derive(MyMarker)]
struct Config { debug: Bool }
// → pub fn Config::is_active(self: Config) -> Bool { true }
```

更多示例（全部模板变量都用到了）：

```moonbit
// 自动生成 to_tuple 方法（struct）— 用 $fields, $field_types
macro_derive! ToTuple {
  pub fn $T::to_tuple(self: $T) -> ($field_types) { ($fields) }
}

// 变体计数 + 类型名（enum）— 用 $variants, $kind
macro_derive! EnumInfo {
  pub fn $T::variant_count() -> Int { "$variants".split(", ").length() }
  pub fn $T::kind() -> String { "$kind" }
}

// 字段名列表（struct）— 用 $fields
macro_derive! FieldNames {
  pub fn $T::field_names() -> Array[String] {
    ["$fields"].flat_map(fn(s) { s.split(", ") })
  }
}

// 全类型元数据 — 用 $T $Name $kind $generics $fields $field_types $variants $body
macro_derive! AllMeta {
  pub fn $T::type_name() -> String { "$T" }
  pub fn $T::display_name() -> String { "$Name" }
  pub fn $T::kind() -> String { "$kind" }
  pub fn $T::generics_str() -> String { "$generics" }
  pub fn $T::fields_str() -> String { "$fields" }
  pub fn $T::field_types_str() -> String { "$field_types" }
  pub fn $T::variants_str() -> String { "$variants" }
  pub fn $T::body_str() -> String { "$body" }
}

// 显示类型签名 — 用 $kind $T $generics
macro_derive! ShowType {
  pub fn $T::show_type() -> String { "$kind $T$generics" }
}

// struct 专用元数据 — 用 $fields $field_types $body
macro_derive! StructInfo {
  pub fn $T::field_names() -> String { "$fields" }
  pub fn $T::field_type_str() -> String { "$field_types" }
  pub fn $T::struct_body() -> String { "$body" }
}

// enum 专用元数据 — 用 $variants $kind
macro_derive! EnumMeta {
  pub fn $T::variant_names() -> String { "$variants" }
  pub fn $T::is_enum() -> Bool { "$kind" == "enum" }
}

// 全部变量
macro_derive! FullInfo {
  pub fn $T::full_type_name() -> String { "$Name ($T)" }
  pub fn $T::kind_str() -> String { "$kind" }
  pub fn $T::generics_str() -> String { "$generics" }
  pub fn $T::fields_str() -> String { "$fields" }
  pub fn $T::field_types_str() -> String { "$field_types" }
  pub fn $T::variants_str() -> String { "$variants" }
  pub fn $T::body_str() -> String { "$body" }
}

// $field_types 也支持带字段的 enum
macro_derive! FieldTypes {
  pub fn $T::field_types_str() -> String { "$field_types" }
}
#[macro_derive(FieldTypes)]
enum Result {
  Ok(Int)
  Err(String)
}
// => pub fn Result::field_types_str() -> String { "Int, String" }
```

优先级：built-in > custom > unknown。


## 6. 架构

### 6.1 文件结构

| 文件 | 用途 |
|------|------|
| `reader.mbt` | 宏定义与调用的扫描器 |
| `builtins.mbt` | 13 个内置宏的实现 |
| `derive.mbt` | 3 个内置 derive + 自定义 derive 支持 |
| `expander.mbt` | 多轮展开引擎 |
| `pattern.mbt` | 模式解析与匹配 |
| `mmprocess/mmprocess.mbt` | CLI 入口 |
| `mmprocess/demo.mbt` | 32 部分演示 |
| `test/test.mbt` | 单元测试 |
| `verify/verify.mbt` | 集成测试 |
| `lib/e2e_*/` | 端到端编译测试 |
| `moonmacro.sh` | 批量预处理脚本 |
| `scripts/e2e_test.sh` | 端到端测试运行器 |
| `.github/workflows/ci.yml` | CI 配置 |

### 6.2 当前实现范围

| 项目 | 支持 |
|------|------|
| `macro_rules!` 定义 | 完整 |
| 内置宏（assert, echo, dbg 等） | 13 个 |
| derive 宏（Constructor, Getters, EnumFromStr） | 3 个内置 + 自定义 |
| 泛型 derive | 支持 |
| 重复匹配 `$()*` `$()+` | 支持 |
| 文本内 `//` 注释跳过 | 支持 |
| 文本内 `#|…|#` / `$|…|#` 字符串跳过 | 支持 |
| 导出为库 | 支持 |


### 6.3 设计原则

- **纯文本预处理**: 不依赖 MoonBit 解析器或 AST
- **零外部依赖**: 只使用 MoonBit 标准库
- **声明式宏**: 模式匹配语法
- **即插即用**: 内置宏无需导入

### 6.4 参考

- Rust 声明式宏参考：<https://doc.rust-lang.org/reference/macros-by-example.html>
- Rust 仓库：<https://github.com/rust-lang/rust>（License: Apache-2.0）
- MoonBit 语言文档：<https://docs.moonbitlang.com>
- 项目仓库：<https://github.com/faaaaaa3/moonmacro>
