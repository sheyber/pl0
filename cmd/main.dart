import 'dart:convert';

import './compiler/syntax_analyzer/scanner.dart';
import 'compiler/syntax_analyzer/parser.dart';

void main(List<String> args) {
  // print('hello!');
  var tokens = Scanner.lex('var x, y; begin x := 7; y := 1; end. ');
  // tokens.forEach((element) {
  //   print(element.toString());
  // });
  var ast = Parser(tokens).parse();
  // print(ast);
  ast.forEach(print);
}
