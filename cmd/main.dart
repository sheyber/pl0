import 'dart:io';

import './compiler/syntax_analyzer/scanner.dart';
import 'compiler/gen.dart';
import 'compiler/syntax_analyzer/parser.dart';
import 'vmachine/pcode.dart';

void main(List<String> args) {
  var code = '''
var n, f;
begin
   n := 0;
   f := 1;
   while n # 16 do 
   begin
      n := n + 1;
      f := f * n;
   end;
end.
  ''';
  var tokens = Scanner.lex(code);
  var program_ast = Parser(tokens).parse();
  print(program_ast);
  // CodeGenerator(program_ast).compile().forEach(print);
  var pcodes = CodeGenerator(program_ast).compile();
  pcodes.forEach(print);
  // print(PCode(Instructions.JMP, 'heh'));
}
