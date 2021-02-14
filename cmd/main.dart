import 'dart:io';

import './compiler/syntax_analyzer/scanner.dart';
import 'compiler/gen.dart';
import 'compiler/syntax_analyzer/parser.dart';
import 'vmachine/pcode.dart';
import 'vmachine/vmachine.dart';
import './compiler/middle/optimization.dart';

void main(List<String> args) {
  if (args.isNotEmpty) {
    if (args[0] == '-e') {
      var code = args[1];
      var tokens = Scanner.lex(code);
      var program_ast = Parser(tokens).parse();
      // testing
      program_ast = Optimization(program_ast).getProgram();
      // end testing
      var pcodes = CodeGenerator(program_ast).compile();
      VirtualMachine().run(pcodes);
    } else if (args[0] == '-edev') {
      var code = args[1];
      var tokens = Scanner.lex(code);
      var program_ast = Parser(tokens).parse();
      // testing
      program_ast = Optimization(program_ast).getProgram();
      // end testing
      var pcodes = CodeGenerator(program_ast).compile();
      VirtualMachine().run(pcodes, dumpFrames: true, dumpStack: true);
    } else if (args[0] == '-asm' || args[0] == '-asm-no') {
      var code = args[1];
      var tokens = Scanner.lex(code);
      var program_ast = Parser(tokens).parse();
      // testing
      if (args[0] != '-asm-no')
        program_ast = Optimization(program_ast).getProgram();
      // end testing
      var pcodes = CodeGenerator(program_ast).compile();
      print_asm_pcode(pcodes);
    }
  } else {
    print('''
↬ PL/0 programming language. Ugly implementation written in Dart.
    -e 'source code'    | execute code
    -edev 'source code' | execute code with debug info
    -asm 'source code'  | print a asm like PCode format''');
  }
}

void print_asm_pcode(List<PCode> pcodes) {
  for (var i in pcodes) {
    if (i.arg != 'main_start_point' &&
        i.type != Instructions.LABEL &&
        i.type != Instructions.DEFINE_CONST) stdout.write('\t');
    if (i.type == Instructions.LABEL) {
      print('\u001b[35m$i \u001b[0m');
    } else {
      print(i);
    }
  }
}
