import gleam/dynamic
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
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
}

pub type Model {
  Model(meals: List(Meal), new_meal: String, language: Language)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model(meals: [], new_meal: "", language: En), effect.none())
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
  }
}

fn get_translation(lang: Language, key: String) -> String {
  case lang, key {
    En, "title" -> "Weekly Meal Tracker"
    En, "add_meal" -> "Add Meal"
    En, "enter_meal" -> "Enter a new meal"
    En, "eaten" -> "Eaten"
    En, "uneaten" -> "Uneaten"
    En, "eaten_meals" -> "Eaten Meals"
    En, "select_language" -> "Select Language"

    Sv, "title" -> "Veckans Måltidsspårare"
    Sv, "add_meal" -> "Lägg till Måltid"
    Sv, "enter_meal" -> "Ange en ny måltid"
    Sv, "eaten" -> "Äten"
    Sv, "uneaten" -> "Oäten"
    Sv, "eaten_meals" -> "Ätna Måltider"
    Sv, "select_language" -> "Välj Språk"

    Fr, "title" -> "Suivi des Repas Hebdomadaires"
    Fr, "add_meal" -> "Ajouter un Repas"
    Fr, "enter_meal" -> "Entrez un nouveau repas"
    Fr, "eaten" -> "Mangé"
    Fr, "uneaten" -> "Non Mangé"
    Fr, "eaten_meals" -> "Repas Mangés"
    Fr, "select_language" -> "Choisir la Langue"

    // Add other languages...
    _, _ -> "Translation missing"
  }
}

fn language_name(lang: Language) -> String {
  case lang {
    En -> "English"
    Sv -> "Svenska"
    Fr -> "Français"
    De -> "Deutsch"
    It -> "Italiano"
    Nl -> "Nederlands"
  }
}

fn language_switcher(current: Language) -> element.Element(Msg) {
  html.div([attribute.class("absolute top-4 right-4")], [
    html.select(
      [
        event.on_input(fn(value) {
          case value {
            "en" -> SetLanguage(En)
            "sv" -> SetLanguage(Sv)
            "fr" -> SetLanguage(Fr)
            "de" -> SetLanguage(De)
            "it" -> SetLanguage(It)
            "nl" -> SetLanguage(Nl)
            _ -> SetLanguage(En)
          }
        }),
        attribute.class("p-2 border rounded bg-white"),
      ],
      [
        html.option([attribute.value("en")], "English"),
        html.option([attribute.value("sv")], "Svenska"),
        html.option([attribute.value("fr")], "Français"),
        html.option([attribute.value("de")], "Deutsch"),
        html.option([attribute.value("it")], "Italiano"),
        html.option([attribute.value("nl")], "Nederlands"),
      ],
    ),
  ])
}

fn format_date(timestamp: date.Date) -> String {
  date.to_iso_string(timestamp) |> string.slice(0, 10)
}

fn render_meal_item(
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
                True -> "uneaten"
                False -> "eaten"
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
    language_switcher(model.language),
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
        render_meal_item(meal, False, model.language)
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
              render_meal_item(meal, True, model.language)
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
