import meal.{type Meal}

// // import carpenter/table
// import gleam/dict
// import gleam/result
// import shared.{type ClientMessage, type ServerMessage}

// // this is demo without users, so just a single chat:
// const chat_id = 1

pub type Context {
  Context(meals: List(Meal))
}

pub fn change_state(_: Context, meals: List(Meal)) {
  Context(meals)
}
// // pub fn new() {
// //   table.build("chats")
// //   |> table.privacy(table.Public)
// //   |> table.write_concurrency(table.AutoWriteConcurrency)
// //   |> table.read_concurrency(True)
// //   |> table.decentralized_counters(True)
// //   |> table.compression(False)
// //   |> table.set
// //   |> result.map(Context)
// // }

// pub fn get_meals(ctx: Context) {
//   case
//     ctx.meals
//     |> table.lookup(chat_id)
//     |> list.first
//   {
//     Ok(entry) -> {
//       entry.1
//     }
//     Error(_) -> []
//   }
// }

// pub fn add_meal(ctx: Context, meal: Meal) {
//   ctx.meals |> table.insert([#(chat_id, meal)])
// }
// // pub fn delete_meal(ctx: Context, meal_id: Int) {
// //   ctx.meals |> table.insert([#(chat_id, chat)])
// // }
