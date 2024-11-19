import birl
import birl/duration
import decode/zero as decode
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lucide_lustre as lucide
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import meal.{type Meal, Meal}
import rxdb

pub type Language {
  En
  Sv
  Fr
  De
  It
  Nl
}

type Msg {
  AddMeal(String)
  UpdateNewMeal(String)
  ToggleEaten(String)
  SetLanguage(Language)
  HandleKeyPress(String)
  DeleteMeal(String)
  MoveMealUp(String)
  MoveMealDown(String)
  ToggleLanguageDropdown
  DatabaseCreated(Result(rxdb.Database, String))
  CollectionCreated(Result(rxdb.Collection, String))
  StateLoaded(Result(PersistedModel, String))
  StateSaved(Result(Nil, String))
  CloseLanguageDropdown
}

pub type Model {
  Model(
    meals: List(Meal),
    new_meal: String,
    language: Language,
    language_dropdown_open: Bool,
    db: Option(rxdb.Database),
    collection: Option(rxdb.Collection),
  )
}

type PersistedModel {
  PersistedModel(meals: List(Meal), language: Language)
}

const schema = "{
  \"version\": 0,
  \"primaryKey\": \"id\",
  \"type\": \"object\",
  \"properties\": {
    \"id\": {
      \"type\": \"string\",
      \"maxLength\": 100
    },
    \"meals\": {
      \"type\": \"array\",
      \"items\": {
        \"type\": \"object\",
        \"properties\": {
          \"id\": { \"type\": \"string\" },
          \"name\": { \"type\": \"string\" },
          \"eaten\": { \"type\": \"boolean\" },
          \"lastEaten\": { \"type\": \"number\", \"optional\": true }
        }
      }
    },
    \"language\": { \"type\": \"string\" }
  }
}"

// Add encoding functions
fn encode_meal(meal: Meal) -> json.Json {
  json.object([
    #("id", json.string(meal.id)),
    #("name", json.string(meal.name)),
    #("eaten", json.bool(meal.eaten)),
    #("last_eaten", case meal.last_eaten {
      Some(time) -> json.int(birl.to_unix(time))
      None -> json.null()
    }),
  ])
}

fn encode_language(lang: Language) -> json.Json {
  json.string(case lang {
    En -> "en"
    Sv -> "sv"
    Fr -> "fr"
    De -> "de"
    It -> "it"
    Nl -> "nl"
  })
}

fn init_database() -> effect.Effect(Msg) {
  effect.from(fn(callback) {
    let _promise = {
      rxdb.create_database("everyday_meals")
      |> promise.map(fn(db) { callback(Ok(db)) })
      |> promise.rescue(fn(error) { callback(Error(string.inspect(error))) })
    }
    Nil
  })
  |> effect.map(DatabaseCreated)
}

fn init_collection(db: rxdb.Database) -> effect.Effect(Msg) {
  effect.from(fn(callback) {
    let _promise = {
      rxdb.create_collection(db, "state", schema)
      |> promise.map(fn(collection) { callback(Ok(collection)) })
      |> promise.rescue(fn(error) { callback(Error(string.inspect(error))) })
    }
    Nil
  })
  |> effect.map(CollectionCreated)
}

fn read_state(collection: rxdb.Collection) -> effect.Effect(Msg) {
  effect.from(fn(callback) {
    let _promise =
      rxdb.find_one(collection, "current")
      |> promise.map(fn(state) {
        let result = decode.run(dynamic.from(state), decode_state())
        case result {
          Ok(state) -> {
            // Parse the state and update the model
            callback(Ok(state))
          }
          Error(_) -> callback(Error(string.inspect(result)))
        }
      })
      |> promise.rescue(fn(error) { callback(Error(string.inspect(error))) })
    Nil
  })
  |> effect.map(StateLoaded)
}

fn decode_meal() -> decode.Decoder(Meal) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use eaten <- decode.field("eaten", decode.bool)
  use last_eaten <- decode.field(
    "last_eaten",
    decode.optional(
      decode.int
      |> decode.then(fn(t) { decode.success(birl.from_unix(t)) }),
    ),
  )

  decode.success(Meal(id: id, name: name, eaten: eaten, last_eaten: last_eaten))
}

fn decode_language() -> decode.Decoder(Language) {
  decode.string
  |> decode.then(fn(str) {
    case str {
      "en" -> decode.success(En)
      "sv" -> decode.success(Sv)
      _ -> decode.failure(En, "Language not supported")
    }
  })
}

fn decode_state() -> decode.Decoder(PersistedModel) {
  use meals <- decode.field("meals", decode.list(decode_meal()))
  use lang <- decode.field("language", decode_language())
  decode.success(PersistedModel(meals: meals, language: lang))
}

fn save_state(model: Model) -> effect.Effect(Msg) {
  io.debug("save_state")
  case model.collection {
    None -> effect.none()
    Some(collection) -> {
      io.debug("save_state: collection")
      let state =
        json.object([
          #("id", json.string("current")),
          #("meals", json.array(model.meals, encode_meal)),
          #("language", encode_language(model.language)),
        ])
        |> json.to_string

      effect.from(fn(callback) {
        let _promise = {
          rxdb.upsert(collection, state)
          |> promise.map(fn(_) { callback(Ok(Nil)) })
          |> promise.rescue(fn(error) {
            io.debug("save_state: error")
            io.debug(string.inspect(error))
            callback(Error(string.inspect(error)))
          })
        }
        Nil
      })
      |> effect.map(StateSaved)
    }
  }
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      meals: [],
      new_meal: "",
      language: En,
      language_dropdown_open: False,
      db: None,
      collection: None,
    ),
    init_database(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    DatabaseCreated(Ok(db)) -> #(
      Model(..model, db: Some(db)),
      init_collection(db),
    )
    DatabaseCreated(Error(_error)) -> {
      // Log error or handle it appropriately
      #(model, effect.none())
    }

    CollectionCreated(Ok(collection)) -> #(
      Model(..model, collection: Some(collection)),
      read_state(collection),
    )
    CollectionCreated(Error(error)) -> {
      // Log error or handle it appropriately
      io.debug(error)
      #(model, effect.none())
    }

    StateLoaded(Ok(PersistedModel(meals, language))) -> {
      io.debug("StateLoaded: Ok")
      io.debug(string.inspect(meals))
      #(Model(..model, meals: meals, language: language), effect.none())
    }

    StateLoaded(Error(error)) -> {
      // Log error or handle it appropriately
      io.debug(error)
      #(model, effect.none())
    }

    StateSaved(Ok(Nil)) -> {
      io.debug("StateSaved: Ok")
      #(model, effect.none())
    }

    StateSaved(Error(error)) -> {
      // Log error or handle it appropriately
      io.debug(error)
      #(model, effect.none())
    }

    AddMeal(name) ->
      case string.trim(name) {
        "" -> #(model, effect.none())
        _ -> {
          let new_meal =
            Meal(
              id: string.inspect(birl.to_unix(birl.now())),
              name: name,
              eaten: False,
              last_eaten: None,
            )
          let new_model =
            Model(
              ..model,
              meals: list.append(model.meals, [new_meal]),
              new_meal: "",
            )

          #(new_model, save_state(new_model))
        }
      }
    UpdateNewMeal(value) -> #(Model(..model, new_meal: value), effect.none())
    ToggleEaten(id) -> {
      let current_time = birl.now()
      let updated_meals =
        list.map(model.meals, fn(meal) {
          case meal.id == id {
            True ->
              Meal(
                ..meal,
                eaten: !meal.eaten,
                last_eaten: case !meal.eaten {
                  True -> Some(current_time)
                  False -> meal.last_eaten
                },
              )
            False -> meal
          }
        })

      // Count uneaten meals
      let uneaten_count =
        list.filter(updated_meals, fn(m) { !m.eaten })
        |> list.length

      // If less than 7 uneaten meals, convert some eaten meals
      case uneaten_count < 7 {
        False -> #(Model(..model, meals: updated_meals), save_state(model))
        True -> {
          let meals_to_convert = 7 - uneaten_count

          // First, separate eaten and uneaten meals
          let eaten = list.filter(updated_meals, fn(m) { m.eaten })
          let uneaten = list.filter(updated_meals, fn(m) { !m.eaten })

          // Convert the required number of eaten meals
          let converted =
            eaten
            |> list.take(meals_to_convert)
            |> list.map(fn(m) { Meal(..m, eaten: False) })

          // Keep remaining eaten meals
          let remaining_eaten =
            eaten
            |> list.drop(meals_to_convert)

          // Combine lists: uneaten + converted + remaining eaten
          let final_meals =
            list.append(uneaten, converted)
            |> list.append(remaining_eaten)

          #(Model(..model, meals: final_meals), save_state(model))
        }
      }
    }
    SetLanguage(lang) -> {
      let new_model =
        Model(..model, language: lang, language_dropdown_open: False)
      #(new_model, save_state(model))
    }
    HandleKeyPress(key) ->
      case key {
        "Enter" -> update(model, AddMeal(model.new_meal))
        _ -> #(model, effect.none())
      }
    DeleteMeal(id) -> {
      let updated_meals = list.filter(model.meals, fn(meal) { meal.id != id })
      let new_model = Model(..model, meals: updated_meals)
      #(new_model, save_state(new_model))
    }
    MoveMealUp(id) -> {
      let updated_meals = meal.move_up(model.meals, id)
      let new_model = Model(..model, meals: updated_meals)
      #(new_model, save_state(new_model))
    }
    MoveMealDown(id) -> {
      let updated_meals = meal.move_down(model.meals, id)
      let new_model = Model(..model, meals: updated_meals)
      #(new_model, save_state(new_model))
    }
    ToggleLanguageDropdown -> #(
      Model(..model, language_dropdown_open: !model.language_dropdown_open),
      effect.none(),
    )
    CloseLanguageDropdown -> #(
      Model(..model, language_dropdown_open: False),
      effect.none(),
    )
  }
}

fn get_translation(lang: Language, key: String) -> String {
  case lang, key {
    En, "title" -> "Everyday Meals"
    En, "add_meal" -> "Add Meal"
    En, "enter_meal" -> "Enter a new meal"
    En, "eat" -> "Eat"
    En, "plan" -> "Plan"
    En, "eaten_meals" -> "Eaten Meals"
    En, "select_language" -> "Select Language"

    Sv, "title" -> "Vardagsmat"
    Sv, "add_meal" -> "Lägg till Måltid"
    Sv, "enter_meal" -> "Ange en ny måltid"
    Sv, "eat" -> "Ät"
    Sv, "plan" -> "Planera"
    Sv, "eaten_meals" -> "Ätna Måltider"
    Sv, "select_language" -> "Välj Språk"

    Fr, "title" -> "Suivi des Repas Hebdomadaires"
    Fr, "add_meal" -> "Ajouter un Repas"
    Fr, "enter_meal" -> "Entrez un nouveau repas"
    Fr, "eat" -> "Manger"
    Fr, "plan" -> "Prévoir"
    Fr, "eaten_meals" -> "Repas Mangés"
    Fr, "select_language" -> "Choisir la Langue"

    // Add other languages...
    _, _ -> "Translation missing"
  }
}

fn view_language_switcher(model: Model) -> element.Element(Msg) {
  html.div([], [
    case model.language_dropdown_open {
      True ->
        // Add overlay to catch outside clicks
        html.div(
          [
            attribute.class("fixed inset-0 z-20"),
            // Fixed to viewport
            event.on_click(CloseLanguageDropdown),
          ],
          [],
        )
      False -> element.none()
    },
    // Language icon button
    html.button(
      [
        event.on_click(ToggleLanguageDropdown),
        attribute.class("p-2 text-gray-600 hover:text-blue-500"),
        attribute.title("Select Language"),
      ],
      [lucide.languages([])],
    ),
    // Dropdown menu
    case model.language_dropdown_open {
      False -> element.none()
      True ->
        html.div(
          [
            attribute.class(
              "absolute right-0 mt-2 py-2 w-48 bg-white rounded-md shadow-xl z-30 border",
            ),
          ],
          [
            view_language_option("English", En, model.language),
            view_language_option("Svenska", Sv, model.language),
            view_language_option("Français", Fr, model.language),
            view_language_option("Deutsch", De, model.language),
            view_language_option("Italiano", It, model.language),
            view_language_option("Nederlands", Nl, model.language),
          ],
        )
    },
  ])
}

// Helper function to create language options
fn view_language_option(
  label: String,
  lang: Language,
  current: Language,
) -> element.Element(Msg) {
  html.button(
    [
      event.on_click(SetLanguage(lang)),
      attribute.class(
        "block px-4 py-2 text-sm capitalize text-gray-700 hover:bg-gray-100 w-full text-left "
        <> case lang == current {
          True -> "bg-gray-100"
          False -> ""
        },
      ),
    ],
    [element.text(label)],
  )
}

fn format_date(time: birl.Time) -> String {
  birl.to_naive_date_string(time)
}

fn view_meal_item(
  meal: Meal,
  index: Int,
  is_eaten: Bool,
  language: Language,
) -> element.Element(Msg) {
  let day_text = case index {
    0 -> "Today"
    n -> {
      let today = birl.now()
      let future_date = birl.add(today, duration.days(n))
      birl.weekday(future_date) |> birl.weekday_to_short_string
    }
  }

  html.div([attribute.class("flex items-center")], [
    // Day label on the left
    html.div([attribute.class("w-12 text-sm text-gray-500 text-right pr-2")], [
      element.text(day_text),
    ]),
    // Meal card
    html.li([attribute.class("p-2 border rounded flex-1")], [
      html.div([attribute.class("flex justify-between items-center w-full")], [
        html.div([attribute.class("flex flex-col gap-0")], [
          element.text(meal.name),
          html.span([attribute.class("text-xs text-gray-500")], [
            element.text(case meal.last_eaten {
              Some(time) -> format_date(time)
              None -> "Never eaten"
            }),
          ]),
        ]),
        html.div([attribute.class("flex items-center gap-1")], [
          // Only show reorder buttons for planned meals
          case is_eaten {
            True -> element.none()
            False ->
              html.div([attribute.class("flex items-center gap-1")], [
                html.button(
                  [
                    event.on_click(MoveMealUp(meal.id)),
                    attribute.class("p-1 text-gray-500 hover:text-blue-500"),
                    attribute.title("Move up"),
                  ],
                  [element.text("⬆️")],
                ),
                html.button(
                  [
                    event.on_click(MoveMealDown(meal.id)),
                    attribute.class("p-1 text-gray-500 hover:text-blue-500"),
                    attribute.title("Move down"),
                  ],
                  [element.text("⬇️")],
                ),
              ])
          },
          html.button(
            [
              event.on_click(ToggleEaten(meal.id)),
              attribute.class(case is_eaten {
                True -> "px-3 py-1 border border-gray-300 rounded"
                False -> "px-3 py-1 bg-green-500 text-white rounded"
              }),
            ],
            [
              element.text(
                get_translation(language, case is_eaten {
                  True -> "plan"
                  False -> "eat"
                }),
              ),
            ],
          ),
          html.button(
            [
              event.on_click(DeleteMeal(meal.id)),
              attribute.class("p-1 text-gray-500 hover:text-red-500"),
              attribute.title("Delete meal"),
            ],
            [
              // Trash bin icon using HTML entity
              html.span([attribute.class("text-xl")], [element.text("🗑️")]),
            ],
          ),
        ]),
      ]),
    ]),
  ])
}

// Update the view_meals function to pass the index
fn view_meals(
  meals: List(Meal),
  is_eaten: Bool,
  language: Language,
) -> element.Element(Msg) {
  html.ul(
    [attribute.class("space-y-2")],
    list.index_map(meals, fn(meal, index) {
      view_meal_item(meal, index, is_eaten, language)
    }),
  )
}

fn view(model: Model) -> element.Element(Msg) {
  let uneaten_meals = list.filter(model.meals, fn(m) { !m.eaten })
  let eaten_meals = list.filter(model.meals, fn(m) { m.eaten })

  html.div([], [
    // Regular navbar (not fixed)
    html.div([attribute.class("bg-white border-b shadow-sm")], [
      html.div(
        [
          attribute.class(
            "max-w-md mx-auto px-4 py-3 flex justify-between items-center",
          ),
        ],
        [
          // Title
          html.h1([attribute.class("text-2xl font-bold")], [
            element.text("🥘 " <> get_translation(model.language, "title")),
          ]),
          // Language switcher
          view_language_switcher(model),
        ],
      ),
    ]),
    // Main content (no extra top padding needed)
    html.div([attribute.class("max-w-md mx-auto p-4")], [
      // Add meal form with left spacing to match meal items
      html.div([attribute.class("flex mb-4")], [
        html.div([attribute.class("w-16")], []),
        // Spacer to align with day labels
        html.div([attribute.class("flex-1")], [
          html.div([attribute.class("flex gap-2")], [
            html.input([
              attribute.type_("text"),
              attribute.value(model.new_meal),
              attribute.placeholder(get_translation(
                model.language,
                "enter_meal",
              )),
              event.on_input(UpdateNewMeal),
              event.on_keydown(HandleKeyPress),
              attribute.class("flex-1 p-2 border rounded"),
            ]),
            html.button(
              [
                event.on_click(AddMeal(model.new_meal)),
                attribute.class("px-4 py-2 bg-blue-500 text-white rounded"),
              ],
              [element.text(get_translation(model.language, "add_meal"))],
            ),
          ]),
        ]),
      ]),
      // Uneaten meals list
      view_meals(uneaten_meals, False, model.language),
      // Eaten meals section
      case eaten_meals {
        [] -> element.none()
        _ ->
          html.div([], [
            html.h2([attribute.class("text-lg font-semibold mt-6 mb-2")], [
              element.text(get_translation(model.language, "eaten_meals")),
            ]),
            view_meals(eaten_meals, True, model.language),
          ])
      },
    ]),
  ])
}

pub fn main() {
  let init = fn(_) {
    #(
      Model(
        meals: [],
        new_meal: "",
        language: En,
        language_dropdown_open: False,
        db: None,
        collection: None,
      ),
      init_database(),
    )
  }

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
