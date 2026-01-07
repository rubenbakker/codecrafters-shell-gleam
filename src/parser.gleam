import gleam/list
import gleam/option
import gleam/result
import gleam/string
import string_reader.{type Reader}

const whitespace = [" ", "\r", "\n", "\t"]

const non_word = [" ", "\r", "\n", "\t", "\"", "'"]

pub type ParseError

pub fn parse(arg_string: String) -> Result(List(String), Nil) {
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
  Parser(
    reader: Reader,
    mode: List(ParserMode),
    args: List(String),
    current_arg: String,
  )
}

fn create_parser(arg_string: String) -> Parser {
  Parser(
    reader: string_reader.reader(arg_string),
    mode: [Whitespace],
    args: [],
    current_arg: "",
  )
}

fn parse_to_end(parser: Parser) -> Result(List(String), Nil) {
  use mode <- result.try(list.first(parser.mode))
  case mode {
    Whitespace -> skip_whitespace(parser) |> parse_to_end()
    Word -> consume_word(parser) |> parse_to_end()
    DoubleQuote -> consume_double_quote(parser) |> parse_to_end()
    SingleQuote -> consume_single_quote(parser) |> parse_to_end()
    End -> Ok(parser.args)
  }
}

fn advance(parser: Parser) -> Parser {
  let #(reader, _) = string_reader.next(parser.reader)
  Parser(..parser, reader: reader)
}

fn push_mode(parser: Parser, mode: ParserMode) -> Parser {
  echo #("push_mode", parser, mode)
  Parser(..parser, mode: list.prepend(parser.mode, mode))
}

fn pop_mode(parser: Parser) -> Parser {
  echo #("pop_mode", parser)
  Parser(..parser, mode: list.drop(parser.mode, 1))
}

fn pop_mode_with_value(parser: Parser, value: String) -> Parser {
  let parser = Parser(..parser, mode: list.drop(parser.mode, 1))
  let assert Ok(mode) = list.first(parser.mode)
  {
    case mode {
      DoubleQuote -> parser |> append_to_arg(value)
      _ -> parser
    }
  }
}

fn skip_whitespace(parser: Parser) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> parser |> advance() |> push_mode(End)
    option.Some(value) ->
      case list.contains(whitespace, value) {
        True -> advance(parser) |> skip_whitespace()
        False -> parser |> pop_mode() |> determine_and_push_mode()
      }
  }
}

fn append_to_arg(parser: Parser, value: String) -> Parser {
  Parser(..parser, current_arg: string.concat([parser.current_arg, value]))
}

fn add_arg(parser: Parser) -> Parser {
  case parser.current_arg {
    "" -> parser
    _ ->
      Parser(
        ..parser,
        args: list.append(parser.args, [parser.current_arg]),
        current_arg: "",
      )
  }
}

fn consume_word(parser: Parser) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> pop_mode() |> determine_and_push_mode()
    }
    option.Some(value) -> {
      case value {
        "\\" -> {
          parser |> advance() |> consume_word_escaped()
        }
        _ -> {
          case !list.contains(non_word, value) {
            True -> advance(parser) |> append_to_arg(value) |> consume_word()
            False -> parser |> determine_and_push_mode()
          }
        }
      }
    }
  }
}

fn consume_word_escaped(parser: Parser) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> determine_and_push_mode()
    }
    option.Some(value) ->
      advance(parser) |> append_to_arg(value) |> consume_word()
  }
}

fn consume_double_quote(parser: Parser) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> determine_and_push_mode()
    }
    option.Some(value) -> {
      case value {
        "\"" ->
          case parser.current_arg {
            "" -> parser |> advance() |> consume_double_quote()
            _ -> parser |> advance() |> push_mode(SingleQuote)
          }
        "'" ->
          parser
          |> advance()
          |> append_to_arg(value)
          |> push_mode(SingleQuote)
        "\\" -> parser |> advance() |> consume_double_quote_escaped()
        _ ->
          parser
          |> advance()
          |> append_to_arg(value)
          |> consume_double_quote()
      }
    }
  }
}

fn consume_double_quote_escaped(parser: Parser) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> determine_and_push_mode()
    }
    option.Some(value) ->
      case value {
        "\"" | "\\" ->
          advance(parser) |> append_to_arg(value) |> consume_double_quote()
        _ ->
          advance(parser)
          |> append_to_arg(value)
          |> consume_double_quote()
      }
  }
}

fn consume_single_quote(parser: Parser) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> determine_and_push_mode()
    }
    option.Some(value) -> {
      case value == "'" {
        True -> {
          case parser.current_arg {
            "" -> parser |> advance() |> consume_single_quote()
            _ -> parser |> advance() |> pop_mode_with_value(value)
          }
        }
        False ->
          parser
          |> advance()
          |> append_to_arg(value)
          |> consume_single_quote()
      }
    }
  }
}

fn determine_and_push_mode(parser: Parser) -> Parser {
  let value = string_reader.peek(parser.reader)
  let mode = case value {
    option.None -> End
    option.Some(char) -> {
      case char {
        "" -> End
        "\"" -> DoubleQuote
        "'" -> SingleQuote
        " " -> Whitespace
        "\r" -> Whitespace
        "\n" -> Whitespace
        "\t" -> Whitespace
        _ -> Word
      }
    }
  }
  parser |> add_arg_if_needed(mode) |> push_mode(mode)
}

fn add_arg_if_needed(parser: Parser, new_mode: ParserMode) -> Parser {
  case parser.current_arg == "" {
    True -> parser
    False -> {
      case new_mode {
        End | Whitespace -> add_arg(parser)
        _ -> parser
      }
    }
  }
}
