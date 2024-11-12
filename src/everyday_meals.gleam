import gleam/dynamic
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lucide_lustre as lucide
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import plinth/javascript/date

pub type Language {
  En
  Sv
  Fr
  De
  It
  Nl
}

pub type Meal {
  Meal(id: String, name: String, eaten: Bool, last_eaten: Option(date.Date))
}

pub type Msg {
  AddMeal(String)
  UpdateNewMeal(String)
  ToggleEaten(String)
  SetLanguage(Language)
  HandleKeyPress(String)
  DeleteMeal(String)
  MoveMealUp(String)
  MoveMealDown(String)
  ToggleLanguageDropdown
}

pub type Model {
  Model(
    meals: List(Meal),
    new_meal: String,
    language: Language,
    language_dropdown_open: Bool,
  )
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(meals: [], new_meal: "", language: En, language_dropdown_open: False),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    AddMeal(name) ->
      case string.trim(name) {
        "" -> #(model, effect.none())
        _ -> {
          let new_meal =
            Meal(
              id: string.inspect(date.now()),
              name: name,
              eaten: False,
              last_eaten: None,
            )
          #(
            Model(
              ..model,
              meals: list.append(model.meals, [new_meal]),
              new_meal: "",
            ),
            effect.none(),
          )
        }
      }
    UpdateNewMeal(value) -> #(Model(..model, new_meal: value), effect.none())
    ToggleEaten(id) -> {
      let current_time = date.now()
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
        False -> #(Model(..model, meals: updated_meals), effect.none())
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

          #(Model(..model, meals: final_meals), effect.none())
        }
      }
    }
    SetLanguage(lang) -> #(Model(..model, language: lang), effect.none())
    HandleKeyPress(key) ->
      case key {
        "Enter" -> update(model, AddMeal(model.new_meal))
        _ -> #(model, effect.none())
      }
    DeleteMeal(id) -> {
      let updated_meals = list.filter(model.meals, fn(meal) { meal.id != id })
      #(Model(..model, meals: updated_meals), effect.none())
    }
    MoveMealUp(id) -> {
      let updated_meals = move_meal(model.meals, id, Up)
      #(Model(..model, meals: updated_meals), effect.none())
    }
    MoveMealDown(id) -> {
      let updated_meals = move_meal(model.meals, id, Down)
      #(Model(..model, meals: updated_meals), effect.none())
    }
    ToggleLanguageDropdown -> #(
      Model(..model, language_dropdown_open: !model.language_dropdown_open),
      effect.none(),
    )
  }
}

type Direction {
  Up
  Down
}

// Helper function to move a meal up or down
fn move_meal(meals: List(Meal), id: String, direction: Direction) -> List(Meal) {
  // Find the meal and its index
  let #(before, rest) =
    list.fold_until(meals, #([], meals), fn(acc, meal) {
      case meal.id == id {
        True -> list.Stop(acc)
        False -> list.Continue(#([meal, ..acc.0], list.drop(acc.1, 1)))
      }
    })

  case rest {
    [] -> meals
    // Meal not found
    [meal, ..after] -> {
      let before = list.reverse(before)
      case direction {
        // Moving up
        Up ->
          case before {
            [] -> meals
            // Already at top
            [prev, ..earlier] -> list.append(earlier, [meal, prev, ..after])
          }
        // Moving down
        Down ->
          case after {
            [] -> meals
            // Already at bottom
            [next, ..later] -> list.append(before, [next, meal, ..later])
          }
      }
    }
  }
}

fn get_translation(lang: Language, key: String) -> String {
  case lang, key {
    En, "title" -> "Weekly Meal Tracker"
    En, "add_meal" -> "Add Meal"
    En, "enter_meal" -> "Enter a new meal"
    En, "eat" -> "Eat"
    En, "plan" -> "Plan"
    En, "eaten_meals" -> "Eaten Meals"
    En, "select_language" -> "Select Language"

    Sv, "title" -> "Veckans Måltidsspårare"
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
  html.div([attribute.class("fixed top-4 right-4")], [
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
              "absolute right-0 mt-2 py-2 w-48 bg-white rounded-md shadow-xl z-20 border",
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

fn format_date(timestamp: date.Date) -> String {
  date.to_iso_string(timestamp) |> string.slice(0, 10)
}

fn view_meal_item(
  meal: Meal,
  is_eaten: Bool,
  language: Language,
) -> element.Element(Msg) {
  html.li([attribute.class("p-4 border rounded flex flex-col")], [
    html.div([attribute.class("flex justify-between items-center w-full")], [
      html.div([attribute.class("flex flex-col")], [
        element.text(meal.name),
        html.span([attribute.class("text-sm text-gray-500")], [
          element.text(case meal.last_eaten {
            Some(timestamp) -> format_date(timestamp)
            None -> "Never eaten"
          }),
        ]),
      ]),
      html.div([attribute.class("flex items-center gap-2")], [
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
  ])
}

pub fn view(model: Model) -> element.Element(Msg) {
  let uneaten_meals = list.filter(model.meals, fn(m) { !m.eaten })
  let eaten_meals = list.filter(model.meals, fn(m) { m.eaten })

  html.div([attribute.class("max-w-md mx-auto p-4 relative")], [
    view_language_switcher(model),
    html.h1([attribute.class("text-2xl font-bold mb-4")], [
      element.text("🥘 " <> get_translation(model.language, "title")),
    ]),
    // Add meal form
    html.div([attribute.class("flex mb-4")], [
      html.input([
        attribute.type_("text"),
        attribute.value(model.new_meal),
        attribute.placeholder(get_translation(model.language, "enter_meal")),
        event.on_input(UpdateNewMeal),
        event.on_keydown(HandleKeyPress),
        attribute.class("mr-2 p-2 border rounded"),
      ]// [],
      ),
      html.button(
        [
          event.on_click(AddMeal(model.new_meal)),
          attribute.class("px-4 py-2 bg-blue-500 text-white rounded"),
        ],
        [element.text(get_translation(model.language, "add_meal"))],
      ),
    ]),
    // Uneaten meals list
    html.ul(
      [attribute.class("space-y-2")],
      list.map(uneaten_meals, fn(meal) {
        view_meal_item(meal, False, model.language)
      }),
    ),
    // Eaten meals section
    case eaten_meals {
      [] -> element.none()
      _ ->
        html.div([], [
          html.h2([attribute.class("text-lg font-semibold mt-6 mb-2")], [
            element.text(get_translation(model.language, "eaten_meals")),
          ]),
          html.ul(
            [attribute.class("space-y-2")],
            list.map(eaten_meals, fn(meal) {
              view_meal_item(meal, True, model.language)
            }),
          ),
        ])
    },
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
