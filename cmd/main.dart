import 'dart:io';

import './compiler/syntax_analyzer/scanner.dart';
import 'compiler/gen.dart';
import 'compiler/syntax_analyzer/parser.dart';
import 'vmachine/pcode.dart';
import 'vmachine/vmachine.dart';

void main(List<String> args) {
  if (args.isNotEmpty) {
    if (args[0] == '-e') {
      var code = args[1];
      var tokens = Scanner.lex(code);
      var program_ast = Parser(tokens).parse();
      var pcodes = CodeGenerator(program_ast).compile();
      VirtualMachine().run(pcodes);
    }
  }
}
