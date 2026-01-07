import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string.{to_graphemes, trim}

type Delimiter =
  String

type CarryString =
  #(String, Delimiter)

pub fn parse_args(body: String) {
  let tokens = body |> trim() |> to_graphemes

  case parse_args_recursive(tokens, None, "", []) {
    Ok(args) -> Ok(args |> list.reverse)
    Error(_) as err -> err
  }
}

fn parse_args_recursive(
  tokens tokens: List(String),
  carry_string carry_string: Option(CarryString),
  carry_arg carry_arg: String,
  args args: List(String),
) -> Result(List(String), String) {
  case tokens {
    ["\\", escaped, ..rest] -> {
      case carry_string {
        Some(#(partial, delimiter)) ->
          parse_args_recursive(
            tokens: rest,
            carry_string: Some(#(
              case escaped {
                val if val == delimiter -> partial <> escaped
                val -> {
                  case delimiter {
                    "\"" ->
                      case escaped {
                        "\\" -> partial <> escaped
                        "$" -> partial <> escaped
                        "`" -> partial <> escaped
                        "\n" -> partial <> escaped
                        _ -> partial <> "\\" <> val
                      }
                    _ -> partial <> "\\" <> val
                  }
                }
              },
              delimiter,
            )),
            carry_arg:,
            args:,
          )
        None ->
          parse_args_recursive(
            tokens: rest,
            carry_string:,
            carry_arg: carry_arg <> escaped,
            args:,
          )
      }
    }
    tokens -> {
      case carry_string {
        Some(#(partial, delimiter)) ->
          case tokens {
            [a, b, ..rest] if a == delimiter && b == delimiter -> {
              parse_args_recursive(
                tokens: rest,
                carry_string: Some(#(partial, delimiter)),
                carry_arg: "",
                args:,
              )
            }
            [a, " ", ..rest] if a == delimiter -> {
              parse_args_recursive(
                tokens: rest,
                carry_string: None,
                carry_arg: "",
                args: case partial {
                  "" -> args
                  arg -> [arg, ..args]
                },
              )
            }
            [a, ..rest] if a == delimiter -> {
              parse_args_recursive(
                tokens: rest,
                carry_string: None,
                carry_arg: partial,
                args:,
              )
            }
            [token, ..rest] -> {
              parse_args_recursive(
                tokens: rest,
                carry_string: Some(#(partial <> token, delimiter)),
                carry_arg: "",
                args:,
              )
            }
            [] -> Error("Missing end quote for string")
          }
        None ->
          case tokens {
            [] ->
              case carry_arg {
                "" -> Ok(args)
                arg -> Ok([arg, ..args])
              }
            [token, ..rest] -> {
              case token {
                "'" | "\"" ->
                  parse_args_recursive(
                    tokens: rest,
                    carry_string: Some(#(carry_arg, token)),
                    carry_arg: "",
                    args:,
                  )
                " " ->
                  parse_args_recursive(
                    tokens: rest,
                    carry_string: None,
                    carry_arg: "",
                    args: case carry_arg {
                      "" -> args
                      arg -> [arg, ..args]
                    },
                  )
                token ->
                  parse_args_recursive(
                    tokens: rest,
                    carry_string: None,
                    carry_arg: carry_arg <> token,
                    args:,
                  )
              }
            }
          }
      }
    }
  }
}
