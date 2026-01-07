import cdbuiltin
import executable
import externalutils
import gleam/erlang/charlist
import gleam/int
import gleam/io
import gleam/string
import parser
import typebuiltin

pub fn main() {
  repl()
}

fn repl() -> Nil {
  let assert Ok(input_line) = externalutils.get_line("$ ")
  let assert Ok(args) = parser.parse_args(input_line)
  case args {
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
      cdbuiltin.perform(dir)
    }
    [command, ..rest] -> {
      executable.execute(command, rest)
    }
    [] -> Nil
  }

  repl()
}
