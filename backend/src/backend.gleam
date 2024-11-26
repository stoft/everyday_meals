import gleam/erlang/process
import mist
import server/context.{type Context, Context}
import server/router
import wisp

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(context) = Ok(Context([]))

  let handler = fn(req) { router.mist_handler(req, context, secret_key_base) }

  let assert Ok(_) =
    handler
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
