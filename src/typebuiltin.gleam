import envoy
import filepath
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import simplifile

pub fn perform(command) -> Nil {
  case command {
    "type" | "exit" | "echo" -> {
      io.println(command <> " is a shell builtin")
      Nil
    }
    _ -> {
      let assert Ok(path) = envoy.get("PATH")
      let path =
        string.split(path, ":")
        |> list.filter(fn(p) { check_executable(p, command) })
        |> list.first()
      case path {
        Ok(path) ->
          io.println(command <> " is " <> filepath.join(path, command))
        _ -> io.println(command <> ": not found")
      }
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
