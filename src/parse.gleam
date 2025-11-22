import gleam/list
import gleam/result
import gleam/string
import party

pub fn parse(input: String) -> Result(List(String), Nil) {
  let input = string.trim(input)
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
