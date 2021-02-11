import './compiler/syntax_analyzer/scanner.dart';

void main(List<String> args) {
  print('hello!');
  var tokens = Scanner.lex('if x > 5 then y := 5 * 2 ');
  tokens.forEach((element) {
    print(element.toString());
  });
}
