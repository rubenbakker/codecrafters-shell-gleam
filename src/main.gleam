import gleam/erlang
import gleam/io
import gleam/string

pub fn main() {
  let assert Ok(input) = erlang.get_line("$ ")
  let input = string.trim(input)
  io.println(input <> ": command not found")
}
