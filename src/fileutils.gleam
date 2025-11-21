import envoy
import externalutils
import filepath
import gleam/erlang/charlist

pub fn expand_path(path: String) -> Result(String, Nil) {
  let dir = case filepath.is_absolute(path) {
    True -> path
    False ->
      case path {
        "~" <> rest -> {
          let assert Ok(home) = envoy.get("HOME")
          filepath.join(home, rest)
        }
        _ -> {
          let assert Ok(cwd) = externalutils.get_cwd()
          filepath.join(charlist.to_string(cwd), path)
        }
      }
  }
  filepath.expand(dir)
}
