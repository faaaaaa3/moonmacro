struct Point {
  x: Int
  y: Int
}
pub fn Point::new(x: Int, y: Int) -> Point { { x, y } }



fn main {
  let p = Point::new(1, 2)
  println(p.x.to_string() + "," + p.y.to_string())
}
