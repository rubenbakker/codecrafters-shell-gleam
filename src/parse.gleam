import gleam/list
import gleam/result
import gleam/string
import party

pub fn parse(input: String) -> Result(List(String), Nil) {
  let result = parse_command_with_quotes(string.drop_right(input, 1))
  Ok(result)
}

fn parse_command_with_quotes(command: String) -> List(String) {
  parse_command_with_quotes_inner(command, [], [], False)
}

fn parse_command_with_quotes_inner(
  remaining: String,
  current_token: List(String),
  tokens: List(String),
  in_quotes: Bool,
) -> List(String) {
  case string.pop_grapheme(remaining) {
    Ok(#("'", rest)) -> {
      parse_command_with_quotes_inner(rest, current_token, tokens, !in_quotes)
    }

    Ok(#(char, rest)) -> {
      case in_quotes {
        True ->
          parse_command_with_quotes_inner(
            rest,
            list.append(current_token, [char]),
            tokens,
            True,
          )

        False -> {
          case char {
            " " -> {
              let new_tokens = case current_token {
                [] -> tokens
                _ -> list.append(tokens, [string.concat(current_token)])
              }
              parse_command_with_quotes_inner(rest, [], new_tokens, False)
            }

            _ ->
              parse_command_with_quotes_inner(
                rest,
                list.append(current_token, [char]),
                tokens,
                False,
              )
          }
        }
      }
    }

    Error(_) -> {
      case current_token {
        [] -> tokens
        _ -> list.append(tokens, [string.concat(current_token)])
      }
    }
  }
}

pub fn parse_old(input: String) -> Result(List(String), Nil) {
  let input =
    input
    |> string.trim()
    |> string.replace("''", "")
  let args_parser = party.many(arguments_parser())
  party.go(args_parser, input)
  |> result.map(fn(result) {
    list.filter(result, fn(x) { !string.is_empty(x) })
  })
  |> result.map_error(fn(_) { Nil })
}

type Parser(a) =
  party.Parser(a, party.ParseError(String))

fn double_quoted_string() -> Parser(String) {
  party.between(party.char("\""), up_to(["\""]), party.char("\""))
}

fn single_quoted_string() -> Parser(String) {
  party.between(party.char("'"), up_to(["'"]), party.char("'"))
}

pub fn arguments_parser() -> Parser(String) {
  [bare_string(), single_quoted_string(), double_quoted_string(), whitespace()]
  |> party.choice
}

fn whitespace() -> Parser(String) {
  use _ <- party.do(party.whitespace1())
  party.return("")
}

fn bare_string() -> Parser(String) {
  up_to1([" ", "\t", "\n", "'", "\""])
}

fn up_to(unwanted: List(String)) -> Parser(String) {
  party.many_concat(party.satisfy(fn(c) { !list.contains(unwanted, c) }))
}

fn up_to1(unwanted: List(String)) -> Parser(String) {
  party.many1_concat(party.satisfy(fn(c) { !list.contains(unwanted, c) }))
}
