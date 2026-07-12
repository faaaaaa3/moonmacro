# MoonMacro 使用手册

MoonMacro 是一个面向 MoonBit 语言的构建时宏系统（编译期预处理器），
提供声明式 `macro_rules!` 宏定义、模式匹配展开、
`#[macro_derive]` 自动派生以及一系列内置实用宏。

**版本**: 0.1.0
**许可证**: MIT
**模块路径**: faaaaaa3/moonmacro


## 1. 概述与设计思想

### 1.1 什么是构建时宏？

构建时宏是在代码编译之前执行代码变换的程序。与运行时函数调用不同，宏在构建阶段展开，可以：

- **生成重复代码**: 避免手写样板代码
- **实现 DSL**: 创建自定义语法
- **条件编译**: 根据条件包含或排除代码
- **自动派生**: 为类型自动实现 trait

### 1.2 设计原则

1. **纯文本预处理**: 不依赖 MoonBit 解析器或 AST
2. **零外部依赖**: 只使用 MoonBit 标准库
3. **声明式宏**: 采用类似 Rust macro_rules! 的模式匹配语法
4. **即插即用**: 内置宏无需导入即可使用

---

## 2. 快速开始

### 2.1 添加依赖

在 `moon.mod.json` 中添加 moonmacro 依赖：

```json
{
  "import": {
    "faaaaaa3/moonmacro": "0.1.2"
  }
}
```

### 2.2 完整示例

以下示例展示了 MoonMacro 的核心功能：用户宏、内置宏和派生宏。

```moonbit
// 用户宏
macro_rules! greet {
  ($name:expr) => {
    fn greet_$name() -> String { "Hello, $name!" }
  }
}
macro_rules! make_tuple {
  ($($item:expr),*) => { ($($item),*) }
}
greet!(World)
let tup = make_tuple!(1, 2, 3)

// 内置宏
assert!(x > 0)
let s = stringify!(hello world)
let result = todo!("not yet implemented")
let matched = matches!(x, Some(v))
let val = dbg!(compute())

// 派生宏
#[macro_derive(Constructor, Getters)]
struct Point {
  x: Int
  y: Int
}

#[macro_derive(EnumFromStr)]
enum Color { Red; Green; Blue }
```

---

## 3. 作为构建时预处理器使用

### 3.1 工作流程

MoonMacro 的核心定位是构建时预处理器。在 MoonBit 项目中先用 `.mbt.macro` 文件编写代码，然后通过预处理器展开为纯 `.mbt` 文件。

```
你的 MoonBit 项目/
  src/
    main.mbt.macro     # 含 macro_rules! 和 #[macro_derive]
    lib.mbt.macro      # 混合宏调用和普通代码
    utils.mbt          # 纯 MoonBit 文件，无需预处理

步骤:
  1. 编写 .mbt.macro 文件
  2. 运行: ./moonmacro.sh src/
  3. .mbt.macro 文件变为纯 .mbt 文件
  4. 运行 moon build
```

### 3.2 文件命名约定

| 扩展名 | 说明 |
|---------|------|
| `.mbt.macro` | 需要预处理的源文件 |
| `.mbt` | 纯 MoonBit 源码 |
| `.mbt.macro` -> `.mbt` | 预处理后去除 `.macro` 后缀 |

### 3.3 moonmacro.sh 脚本

`moonmacro.sh` 自动查找目录中的 `.mbt.macro` 文件并调用 `mmprocess` 展开：

```bash
./moonmacro.sh src/               # 处理整个目录
./moonmacro.sh src/main.mbt.macro  # 处理单个文件
./moonmacro.sh                     # 默认处理当前目录
```

### 3.4 与构建系统集成

将 `moonmacro.sh` 复制到项目或创建软链接，然后在 Makefile 中添加预处理步骤：

```makefile
MMROOT = /path/to/moonmacro
preprocess:
    $(MMROOT)/moonmacro.sh src/
build: preprocess
    moon build
.PHONY: preprocess build
```


## 5. 内置宏

MoonMacro 提供 9 个内置宏，无需手动导入。在用户定义宏匹配失败后自动尝试内置宏。

### 5.1 assert!

生成带错误消息的断言：

```moonbit
assert!(x > 0)
// -> if !(x > 0) { abort("assertion failed: x > 0") }

assert!(x > 0 && y < 10)
// -> if !(x > 0 && y < 10) { abort("assertion failed: x > 0 && y < 10") }
```

### 5.2 stringify!

将参数文本原样字面量化为字符串：

```moonbit
let s = stringify!(hello world)  // -> let s = "hello world"
let op = stringify!(x + y)       // -> let op = "x + y"
```

### 5.3 matches!

模式匹配表达式，返回 `Bool`：

```moonbit
let b = matches!(result, Ok(val))
// -> let b = match result { Ok(val) => true, _ => false }
```

参数用逗号分隔：第一个是表达式，第二个是模式。

### 5.4 todo!

占位宏，标记未完成的代码：

```moonbit
fn unimplemented() -> Int {
  todo!()  // -> abort("not implemented")
}

todo!("fix this later")  // -> abort("fix this later")
```

### 5.5 dbg!

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

`dbg!` 通过多轮展开实现：首轮生成包含 `stringify!` 的代码，次轮展开 `stringify!` 得到带引号的表达式文本。

### 5.6 let_array!

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

### 5.7 repeat!

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

### 5.8 call_each!

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

**混合模式**：单参数与多参数可以混用。

```moonbit
call_each!(f, a, (b, c), d)
// -> f(a); f(b, c); f(d)
```

### 5.9 inspect!

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

---

## 6. 自动派生 #[macro_derive]

`#[macro_derive(Trait1, Trait2)]` 为 struct 或 enum 自动生成 trait 实现代码。
多个 trait 可以放在同一个 `#[macro_derive(...)]` 中，也可以用连续多行堆叠。

### 6.1 Constructor

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



### 6.2 Getters

为 struct 生成 PascalCase 命名的 getter 方法。**仅支持 struct**，至少需要一个字段。
方法名首字母大写（如 `x` -> `X()`），与字段访问（`point.x`）区分。

```moonbit
#[macro_derive(Getters)]
struct Point {
  x: Int
  y: String
}
// 生成:
// pub fn Point::X(self: Point) -> Int { self.x }
// pub fn Point::Y(self: Point) -> String { self.y }
```



### 6.3 EnumFromStr

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
//     "Red" => Some(Red),
//     "Green" => Some(Green),
//     "Blue" => Some(Blue),
//     _ => None
//   }
// }
```


## 8. 架构说明

### 8.1 文件结构

| 文件 | 用途 |
|------|------|
| `reader.mbt` | 宏定义与宏调用的扫描器 |
| `builtins.mbt` | 5 个内置宏的实现 |
| `derive.mbt` | 3 个 derive 的实现 |
| `expander.mbt` | 多轮展开引擎 |
| `mmprocess/mmprocess.mbt` | CLI 入口 |
| `mmprocess/demo.mbt` | 9 部分演示 |
| `test/test.mbt` | 单元测试 |
| `verify/verify.mbt` | 集成测试 |
| `moonmacro.sh` | Bash 预处理脚本 |



## 9. 命令行工具

### 9.1 mmprocess（核心二进制）

编译为 `mmprocess.exe`，通过 `mmprocess --demo` 或直接接受源文本。

```bash
moon build --target native
mmprocess --demo                     # 运行 9 部分演示
mmprocess "source code here"          # 展开源文本
mmprocess < input.mbt.macro > out.mbt  # 从 stdin 读取
```

### 9.2 moonmacro.sh（Bash 包装器）

用于批量处理目录中的所有 `.mbt.macro` 文件。

```bash
moonmacro.sh [目录]     # 处理目录中的 .mbt.macro 文件
moonmacro.sh install    # 构建并安装到 ~/.local/bin/
```

安装后会将两个文件放入 `~/.local/bin/`：
- `mmprocess`（二进制）
- `moonmacro.sh`（包装脚本）

---

## 10. API 参考

### 10.1 expand_file 函数

最常用的库入口函数。扫描宏定义、展开宏调用和 derive，然后去除宏定义。

```moonbit
fn expand_file(text: String) -> String
```

**参数**: `text` — 包含 `macro_rules!` 定义和宏调用的源代码字符串

**返回值**: 展开后不含宏定义的纯 MoonBit 代码

### 10.2 expand_pass 函数

执行一轮展开。

```moonbit
fn expand_pass(text: String, defs: Array[MacroDef]) -> String
```

