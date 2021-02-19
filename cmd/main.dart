import 'dart:io';

import './compiler/syntax_analyzer/scanner.dart';
import 'compiler/gen.dart';
import 'compiler/middle/semantic_checker.dart';
import 'compiler/syntax_analyzer/parser.dart';
import 'vmachine/pcode.dart';
import 'vmachine/vmachine.dart';
import './compiler/middle/optimization.dart';

class CLI {
  // общие
  List<String> _args;
  List<String> _flags;
  String _nameOfFile;
  // параметры интерпретации
  bool _showAsm, _dupmsInfoAboutExec, _optimization, _checkSemantic;

  CLI(this._args)
      : _flags = List<String>(),
        _showAsm = false,
        _dupmsInfoAboutExec = false,
        _optimization = true,
        _checkSemantic = true {
    this._parse();
    this._executeFlags();
  }

  void _parse() {
    for (var arg in _args) {
      if (arg[0] == '-')
        _flags.add(arg);
      else
        _nameOfFile = arg;
    }

    if (_nameOfFile == null || _nameOfFile.isEmpty) {
      print('Не указан файл');
      exit(0);
    }
  }

  void _executeFlags() {
    for (var flag in _flags)
      switch (flag) {
        case '-asm':
          _showAsm = true;
          break;
        case '-no':
          _optimization = false;
          break;
        case '-dev':
          _dupmsInfoAboutExec = true;
          break;
        case '-ns':
          _checkSemantic = false;
          break;
        default:
          print('unknow option `$flag`');
          exit(0);
      }
  }

  String _loadFile(String namefile) {
    try {
      return File(namefile).readAsStringSync();
    } catch (e) {
      print(e);
      exit(0);
    }
  }

  void execute() {
    // Syntax analyzing
    var sourceCode = _loadFile(_nameOfFile);
    var tokens = Scanner.lex(sourceCode);
    var node = Parser(tokens).parse();

    // middle step
    if (_checkSemantic) SemanticChecker(node).check();
    if (_optimization) node = Optimization(node).getProgram();

    // кодогенерация
    var pcodes = CodeGenerator(node).compile();

    // доп.
    if (_showAsm) {
      _printAsm(pcodes);
      exit(0);
    }

    // этап исполнения
    var vm = VirtualMachine();
    vm.run(pcodes,
        dumpFrames: _dupmsInfoAboutExec, dumpStack: _dupmsInfoAboutExec);
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
  if (args.length > 0)
    CLI(args).execute();
  else
    print('''
Ugly implementation PL/0 written in Dart. <3
Usage: pl0 [options] file
Options:
  -no         execute without optimization
  -ns         skip semantic checker
  -dev        dump results of works virtual machine
  -asm        print PCode/IR as asm-like style''');
}
