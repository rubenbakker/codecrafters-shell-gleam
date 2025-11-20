import executable
import gleam/io
import gleam/option

pub fn perform(command) -> Nil {
  case command {
    "type" | "exit" | "echo" | "pwd" | "cd" -> {
      io.println(command <> " is a shell builtin")
      Nil
    }
    _ -> {
      case executable.find_executable(command) {
        option.Some(path) -> io.println(command <> " is " <> path)
        option.None -> io.println(command <> ": not found")
      }
      Nil
    }
  }
}
