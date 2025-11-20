import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
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
    |> list.map(string.trim)
    |> list.filter(fn(arg) { !string.is_empty(arg) })

  case arguments {
    ["exit"] -> {
      exit(0)
    }
    ["exit", status] -> {
      let assert Ok(status) = int.parse(status)
      exit(status)
    }
    ["type", command] -> {
      case command {
        "type" | "exit" | "echo" -> {
          io.println(command <> " is a shell builtin")
        }
        _ -> io.println(command <> ": not found")
      }
    }
    ["echo", ..args] -> {
      io.println(string.join(args, " "))
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
