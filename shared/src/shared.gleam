import decode/zero
import gleam/dict
import gleam/json
import gleam/list
import meal.{type Meal, type MealId, Meal}

pub type ClientMessage {
  AddMeal(Meal)
  DeleteMeal(MealId)
  ToggleEaten(MealId)
  MoveMealUp(MealId)
  MoveMealDown(MealId)
  FetchMeals
}

pub fn encode_client_message(msg: ClientMessage) {
  case msg {
    AddMeal(meal) -> [json.int(0), meal.encode(meal)]
    DeleteMeal(meal_id) -> [json.int(1), json.string(meal_id)]
    ToggleEaten(meal_id) -> [json.int(2), json.string(meal_id)]
    MoveMealUp(meal_id) -> [json.int(3), json.string(meal_id)]
    MoveMealDown(meal_id) -> [json.int(4), json.string(meal_id)]
    FetchMeals -> [json.int(5), json.null()]
  }
  |> json.preprocessed_array
  |> json.to_string
}

pub fn decode_client_message(str_msg: String) {
  let decoder = {
    use id <- zero.field(0, zero.int)

    case id {
      0 -> {
        use meal <- zero.field(1, meal.decoder())
        zero.success(AddMeal(meal))
      }
      1 -> {
        use meal_id <- zero.field(1, zero.string)
        zero.success(DeleteMeal(meal_id))
      }
      2 -> {
        use meal_id <- zero.field(1, zero.string)
        zero.success(ToggleEaten(meal_id))
      }
      3 -> {
        use meal_id <- zero.field(1, zero.string)
        zero.success(MoveMealUp(meal_id))
      }
      4 -> {
        use meal_id <- zero.field(1, zero.string)
        zero.success(MoveMealDown(meal_id))
      }
      5 -> zero.success(FetchMeals)
      _ -> zero.failure(FetchMeals, "ClientMessage")
    }
  }

  str_msg
  |> json.decode(zero.run(_, decoder))
}

pub type ServerMessage {
  ServerUpsertMeals(dict.Dict(String, Meal))
}

pub fn encode_server_message(msg: ServerMessage) {
  case msg {
    ServerUpsertMeals(meals) -> [
      json.int(0),
      json.array(dict.values(meals), meal.encode),
    ]
  }
  |> json.preprocessed_array
  |> json.to_string
}

pub fn decode_server_message(str_msg: String) {
  let decoder = {
    use id <- zero.field(0, zero.int)

    case id {
      0 -> {
        use meals <- zero.field(1, zero.list(meal.decoder()))
        let meals =
          meals
          |> list.map(fn(meal) { #(meal.id, meal) })
          |> dict.from_list
        zero.success(ServerUpsertMeals(meals))
      }
      _ -> zero.failure(ServerUpsertMeals(dict.new()), "ServerMessage")
    }
  }

  str_msg
  |> json.decode(zero.run(_, decoder))
}
