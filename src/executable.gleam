import envoy
import filepath
import gleam/erlang/charlist
import gleam/io
import gleam/list
import gleam/option
import gleam/set
import gleam/string
import simplifile

pub fn find_executable(command) -> option.Option(String) {
  let assert Ok(path) = envoy.get("PATH")
  let path =
    string.split(path, ":")
    |> list.filter(fn(p) { check_executable(p, command) })
    |> list.first()
  case path {
    Ok(path) -> option.Some(filepath.join(path, command))
    _ -> option.None
  }
}

pub fn execute(command, args) -> Nil {
  case find_executable(command) {
    option.Some(_) -> {
      let command_line = string.join([command, ..args], " ")
      cmd(charlist.from_string(command_line))
      |> io.print
      Nil
    }
    option.None -> {
      io.println(command <> ": command not found")
      Nil
    }
  }
}

fn check_executable(path, command) -> Bool {
  let file_info =
    filepath.join(path, command)
    |> simplifile.file_info
  case file_info {
    Ok(fi) -> {
      let permission = simplifile.file_info_permissions(fi)
      set.contains(permission.user, simplifile.Execute)
    }
    _ -> False
  }
}

@external(erlang, "os", "cmd")
fn cmd(command_line: charlist.Charlist) -> String
