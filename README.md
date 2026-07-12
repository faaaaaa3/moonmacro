# MoonMacro 使用手册

MoonMacro 是一个面向 MoonBit 语言的编译期宏系统（构建时预处理器），
提供了类似 Rust macro_rules! 的声明式宏定义、模式匹配展开、
#[macro_derive] 自动派生以及一系列内置实用宏。

**版本**: 0.1.0
**许可证**: MIT
**模块路径**: aaa/moonmacro


---

## 1. 概述与设计思想

### 1.1 什么是编译期宏？

编译期宏是在代码编译之前执行代码变换的程序。与运行时函数调用不同，
宏在编译阶段展开，可以：

- **生成重复代码**: 避免手写样板代码
- **实现 DSL**: 创建自定义语法
- **条件编译**: 根据条件包含或排除代码
- **自动派生**: 为类型自动实现 trait

### 1.2 设计原则

MoonMacro 遵循以下设计原则：

1. **纯文本预处理**: 不依赖 MoonBit 解析器或 AST，对任何文本进行模式匹配和替换
2. **零外部依赖**: 只使用 MoonBit 标准库，无第三方依赖
3. **声明式宏**: 采用类似 Rust macro_rules! 的模式匹配语法
5. **即插即用**: 内置宏无需导入即可使用

---

## 2. 快速开始

### 2.1 添加依赖

在 moon.mod.json 中添加 moonmacro 依赖：

```json
{
  "import": {
    "aaa/moonmacro": "0.1.0"
  }
}
```

### 2.2 完整示例

```moonbit
// 定义宏
macro_rules! greet {
  ($name:expr) => {
    fn greet_$name() -> String { "Hello, $name!" }
  }
}

// 定义带重复的宏
macro_rules! make_tuple {
  ($($item:expr),*) => {
    ($($item),*)
  }
}

// 调用宏
greet!(World)
let tup = make_tuple!(1, 2, 3)

// 使用内置宏
let nums = vec![1, 2, 3]
println!("nums = " + nums.to_string())

// 使用 derive
#[macro_derive(Show, Eq)]
struct Point {
  x: Int
  y: Int
}
```

### 2.3 以库方式调用

```moonbit
let source = "macro_rules! double { ($x:expr) => { $x * 2 } }\ndouble!(21)"
let defs = @moonmacro.find_macro_defs(source)
let result = @moonmacro.expand_file(source, defs)
println(result)
// 输出:
//   macro_rules! double { ($x:expr) => { $x * 2 } }
//   21 * 2
```

### 2.4 查看细节

```moonbit
let source = "greet!(World)"
let defs = @moonmacro.find_macro_defs(source)
// defs[0].name == "greet"
// defs[0].patterns[0].pattern == "$name:expr"
// defs[0].patterns[0].template == 'fn greet_$name() -> String { "Hello, $name!" }'

let invocations = @moonmacro.find_macro_invocations(source, defs)
// invocations[0] == FuncCall("greet", "World", "(", 0, 14)

let expanded = @moonmacro.expand_macro_call("greet", "World", defs)
// expanded == Some('fn greet_World() -> String { "Hello, World!" }')
```


## 3. 在其他 MoonBit 项目中使用（作为构建时预处理器）

moonmacro 的核心定位是**构建时预处理器**：在你的 MoonBit 项目中先用宏语法编写代码，
然后通过预处理器展开为纯 MoonBit 源码，最后正常执行 `moon build`。

### 3.1 工作流程

```
你的 MoonBit 项目/
  src/
    main.mbt.macro     # 用 macro_rules! 和 #[macro_derive] 编写
    lib.mbt.macro      # 可以混合宏调用和普通 MoonBit 代码
    utils.mbt          # 普通 MoonBit 文件（无需预处理）

步骤:
  1. 编写 .mbt.macro 文件（宏语法 + MoonBit 代码混合）
  2. 运行预处理器: ./moonmacro.sh src/
  3. 展开后的 .mbt.macro 文件变为纯 .mbt 文件
  4. 运行 moon build
```

### 3.2 文件命名约定

| 扩展名 | 说明 |
|---------|------|
| `.mbt.macro` | 包含宏定义和调用的源文件，需要预处理 |
| `.mbt` | 纯 MoonBit 源码，无需预处理 |
| `.mbt.macro` → `.mbt` | 预处理后重命名 |

约定：
- 用 `.mbt.macro` 后缀标记需要宏展开的文件
- 预处理脚本原地展开后，文件变为纯 MoonBit 代码
- 普通的 `.mbt` 文件不经预处理直接传递给编译器

### 3.3 设计说明

moonmacro 的预处理发生在 MoonBit 编译器之前，与 MoonBit 自身的
`#[derive]`、`#[test]` 等属性语法**完全解耦**：

- moonmacro 使用 `#[macro_derive(...)]`（而不是 `#[derive(...)]`）避免冲突
- `macro_rules!` 定义在预处理阶段被识别和展开
- 展开后的代码是纯 MoonBit 语法，再由 `moon build` 正常编译

预处理通过 `moonmacro.sh` 脚本 + MoonBit 原生二进制协作实现。
`moonmacro.sh` 负责文件 I/O 和目录递归；原生二进制接收源码文本
作为命令行参数，执行宏展开并输出结果到 stdout。原生目标
（`moon build --target native`）提供完整的 CLI 参数和文件 I/O 支持。

## 4. 宏定义 macro_rules!

### 4.1 基本语法

```moonbit
macro_rules! 宏名称 {
  (模式1) => { 模板1 }
  (模式2) => { 模板2 }
}
```

各部分说明:

| 部分 | 说明 |
|------|------|
| `macro_rules!` | 关键字，标记宏定义的开始 |
| `宏名称` | MoonBit 标识符（字母、数字、下划线，数字不能开头） |
| `(模式)` | 圆括号包裹的匹配模式 |
| `=>` | 连接模式和模板 |
| `{ 模板 }` | 花括号包裹的输出模板（也可用圆括号） |



## 5. 内置宏

内置宏无需手动导入，在用户定义宏匹配失败后自动尝试。

### 5.1 vec!

最简单的内置宏——将参数包装为数组字面量：

```moonbit
let a = vec![1, 2, 3]               // -> let a = [1, 2, 3]
let b = vec!["a", "b", "c"]         // -> let b = ["a", "b", "c"]
let c = vec![]                       // -> let c = []
let d = vec![1 + 2, 3 * 4]          // -> let d = [1 + 2, 3 * 4]
```

实现：直接返回 "[" + args + "]"。

### 5.2 println! / eprintln!

移除 ! 后缀，将宏调用转为普通函数调用：

```moonbit
println!("hello")                    // -> println("hello")
println!("x = " + x.to_string())    // -> println("x = " + x.to_string())
eprintln!("error")                   // -> eprintln("error")
```

参数原样传递给 println() / eprintln() 函数。

### 5.3 assert!

生成带错误消息的断言：

```moonbit
assert!(x > 0)
// -> if !(x > 0) { abort("assertion failed: x > 0") }

assert!(result.is_some())
// -> if !(result.is_some()) { abort("assertion failed: result.is_some()") }
```

多个条件：

```moonbit
assert!(x > 0 && y < 10)
// -> if !(x > 0 && y < 10) { abort("assertion failed: x > 0 && y < 10") }
```

### 5.4 todo! / unreachable!

占位宏，用于标记未完成的代码或不可达分支：

```moonbit
fn unimplemented() -> Int {
  todo!()
  // -> abort("not implemented")
}

fn process(x: Int) -> String {
  match x {
    1 => "one"
    2 => "two"
    _ => unreachable!()
    // -> abort("unreachable")
  }
}
```

### 5.5 concat!

连接多个字符串字面量：

```moonbit
let s = concat!("Hello, ", "World!")
// -> let s = "Hello, World!"

let path = concat!("/usr/local/", "bin/", "moon")
// -> let path = "/usr/local/bin/moon"
```

实现细节：
1. 解析逗号分隔的参数列表
2. 对每个参数去除引号
3. 拼接所有内容
4. 加回引号

非字符串字面量参数的展开：

```moonbit
let s = concat!("value = ", x.to_string())
// 当前行为: 非字符串参数在展开时保持文本形式
// -> let s = "value = " + x.to_string()
```

### 5.6 stringify!

将参数字面量化为字符串：

```moonbit
let s = stringify!(hello world)
// -> let s = "hello world"

let op = stringify!(x + y)
// -> let op = "x + y"

macro_rules! assert_eq {
  ($left:expr, $right:expr) => {
    if $left != $right {
      abort("assertion failed: " + stringify!($left) + " != " + stringify!($right))
    }
  }
}
assert_eq!(1 + 1, 2)
// 展开为:
// if 1 + 1 != 2 {
//   abort("assertion failed: 1 + 1 != 2")
// }
```

### 5.7 compile_error!

生成编译错误（运行时通过 abort 模拟）：

```moonbit
compile_error!("this feature requires moonbit >= 0.1.0")
// -> abort("this feature requires moonbit >= 0.1.0")
```



## 6. 自动派生 #[macro_derive]

#[macro_derive(Trait1, Trait2)] 为 struct 或 enum 自动生成 trait 实现代码。


## 7. 模块结构

```
moonmacro/
  moon.pkg                # 根包
  moon.mod.json           # 模块定义
  reader.mbt              # 读取、扫描、解析
  pattern.mbt             # 模式匹配引擎
  expander.mbt            # 宏展开器
  derive.mbt              # #[macro_derive] 实现
  builtins.mbt            # 内置宏
  mmprocess/
     moon.pkg              # 预处理器入口（is-main）
     mmprocess.mbt         # main 函数（展开或 --demo）
     demo.mbt              # 8 部分功能演示
  test/
    moon.pkg              # 测试包
    test.mbt              # 单元测试
  verify/
    moon.pkg              # 验证包
    verify.mbt            # 集成测试
```


## 8. 命令行工具

### 8.1 mmprocess 原生二进制

编译生成原生二进制，支持展开和演示：

```bash
cd mmprocess && moon build --target native
_build/native/debug/build/mmprocess/mmprocess.exe --demo
```

支持两种模式：

#### 8.1.1 演示模式

```bash
_build/native/debug/build/mmprocess/mmprocess.exe --demo
```

展示 8 个分步演示，展示宏系统的各个功能：

| 步骤 | 宏 | 说明 |
|------|-----|------|
| 1 | greet! | 基础标识符拼接 |
| 2 | make_tuple! | 带重复的宏 |
| 3 | vec! | 内置宏 |
| 4 | 嵌套展开 | apply! + double! 演示多轮展开 |
| 5 | derive Show | struct Point 自动派生 |
| 6 | derive Show | enum Color 自动派生 |
| 7 | derive Clone | 泛型 Option[T] 自动派生 |
| 8 | stringify! + concat! | 内置元宏 |

#### 8.1.2 展开模式

```bash
_build/native/debug/build/mmprocess/mmprocess.exe '<source_text>'
```

将宏源码作为命令行参数，输出展开并移除 `macro_rules!` 定义后的纯 MoonBit 代码。

### 8.2 moonmacro.sh 预处理器脚本

`moonmacro.sh` 是面向日常使用的文件级预处理器，处理 `.mbt.macro` 文件：

- 自动查找目录（含递归子目录）中的所有 `.mbt.macro` 文件
- 调用 `mmprocess` 原生二进制进行宏展开
- 将展开结果（已剔除 `macro_rules!` 定义）写入对应的 `.mbt` 文件

```bash
./moonmacro.sh src/                          # 处理整个目录
./moonmacro.sh src/main.mbt.macro            # 处理单个文件
./moonmacro.sh                               # 默认处理当前目录
```

### 8.3 安装到 PATH

```bash
./moonmacro.sh install
# 安装至 ~/.local/bin/mmprocess 和 ~/.local/bin/moonmacro.sh
# 也可指定目录: ./moonmacro.sh install /usr/local/bin
```

安装后可全局使用：

```bash
mmprocess --demo                    # 查看演示
mmprocess 'source_text'             # 直接展开源码
moonmacro.sh src/                   # 处理目录
```

`install` 自动执行 `moon build --target native` 构建原生二进制并复制到目标目录。



### 9. 许可

MIT License
Copyright (c) 2026 aaa

