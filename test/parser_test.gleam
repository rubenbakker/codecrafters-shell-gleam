import parser

pub fn simple_parse_args_test() {
  assert Ok(["/usr/bin/bar", "file", "gugus"])
    == parser.parse("/usr/bin/bar file gugus")
  assert Ok(["/usr/bin/bar", "file", "gugus"])
    == parser.parse("    /usr/bin/bar     file    gugus     ")
}

pub fn double_quoted_args_test() {
  assert Ok(["/usr/bin/bar", "multiple   words", "yesyes"])
    == parser.parse("/usr/bin/bar \"multiple   words\" \"yes\"\"yes\"")
  assert Ok(["/usr/bin/bar", "multiple   words", "yesyes"])
    == parser.parse("/usr/bin/bar \"multiple   words\" yes\"\"yes")
}

pub fn single_quoted_args_test() {
  assert Ok(["/usr/bin/bar", "multiple   words", "yesyes"])
    == parser.parse("/usr/bin/bar 'multiple   words' \"yes''yes\"")
  assert Ok(["/usr/bin/bar", "multiple   words", "yesyes"])
    == parser.parse("/usr/bin/bar 'multiple   words' yes''yes")
}

pub fn escaping_test() {
  assert Ok(["/usr/bin/bar", "'multiple   words'", "yesyes"])
    == parser.parse("/usr/bin/bar \\'multiple\\ \\ \\ words\\'  yesyes   ")
}

pub fn concat_args() {
  assert Ok(["/usr/bin/bar", "multiple wordsyesyes"])
    == parser.parse("/usr/bin/bar \"multiple words\"yesyes")
}
// pub fn double_quote_escaping_test() {
//   io.println("/usr/bin/bar \"this is \\\"funny\\\"\" yes")
//   assert Ok(["/usr/bin/bar", "this is \"funny\"", "yes"])
//     == parser.parse("/usr/bin/bar \"this is \\\"funny\\\"\" yes")
// }
