import gleam/json
import gleam/result
import plinth/javascript/storage.{type Storage}
import shared.{type Meal}

const meals_key = "meals"

pub fn save_meals(meals: List(Meal)) -> Result(Nil, Nil) {
  use storage <- result.try(storage.local())

  // Convert meals to JSON string
  let meals_json =
    meals
    |> list.map(shared.meal_to_json)
    |> json.array
    |> json.to_string

  storage.set_item(storage, meals_key, meals_json)
}

pub fn load_meals() -> Result(List(Meal), String) {
  use storage <- result.try(storage.local())
  use json_str <- result.try(storage.get_item(storage, meals_key))

  // Parse JSON string back to meals
  case json.decode(json_str, shared.meals_decoder) {
    Ok(meals) -> Ok(meals)
    Error(_) -> Error("Failed to decode meals from storage")
  }
}

pub fn clear_meals() -> Result(Nil, Nil) {
  use storage <- result.try(storage.local())
  storage.remove_item(storage, meals_key)
  Ok(Nil)
}
