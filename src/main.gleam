import gleam/erlang
import gleam/int
import gleam/io
import gleam/string

pub fn main() {
  repl()
}

fn repl() -> Nil {
  let assert Ok(cmd) = erlang.get_line("$ ")
  let arguments =
    cmd
    |> string.trim
    |> string.split(" ")
  case arguments {
    ["exit", status] -> {
      let assert Ok(status) = int.parse(status)
      exit(status)
    }
    [command, ..] -> {
      io.println(command <> ": command not found")
    }
    [] -> Nil
  }
  repl()
}

@external(erlang, "exit_ffi", "do_exit")
fn exit(status: Int) -> Nil
