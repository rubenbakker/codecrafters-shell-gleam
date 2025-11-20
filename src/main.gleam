import gleam/erlang
import gleam/io
import gleam/string

pub fn main() {
  let assert Ok(cmd) = erlang.get_line("$ ")
  cmd
  |> string.trim
  |> fn(cmd) { cmd <> ": command not found" }
  |> io.println
}
