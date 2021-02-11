/**
 * Сущность Token
*/

enum TokenType {
  IDENT,
  NUMBER,
  KEYWORD,

  LPAR,
  RPAR,

  PLUS,
  MINUS,
  STAR,
  SLASH,

  MORE,
  LESS,
  NOT_EQ,
  EQ,

  SET_EQ,

  SEM, // ;
  COMMA, // ,
  END_POINT, // .

  EOF
}

class Token {
  final String value;
  final TokenType type;
  final int line; // номер строки в программе, на которой находится лексема

  Token(this.type, this.value, this.line);

  String toString() => "Token[$line]($type, $value)";
}
