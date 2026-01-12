import command/shellout
import envoy
import filepath
import gleam/io
import gleam/list
import gleam/option
import gleam/set
import gleam/string
import simplifile

pub type ExecInfo {
  ExecInfo(command: String, args: List(String), output: option.Option(String))
}

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

pub fn execute(exec_info: ExecInfo) -> Nil {
  case find_executable(exec_info.command) {
    option.Some(_) -> {
      let result =
        shellout.command(
          run: exec_info.command,
          alias: exec_info.command,
          in: ".",
          with: exec_info.args,
          opt: [],
        )
      let output = case result {
        Ok(output) -> output
        Error(#(_, output)) -> output
      }
      case exec_info.output {
        option.Some(file) -> {
          let _ = simplifile.write(to: file, contents: output)
          Nil
        }
        option.None -> io.print(output)
      }
      Nil
    }
    option.None -> {
      io.println(exec_info.command <> ": command not found")
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

pub fn prepare_execute(command: String, args: List(String)) -> ExecInfo {
  case list.reverse(args) {
    [file, ">", ..rest] | [file, "1>", ..rest] -> {
      ExecInfo(command:, args: list.reverse(rest), output: option.Some(file))
    }
    _ -> ExecInfo(command:, args:, output: option.None)
  }
}
