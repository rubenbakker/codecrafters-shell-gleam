import gleam/erlang
import gleam/io
import gleam/string

pub fn main() {
  repl()
}

pub fn repl() -> Nil {
  let assert Ok(cmd) = erlang.get_line("$ ")
  cmd
  |> string.trim
  |> fn(cmd) { cmd <> ": command not found" }
  |> io.println
  repl()
}
