struct Wrap[T] {
  value: T
}
pub fn[T] Wrap::value(self: Wrap[T]) -> T { self.value }



fn main {
  let w: Wrap[Int] = { value: 42 }
  println(w.value().to_string())
}
