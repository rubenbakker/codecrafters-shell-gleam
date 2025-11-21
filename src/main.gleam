import envoy
import executable
import filepath
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
      exit(0)
    }
    ["exit", status] -> {
      let assert Ok(status) = int.parse(status)
      exit(status)
    }
    ["type", command] -> {
      typebuiltin.perform(command)
    }
    ["echo", ..args] -> {
      io.println(string.join(args, " "))
    }
    ["pwd"] -> {
      let assert Ok(path) = get_cwd()
      io.println(charlist.to_string(path))
    }
    ["cd", dir] -> {
      let dir = case filepath.is_absolute(dir) {
        True -> dir
        False ->
          case dir {
            "~" <> rest -> {
              let assert Ok(home) = envoy.get("HOME")
              filepath.join(home, rest)
            }
            _ -> {
              let assert Ok(cwd) = get_cwd()
              filepath.join(charlist.to_string(cwd), dir)
            }
          }
      }
      let assert Ok(dir) = filepath.expand(dir)
      let assert Ok(is_directory) = simplifile.is_directory(dir)
      case is_directory {
        True -> {
          let _ = set_cwd(charlist.from_string(dir))
          Nil
        }
        False -> {
          io.println("cd: " <> dir <> ": No such file or directory")
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

@external(erlang, "exit_ffi", "do_exit")
fn exit(status: Int) -> Nil

@external(erlang, "file", "get_cwd")
fn get_cwd() -> Result(charlist.Charlist, Nil)

@external(erlang, "file", "set_cwd")
fn set_cwd(path: charlist.Charlist) -> Result(Nil, Nil)
