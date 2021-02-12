import 'dart:io';

import 'token.dart';

/* Синтаксический анализ & Постройка AST
  program = block "." .
  block = [ "const" ident "=" number {"," ident "=" number} ";"]
          [ "var" ident {"," ident} ";"]
          { "procedure" ident ";" block ";" } statement .
  statement = [ ident ":=" expression | "call" ident |
              "begin" statement {";" statement } "end" |
              "if" condition "then" statement |
              "while" condition "do" statement ].
  condition = expression ("="|"#"|"<"|">") expression .
  expression = [ "+"|"-"] term { ("+"|"-") term}.
  term = factor {("*"|"/") factor}.
  factor = ident | number | "(" expression ")".
*/

enum NodeType {
  CONST_NUMBER,
  VARIABLE_NAME,
  MULTIPLY,
  DIV,
  ADD,
  SUB,
  EQ,
  NOT_EQ,
  MORE,
  LESS,
  SET_VAR,
  CALL_PROC,
  BLOCK,
  IF,
  WHILE,
  SET_CONST,
  DEC_VARS,
  PROC_DEFINE,
  MAIN_BLOCK,
  // ...
}

class Parser {
  List<Token> _tokens;
  int _pos;

  Parser(this._tokens) : _pos = 0;

  // Вспомогательные методы для перемещения по списку токенов
  Token _nextToken() => _tokens[_pos++];
  Token _backToken() => _tokens[--_pos];
  Token _getCurrentToken() => _tokens[_pos];

  // factor = ident | number | "(" expression ")".
  Map _factor() {
    var current = _nextToken();
    if (current.type == TokenType.IDENT) {
      return {
        'type': NodeType.VARIABLE_NAME,
        'name': current.value,
        'meta-line': current.line
      };
    } else if (current.type == TokenType.NUMBER) {
      return {
        'type': NodeType.CONST_NUMBER,
        'value': current.value,
        'meta-line': current.line
      };
    } else if (current.type == TokenType.LPAR) {
      var expr = _expression();
      _here_must_be(')', _getCurrentToken());
      return expr;
    }
    _throwSimpleSyntaxError(
        'can\'t make a node in factor:\n\t${_debugLine(current)}\n\t↑',
        current);
  }

  // term = factor {("*"|"/") factor}.
  Map _term() {
    var value = _factor();
    while (true) {
      var current = _nextToken();
      if (current.type == TokenType.STAR) {
        value = {
          'type': NodeType.MULTIPLY,
          'left': value,
          'right': _factor(),
          'meta-line': _getCurrentToken().line
        };
      } else if (current.type == TokenType.SLASH) {
        value = {
          'type': NodeType.DIV,
          'left': value,
          'right': _factor(),
          'meta-line': _getCurrentToken().line
        };
      } else {
        _backToken();
        return value;
      }
    }
  }

  // expression = [ "+"|"-"] term { ("+"|"-") term}.
  Map _expression() {
    var value = _term();
    while (true) {
      var current = _nextToken();
      if (current.type == TokenType.PLUS) {
        value = {
          'type': NodeType.ADD,
          'left': value,
          'right': _term(),
          'meta-line': _getCurrentToken().line
        };
      } else if (current.type == TokenType.MINUS) {
        value = {
          'type': NodeType.SUB,
          'left': value,
          'right': _term(),
          'meta-line': _getCurrentToken().line
        };
      } else {
        _backToken();
        return value;
      }
    }
  }

  // condition = expression ("="|"#"|"<"|">") expression .
  Map _condition() {
    // dry
    var value = _expression();
    while (true) {
      var current = _nextToken();
      if (current.type == TokenType.EQ) {
        value = {
          'type': NodeType.EQ,
          'left': value,
          'right': _expression(),
          'meta-line': _getCurrentToken().line
        };
      } else if (current.type == TokenType.NOT_EQ) {
        value = {
          'type': NodeType.NOT_EQ,
          'left': value,
          'right': _expression(),
          'meta-line': _getCurrentToken().line
        };
      } else if (current.type == TokenType.MORE) {
        value = {
          'type': NodeType.MORE,
          'left': value,
          'right': _expression(),
          'meta-line': _getCurrentToken().line
        };
      }
      if (current.type == TokenType.LESS) {
        value = {
          'type': NodeType.LESS,
          'left': value,
          'right': _expression(),
          'meta-line': _getCurrentToken().line
        };
      } else {
        _backToken();
        return value;
      }
    }
  }

  Map _statement() {
    var current = _nextToken();
    if (current.type == TokenType.IDENT) {
      // ident ":=" expression
      var name = current.value;
      _here_must_be(':=', _getCurrentToken());
      var value = _expression();
      return {
        'type': NodeType.SET_VAR,
        'name': name,
        'value': value,
        'meta-line': _getCurrentToken().line
      };
    } else if (current.type == TokenType.KEYWORD) {
      if (current.value == 'call') {
        // "call" ident
        return {
          'type': NodeType.CALL_PROC,
          'name': _nextToken().value,
          'meta-line': _getCurrentToken().line
        };
      } else if (current.value == 'begin') {
        // "begin" statement {";" statement } "end"
        var body = [];
        if (_nextToken().value != 'end') {
          try {
            _backToken();
            while (true) {
              body.add(_statement());
              var ntoken = _nextToken();
              if (ntoken.type == TokenType.SEM) if (_nextToken().value == 'end')
                break;
              else
                _backToken();
              else if (ntoken.value == 'end')
                break;
              else if (ntoken.value != 'end' && ntoken.type != TokenType.SEM)
                _throwSimpleSyntaxError(
                    'after statment must be `;` in ...', // следует добавить
                    ntoken);
              else
                _throwSimpleSyntaxError(
                    'can\'t found a `end` for close the block', ntoken);
            }
          } catch (e) {
            _throwSimpleSyntaxError(e.toString(), _getCurrentToken());
          }
        }
        return {
          'type': NodeType.BLOCK,
          'body': body,
          'meta-line': current.line
        };
      } else if (current.value == 'if') {
        // "if" condition "then" statement
        var cond = _condition();
        _here_must_be('then', _nextToken());
        var stmt = _statement();
        return {
          'type': NodeType.IF,
          'cond': cond,
          'body': stmt,
          'meta-line': current.line
        };
      } else if (current.value == 'while') {
        // "while" condition "do" statement
        var cond = _condition();
        _here_must_be('do', _nextToken());
        var stmt = _statement();
        return {
          'type': NodeType.WHILE,
          'cond': cond,
          'body': stmt,
          'meta-line': current.line
        };
      }
    }
    _backToken();
    return _condition();
  }

  Map _block({in_procedure = false}) {
    var current = _nextToken();
    if (current.type == TokenType.KEYWORD) {
      if (current.value == 'const') {
        // "const" ident "=" number {"," ident "=" number} ";"
        var pairs = [];
        try {
          while (true) {
            var name = _nextToken().value;
            _here_must_be('=', _getCurrentToken());
            var value = _factor()['value'];
            pairs.add([name, value]);
            var ntoken = _nextToken();

            if (ntoken.type == TokenType.COMMA)
              continue;
            else if (ntoken.type == TokenType.SEM)
              break;
            else if (ntoken.type != TokenType.SEM &&
                ntoken.type != TokenType.COMMA)
              _throwSimpleSyntaxError('can\'t found a `,`', _backToken());
            else
              _throwSimpleSyntaxError('can\'t found a `;`', _backToken());
          }
        } catch (e) {
          _throwSimpleSyntaxError(e.toString(), _getCurrentToken());
        }
        return {
          'type': NodeType.SET_CONST,
          'pairs': pairs,
          'meta-line': current.line
        };
      } else if (current.value == 'var') {
        // "var" ident {"," ident} ";"
        var names = [];
        while (true) {
          names.add(_nextToken().value);
          var ntoken = _nextToken().type;

          if (ntoken == TokenType.COMMA)
            continue;
          else if (ntoken == TokenType.SEM)
            break;
          else if (ntoken != TokenType.SEM && ntoken != TokenType.COMMA)
            _throwSimpleSyntaxError('can\'t found `,` in ...', _backToken());
          else
            _throwSimpleSyntaxError(
                'can\'t found `;` for close var-block in ...', _backToken());
        }
        return {
          'type': NodeType.DEC_VARS,
          'names': names,
          'meta-line': current.line
        };
      } else if (current.value == 'procedure') {
        // "procedure" ident ";" block ";" } statement
        var name = _nextToken().value;

        _here_must_be(';', _getCurrentToken());

        var block = _block(in_procedure: true);
        var body = null;

        if (block['type'] == NodeType.DEC_VARS) {
          body = _statement();
          _here_must_be(';', _getCurrentToken());
        } else {
          _here_must_be(';', _getCurrentToken());
          body = block;
          block = null;
        }

        return {
          'type': NodeType.PROC_DEFINE,
          'name': name,
          'body': body,
          'block': block,
          'meta-line': current.line
        };
      }
    }
    _backToken();
    var stmt = _statement();
    if (!in_procedure) if (stmt['type'] == NodeType.BLOCK) {
      _here_must_be('.', _getCurrentToken());
      stmt['type'] = NodeType.MAIN_BLOCK;
    }
    return stmt;
  }

  List<Map> parse() {
    var program = List<Map>();
    while (_nextToken().type != TokenType.EOF) {
      _backToken();
      program.add(_block());
    }
    return program;
  }

  String _debugLine(Token current) {
    var line = '${current.value} ';
    var current_line = current.line;
    while (_nextToken().line == current_line) {
      _backToken();
      line += _nextToken().value + ' ';
    }
    return line;
  }

  void _here_must_be(String value, Token token) {
    if (_nextToken().value != value)
      _throwSimpleSyntaxError('here must be "${value}"', token);
  }

  void _throwSimpleSyntaxError(String msg, Token token) {
    print("SyntaxError[${token.line}]: $msg");
    exit(0);
  }
}
