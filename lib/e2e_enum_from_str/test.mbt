enum Color {
  Red
  Green
  Blue
}
pub fn Color::from_string(s: String) -> Color? {
  match s {
    "Red" => Some(Color::Red)
    "Green" => Some(Color::Green)
    "Blue" => Some(Color::Blue)
    _ => None
  }
}



fn main {
  match Color::from_string("Red") {
    Some(Red) => println("Red ok")
    Some(_) => println("Red(?) ok")
    None => println("Red fail")
  }
  match Color::from_string("Blue") {
    Some(Blue) => println("Blue ok")
    Some(_) => println("Blue(?) ok")
    None => println("Blue fail")
  }
}
