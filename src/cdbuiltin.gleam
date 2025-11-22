import externalutils
import fileutils
import gleam/erlang/charlist
import gleam/io
import simplifile

pub fn perform(dir: String) -> Nil {
  let assert Ok(dir) = fileutils.expand_path(dir)
  let assert Ok(is_directory) = simplifile.is_directory(dir)
  case is_directory {
    True -> {
      let _ = externalutils.set_cwd(charlist.from_string(dir))
      Nil
    }
    False -> {
      io.println("cd: " <> dir <> ": No such file or directory")
      Nil
    }
  }
}
