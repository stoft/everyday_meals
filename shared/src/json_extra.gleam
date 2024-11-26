import decode/zero
import gleam/json
import gleam/string

pub fn decode_from_string(
  str_msg: String,
  decoder: zero.Decoder(a),
) -> Result(a, json.DecodeError) {
  str_msg
  |> json.decode(zero.run(_, decoder))
}

pub fn decode_error_to_string(error: json.DecodeError) -> String {
  string.inspect(error)
}
