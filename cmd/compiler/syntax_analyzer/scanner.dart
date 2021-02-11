import 'dart:io';

import 'token.dart';

/**
 * Элементарный лексийческий анализ с посимвольным анализом. 
*/

class Scanner {
  static final String _number = '0123456789';
  static final String _word = 'qwertyuiopasdfghjklzxcvbnm_';

  static const _syms = {
    '+': TokenType.PLUS,
    '-': TokenType.MINUS,
    '*': TokenType.STAR,
    '/': TokenType.SLASH,
    '=': TokenType.EQ,
    '>': TokenType.MORE,
    '<': TokenType.LESS,
    '#': TokenType.NOT_EQ,
    ';': TokenType.SEM,
    ',': TokenType.COMMA
  };

  static const _keywords = [
    'begin',
    'end',
    'const',
    'var',
    'if',
    'then',
    'while',
    'do',
    'procedure',
    'call'
  ];

  static List<Token> lex(String source) {
    var lines = 1;
    var tokens = List<Token>();

    for (var i = 0; i < source.length; i++) {
      var current = source[i];
      if (_number.contains(current)) {
        var value = "";
        while (i < source.length && _number.contains(source[i]))
          value += source[i++];
        tokens.add(Token(TokenType.NUMBER, value, lines));
        continue;
      } else if (_word.contains(current)) {
        var value = "";
        while (i < source.length && _word.contains(source[i]))
          value += source[i++];
        var type = (_isKeyword(value)) ? TokenType.KEYWORD : TokenType.IDENT;
        tokens.add(Token(type, value, lines));
        continue;
      } else if (i < source.length - 1 && (current + source[i + 1]) == ':=') {
        tokens.add(Token(TokenType.SET_EQ, current + source[++i], lines));
      } else if (_isSym(current)) {
        tokens.add(Token(_syms[current], current, lines));
      } else if (current == '\n') {
        lines++;
      } else if (current != ' ' && current != '\t') {
        _throwScannerError('unknow token "$current"', line: lines);
      }
    }

    tokens.add(Token(TokenType.EOF, 'EOF', -1));
    return tokens;
  }

  static bool _isKeyword(String value) => _keywords.contains(value);
  static bool _isSym(String value) => _syms.containsKey(value);

  static _throwScannerError(String msg, {int line}) {
    print("ScannerError[$line]: $msg");
    exit(0);
  }
}
