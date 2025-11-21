import gleam/erlang/charlist

@external(erlang, "exit_ffi", "do_exit")
pub fn exit(status: Int) -> Nil

@external(erlang, "file", "get_cwd")
pub fn get_cwd() -> Result(charlist.Charlist, Nil)

@external(erlang, "file", "set_cwd")
pub fn set_cwd(path: charlist.Charlist) -> Result(Nil, Nil)
