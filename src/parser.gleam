import gleam/list
import gleam/option
import gleam/string
import string_reader.{type Reader}

const whitespace = [" ", "\r", "\n", "\t"]

const non_word = [" ", "\r", "\n", "\t", "\"", "'"]

pub type ParseError

pub fn parse(arg_string: String) -> Result(List(String), ParseError) {
  create_parser(arg_string) |> parse_to_end()
}

type ParserMode {
  Word
  Whitespace
  DoubleQuote
  SingleQuote
  End
}

type Parser {
  Parser(reader: Reader, mode: ParserMode, args: List(String))
}

fn create_parser(arg_string: String) -> Parser {
  let arg_string =
    arg_string |> string.replace("\"\"", "") |> string.replace("''", "")
  Parser(reader: string_reader.reader(arg_string), mode: Whitespace, args: [])
}

fn parse_to_end(parser: Parser) -> Result(List(String), ParseError) {
  case parser.mode {
    Whitespace -> skip_whitespace(parser) |> parse_to_end()
    Word -> consume_word(parser, "") |> parse_to_end()
    DoubleQuote -> consume_double_quote(parser, "") |> parse_to_end()
    SingleQuote -> consume_single_quote(parser, "") |> parse_to_end()
    End -> Ok(parser.args)
  }
}

fn advance(parser: Parser) -> Parser {
  let #(reader, _) = string_reader.next(parser.reader)
  Parser(..parser, reader: reader)
}

fn change_mode(parser: Parser, mode: ParserMode) -> Parser {
  Parser(..parser, mode: mode)
}

fn skip_whitespace(parser: Parser) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> parser |> advance() |> change_mode(End)
    option.Some(value) ->
      case list.contains(whitespace, value) {
        True -> advance(parser) |> skip_whitespace()
        False -> determine_mode(parser, value)
      }
  }
}

fn add_arg(parser: Parser, arg: String) -> Parser {
  case arg {
    "" -> parser
    _ -> Parser(..parser, args: list.append(parser.args, [arg]))
  }
}

fn consume_word(parser: Parser, arg: String) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> change_mode(End) |> add_arg(arg)
    }
    option.Some(value) -> {
      case value {
        "\\" -> {
          parser |> advance() |> consume_word_escaped(arg)
        }
        _ -> {
          case !list.contains(non_word, value) {
            True -> advance(parser) |> consume_word(string.concat([arg, value]))
            False -> parser |> add_arg(arg) |> determine_mode(value)
          }
        }
      }
    }
  }
}

fn consume_word_escaped(parser: Parser, arg: String) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> change_mode(End) |> add_arg(arg)
    }
    option.Some(value) ->
      advance(parser) |> consume_word(string.concat([arg, value]))
  }
}

fn consume_double_quote(parser: Parser, arg: String) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> change_mode(End) |> add_arg(arg)
    }
    option.Some(value) -> {
      case value {
        "\"" ->
          case arg {
            "" -> parser |> advance() |> consume_double_quote(arg)
            _ -> {
              case determine_mode(parser, value).mode {
                DoubleQuote -> parser |> advance() |> consume_double_quote(arg)
                _ -> parser |> add_arg(arg) |> determine_mode(value)
              }
            }
          }
        "\\" -> parser |> advance() |> consume_double_quote_escaped(arg)
        _ ->
          advance(parser) |> consume_double_quote(string.concat([arg, value]))
      }
    }
  }
}

fn consume_double_quote_escaped(parser: Parser, arg: String) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> change_mode(End) |> add_arg(arg)
    }
    option.Some(value) ->
      advance(parser) |> consume_double_quote(string.concat([arg, value]))
  }
}

fn consume_single_quote(parser: Parser, arg: String) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> change_mode(End) |> add_arg(arg)
    }
    option.Some(value) -> {
      case value == "'" {
        True ->
          case arg {
            "" -> parser |> advance() |> consume_single_quote(arg)
            _ -> {
              case determine_mode(parser, value).mode {
                SingleQuote -> parser |> advance() |> consume_single_quote(arg)
                _ -> parser |> add_arg(arg) |> determine_mode(value)
              }
            }
          }
        False ->
          advance(parser) |> consume_single_quote(string.concat([arg, value]))
      }
    }
  }
}

fn determine_mode(parser: Parser, char: String) -> Parser {
  let mode = case char {
    "" -> End
    "\"" -> DoubleQuote
    "'" -> SingleQuote
    " " -> Whitespace
    "\r" -> Whitespace
    "\n" -> Whitespace
    "\t" -> Whitespace
    _ -> Word
  }
  change_mode(parser, mode)
}
