import 'dart:io';

import './compiler/syntax_analyzer/scanner.dart';
import 'compiler/gen.dart';
import 'compiler/middle/semantic_checker.dart';
import 'compiler/syntax_analyzer/parser.dart';
import 'vmachine/pcode.dart';
import 'vmachine/vmachine.dart';
import './compiler/middle/optimization.dart';

class CLIPL0 {
  static void executeCode(String source,
      {semanticChecker = true,
      optimization = true,
      dumpInfoAboutVM = false,
      seeAsm = false}) {
    var tokens = Scanner.lex(source);
    var ast = Parser(tokens).parse();

    if (semanticChecker) {
      var correct = SemanticChecker(ast).check();
      if (!correct) exit(0);
    }

    if (optimization) {
      ast = Optimization(ast).getProgram();
    }

    var lir = CodeGenerator(ast).compile();

    if (seeAsm) {
      _printAsm(lir);
      return;
    }

    VirtualMachine()
        .run(lir, dumpFrames: dumpInfoAboutVM, dumpStack: dumpInfoAboutVM);
  }

  static void _printAsm(List<PCode> pcodes) {
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
}

void main(List<String> args) {
  if (args.isNotEmpty) {
    if (args[0] == '-e') {
      var code = args[1];
      CLIPL0.executeCode(code);
    } else if (args[0] == '-edev') {
      var code = args[1];
      CLIPL0.executeCode(code, dumpInfoAboutVM: true);
    } else if (args[0] == '-asm') {
      var code = args[1];
      CLIPL0.executeCode(code, seeAsm: true);
    } else if (args[0] == '-asm-no') {
      var code = args[1];
      CLIPL0.executeCode(code, seeAsm: true, optimization: false);
    } else {
      try {
        var code = File(args[0]).readAsStringSync();
        CLIPL0.executeCode(code);
      } catch (e) {
        print(e);
      }
    }
    return;
  }

  print('''
↬ PL/0 programming language. Ugly implementation written in Dart.
    file                  | execure a file
    -e 'source code'      | execute a code
    -edev 'source code'   | execute a code with debug info
    -asm 'source code'    | print a IR as asm
    -asm-no 'source code' | print a IR as asm without optimization''');
}
