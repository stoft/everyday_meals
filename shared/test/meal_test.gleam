import birl
import decode/zero as decode
import gleam/dict
import gleam/dynamic
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal.{type Meal}

pub fn main() {
  gleeunit.main()
}

pub fn decoder_with_all_fields_test() {
  let json_str =
    dynamic.from(
      dict.from_list([
        #("id", dynamic.from("123")),
        #("name", dynamic.from("Pizza")),
        #("eaten", dynamic.from(True)),
        #("last_eaten", dynamic.from(1_234_567_890)),
        #("modified_at", dynamic.from(1_234_567_891)),
      ]),
    )

  let result = decode.run(json_str, meal.decoder())

  should.be_ok(result)
  let assert Ok(meal) = result
  meal.id |> should.equal("123")
  meal.name |> should.equal("Pizza")
  meal.eaten |> should.equal(True)
  meal.last_eaten |> should.equal(Some(birl.from_unix(1_234_567_890)))
  meal.modified_at |> should.equal(birl.from_unix(1_234_567_891))
}

pub fn decoder_without_last_eaten_test() {
  let json_str =
    dynamic.from(
      dict.from_list([
        #("id", dynamic.from("123")),
        #("name", dynamic.from("Pizza")),
        #("eaten", dynamic.from(False)),
        #("last_eaten", dynamic.from(None)),
        #("modified_at", dynamic.from(1_234_567_891)),
      ]),
    )

  let result = decode.run(json_str, meal.decoder())

  should.be_ok(result)
  let assert Ok(meal) = result
  meal.last_eaten |> should.equal(None)
}

pub fn decoder_without_modified_at_test() {
  let json_str =
    dynamic.from(
      dict.from_list([
        #("id", dynamic.from("123")),
        #("name", dynamic.from("Pizza")),
        #("eaten", dynamic.from(False)),
        #("last_eaten", dynamic.from(None)),
      ]),
    )

  let result = decode.run(json_str, meal.decoder())

  should.be_ok(result)
  let assert Ok(_) = result
}

pub fn decoder_invalid_json_test() {
  let json_str =
    dynamic.from(
      dict.from_list([
        #("id", dynamic.from("123")),
        #("eaten", dynamic.from(False)),
      ]),
    )

  let result = decode.run(json_str, meal.decoder())
  should.be_error(result)
}

pub fn decoder_invalid_types_test() {
  let json_str =
    dynamic.from(
      dict.from_list([
        #("id", dynamic.from(123)),
        #("name", dynamic.from("Pizza")),
        #("eaten", dynamic.from("not a boolean")),
        #("last_eaten", dynamic.from("not a number")),
        #("modified_at", dynamic.from("not a number")),
      ]),
    )

  let result = decode.run(json_str, meal.decoder())
  should.be_error(result)
}
