import gleam/option.{type Option}
import gleam/string

pub type Reader {
  Reader(buffer: String, position: Int)
}

pub fn reader(buffer: String) -> Reader {
  Reader(buffer, -1)
}

pub fn peek(reader: Reader) -> Option(String) {
  case will_be_at_end(reader) {
    True -> option.None
    False -> option.Some(string.slice(reader.buffer, reader.position + 1, 1))
  }
}

pub fn next(reader: Reader) -> #(Reader, Option(String)) {
  case will_be_at_end(reader) {
    True -> #(reader, option.None)
    False -> #(
      Reader(..reader, position: reader.position + 1),
      option.Some(string.slice(reader.buffer, reader.position + 1, 1)),
    )
  }
}

pub fn at_end(reader: Reader) -> Bool {
  reader.position >= string.length(reader.buffer)
}

pub fn will_be_at_end(reader: Reader) -> Bool {
  reader.position + 1 >= string.length(reader.buffer)
}
