import executable
import externalutils
import fileutils
import gleam/erlang
import gleam/erlang/charlist
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile
import typebuiltin

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
      externalutils.exit(0)
    }
    ["exit", status] -> {
      let assert Ok(status) = int.parse(status)
      externalutils.exit(status)
    }
    ["type", command] -> {
      typebuiltin.perform(command)
    }
    ["echo", ..args] -> {
      io.println(string.join(args, " "))
    }
    ["pwd"] -> {
      let assert Ok(path) = externalutils.get_cwd()
      io.println(charlist.to_string(path))
    }
    ["cd", dir] -> {
      let assert Ok(dir) = fileutils.expand_path(dir)
      let assert Ok(is_directory) = simplifile.is_directory(dir)
      case is_directory {
        True -> {
          let _ = externalutils.set_cwd(charlist.from_string(dir))
          Nil
        }
        False -> {
          io.println("cd: " <> dir <> ": No such file or dilsirectory")
          Nil
        }
      }
      Nil
    }
    [command, ..rest] -> {
      executable.execute(command, rest)
    }
    [] -> Nil
  }

  repl()
}
