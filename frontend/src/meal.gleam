import birl.{type Time}
import gleam/list
import gleam/option.{type Option}

pub type Meal {
  Meal(id: String, name: String, eaten: Bool, last_eaten: Option(Time))
}

pub fn move_up(list: List(Meal), id: String) -> List(Meal) {
  case list {
    [] -> []
    [x, ..tail] if x.id == id -> list.append(tail, [x])
    [head, x, ..tail] if x.id == id -> [x, head, ..tail]
    [x, ..tail] -> [x, ..move_up(tail, id)]
  }
}

pub fn move_down(list: List(Meal), id: String) -> List(Meal) {
  list |> list.reverse |> move_up(id) |> list.reverse
}
