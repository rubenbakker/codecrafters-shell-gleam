import gleam/option
import string_reader

pub fn peek_test() {
  let sut = string_reader.reader("Hello")
  assert string_reader.peek(sut) == option.Some("H")
  assert string_reader.peek(sut) == option.Some("H")
}

pub fn next_test() {
  let sut = string_reader.reader("Hello")
  let #(sut, value) = string_reader.next(sut)
  assert option.Some("H") == value
  let #(sut, value) = string_reader.next(sut)
  assert option.Some("e") == value
  let #(sut, value) = string_reader.next(sut)
  assert option.Some("l") == value
  let #(sut, value) = string_reader.next(sut)
  assert option.Some("l") == value
  let #(sut, value) = string_reader.next(sut)
  assert option.Some("o") == value
  let #(_sut, value) = string_reader.next(sut)
  assert option.None == value
}
