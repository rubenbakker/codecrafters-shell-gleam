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
  Parser(
    reader: Reader,
    mode: ParserMode,
    args: List(String),
    current_arg: String,
  )
}

fn create_parser(arg_string: String) -> Parser {
  Parser(
    reader: string_reader.reader(arg_string),
    mode: Whitespace,
    args: [],
    current_arg: "",
  )
}

fn parse_to_end(parser: Parser) -> Result(List(String), ParseError) {
  case parser.mode {
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
        False -> determine_mode(parser)
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
      parser |> advance() |> change_mode(End) |> add_arg()
    }
    option.Some(value) -> {
      case value {
        "\\" -> {
          parser |> advance() |> consume_word_escaped()
        }
        _ -> {
          case !list.contains(non_word, value) {
            True -> advance(parser) |> append_to_arg(value) |> consume_word()
            False -> parser |> add_arg() |> determine_mode()
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
      parser |> advance() |> change_mode(End) |> add_arg()
    }
    option.Some(value) ->
      advance(parser) |> append_to_arg(value) |> consume_word()
  }
}

fn consume_double_quote(parser: Parser) -> Parser {
  let next = string_reader.peek(parser.reader)
  case next {
    option.None -> {
      parser |> advance() |> change_mode(End) |> add_arg()
    }
    option.Some(value) -> {
      case value {
        "\"" ->
          case parser.current_arg {
            "" -> parser |> advance() |> consume_double_quote()
            _ -> parser |> advance() |> determine_mode()
          }
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
      parser |> advance() |> change_mode(End) |> add_arg()
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
      parser |> advance() |> change_mode(End) |> add_arg()
    }
    option.Some(value) -> {
      case value == "'" {
        True ->
          case parser.current_arg {
            "" -> parser |> advance() |> consume_single_quote()
            _ -> parser |> advance() |> add_arg() |> determine_mode()
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

fn determine_mode(parser: Parser) -> Parser {
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
  parser |> add_arg_if_needed(mode) |> change_mode(mode)
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
