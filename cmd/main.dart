import 'dart:io';

import './compiler/syntax_analyzer/scanner.dart';
import 'compiler/syntax_analyzer/parser.dart';

void main(List<String> args) {
  if (args.isEmpty) exit(0);
  var code = File(args[0]).readAsStringSync();
  var tokens = Scanner.lex(code);
  var program_ast = Parser(tokens).parse();
  print(program_ast);
}
