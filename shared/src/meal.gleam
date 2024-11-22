import birl.{type Time}
import decode/zero
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

pub type MealId =
  String

pub type Meal {
  Meal(
    id: MealId,
    name: String,
    eaten: Bool,
    last_eaten: Option(Time),
    modified_at: Time,
  )
}

pub fn move_up(list: List(Meal), id: MealId) -> List(Meal) {
  case list {
    [] -> []
    [x, ..tail] if x.id == id -> list.append(tail, [x])
    [head, x, ..tail] if x.id == id -> [x, head, ..tail]
    [x, ..tail] -> [x, ..move_up(tail, id)]
  }
}

pub fn move_down(list: List(Meal), id: MealId) -> List(Meal) {
  list |> list.reverse |> move_up(id) |> list.reverse
}

pub fn encode(meal: Meal) -> json.Json {
  json.object([
    #("id", meal.id |> json.string),
    #("name", json.string(meal.name)),
    #("eaten", json.bool(meal.eaten)),
    #("last_eaten", case meal.last_eaten {
      Some(time) -> json.int(birl.to_unix(time))
      None -> json.null()
    }),
    #("modified_at", json.int(birl.to_unix(meal.modified_at))),
  ])
}

pub fn decoder() -> zero.Decoder(Meal) {
  use id <- zero.field("id", zero.string)
  use name <- zero.field("name", zero.string)
  use eaten <- zero.field("eaten", zero.bool)
  use last_eaten <- zero.field(
    "last_eaten",
    zero.optional(
      zero.int
      |> zero.then(fn(t) { zero.success(birl.from_unix(t)) }),
    ),
  )
  use modified_at <- zero.optional_field(
    "modified_at",
    birl.now(),
    zero.int
      |> zero.then(fn(t) { zero.success(birl.from_unix(t)) }),
  )

  zero.success(Meal(
    id: id,
    name: name,
    eaten: eaten,
    last_eaten: last_eaten,
    modified_at: modified_at,
  ))
}
