import birl
import gleam/option.{None}
import gleeunit
import gleeunit/should
import meal.{Meal, move_down, move_up}

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`

pub fn move_up_empty_list_test() {
  move_up([], "1")
  |> should.equal([])
}

fn modified_at() {
  birl.from_unix(1_234_567_890)
}

pub fn move_up_single_item_test() {
  let single = [Meal("1", "meal1", False, None, modified_at())]
  move_up(single, "1")
  |> should.equal(single)
}

pub fn move_up_first_item_wraps_to_end_test() {
  let list = [
    Meal("1", "meal1", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
  ]
  move_up(list, "1")
  |> should.equal([
    Meal("2", "meal2", False, None, modified_at()),
    Meal("1", "meal1", False, None, modified_at()),
  ])
}

pub fn move_up_middle_item_test() {
  let list3 = [
    Meal("1", "meal1", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
    Meal("3", "meal3", False, None, modified_at()),
  ]
  move_up(list3, "2")
  |> should.equal([
    Meal("2", "meal2", False, None, modified_at()),
    Meal("1", "meal1", False, None, modified_at()),
    Meal("3", "meal3", False, None, modified_at()),
  ])
}

pub fn move_up_non_existent_id_test() {
  let list3 = [
    Meal("1", "meal1", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
    Meal("3", "meal3", False, None, modified_at()),
  ]
  move_up(list3, "4")
  |> should.equal(list3)
}

pub fn move_up_last_item_test() {
  let list3 = [
    Meal("1", "meal1", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
    Meal("3", "meal3", False, None, modified_at()),
  ]
  move_up(list3, "3")
  |> should.equal([
    Meal("1", "meal1", False, None, modified_at()),
    Meal("3", "meal3", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
  ])
}

pub fn empty_list_move_down_test() {
  move_down([], "1")
  |> should.equal([])
}

pub fn single_item_move_down_test() {
  let single = [Meal("1", "meal1", False, None, modified_at())]
  move_down(single, "1")
  |> should.equal(single)
}

pub fn first_item_move_down_test() {
  let list = [
    Meal("1", "meal1", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
  ]
  move_down(list, "1")
  |> should.equal([
    Meal("2", "meal2", False, None, modified_at()),
    Meal("1", "meal1", False, None, modified_at()),
  ])
}

pub fn middle_item_move_down_test() {
  let list3 = [
    Meal("1", "meal1", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
    Meal("3", "meal3", False, None, modified_at()),
  ]
  move_down(list3, "2")
  |> should.equal([
    Meal("1", "meal1", False, None, modified_at()),
    Meal("3", "meal3", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
  ])
}

pub fn non_existent_id_move_down_test() {
  let list3 = [
    Meal("1", "meal1", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
    Meal("3", "meal3", False, None, modified_at()),
  ]
  move_down(list3, "4")
  |> should.equal(list3)
}

pub fn last_item_move_down_test() {
  let list3 = [
    Meal("1", "meal1", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
    Meal("3", "meal3", False, None, modified_at()),
  ]
  move_down(list3, "3")
  |> should.equal([
    Meal("3", "meal3", False, None, modified_at()),
    Meal("1", "meal1", False, None, modified_at()),
    Meal("2", "meal2", False, None, modified_at()),
  ])
}
