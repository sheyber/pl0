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
  void _backToken() => _pos--;
  Token _getCurrentToken() => _tokens[_pos - 1];

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

      if (!_checkTokenValue(_nextToken(), ')')) {
        _throwSimpleSyntaxError(
            'Не могу найти закрывающаю скобку\n\t${_debugLine(_tokens[_pos])}',
            _getCurrentToken());
      }

      return expr;
    }

    _throwSimpleSyntaxError(
        'can\'t make a node:\n\t${_debugLine(current)}', current);
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
    var value = _expression();

    while (true) {
      var current = _nextToken();
      NodeType typeNode;

      switch (current.type) {
        case TokenType.EQ:
          typeNode = NodeType.EQ;
          break;
        case TokenType.NOT_EQ:
          typeNode = NodeType.NOT_EQ;
          break;
        case TokenType.LESS:
          typeNode = NodeType.LESS;
          break;
        case TokenType.MORE:
          typeNode = NodeType.MORE;
          break;
        default:
          _backToken();
          return value;
      }

      value = {
        'type': typeNode,
        'left': value,
        'right': _expression(),
        'meta-line': _getCurrentToken().line
      };
    }
  }

  Map _parseCallProcedureStmt() {
    return {
      'type': NodeType.CALL_PROC,
      'name': _nextToken().value,
      'meta-line': _getCurrentToken().line
    };
  }

  Map _parseBlock(Token current) {
    var bodyBlock = [];

    if (!_checkTokenValue(_nextToken(), 'end')) {
      _backToken();

      while (true) {
        var stmt = _statement();
        bodyBlock.add(stmt);

        var lookahead = _nextToken();
        if (_checkTokenType(lookahead, TokenType.SEM)) {
          if (_checkTokenValue(_nextToken(), 'end')) break;
          _backToken();
          continue;
        } else if (_checkTokenValue(lookahead, 'end')) {
          break;
        }

        _throwSimpleSyntaxError(
            'some error in block\n\t${_debugLine(_nextToken())}', lookahead);
      }
    }

    return {
      'type': NodeType.BLOCK,
      'body': bodyBlock,
      'meta-line': current.line
    };
  }

  Map _parseIfStmt(Token current) {
    var condition = _condition();

    var lookahead = _nextToken();
    if (!_checkTokenValue(lookahead, 'then')) {
      _throwSimpleSyntaxError(
          'После условия должно идти ключевое слово `then`\n\t${_debugLine(lookahead)}',
          _getCurrentToken());
    }

    var statement = _statement();

    return {
      'type': NodeType.IF,
      'cond': condition,
      'body': statement,
      'meta-line': current.line
    };
  }

  Map _parseWhileStmt(Token current) {
    var condition = _condition();

    var lookahead = _nextToken();
    if (!_checkTokenValue(lookahead, 'do')) {
      _throwSimpleSyntaxError(
          'После условия в цикле идёт ключевое слово `do` \n\t${_debugLine(_tokens[_pos - 2])}',
          _getCurrentToken());
    }

    var statement = _statement();

    return {
      'type': NodeType.WHILE,
      'cond': condition,
      'body': statement,
      'meta-line': current.line
    };
  }

  Map _parseSetVarStmt(Token current) {
    var name = current.value;

    var lookahead = _nextToken();
    if (!_checkTokenValue(lookahead, ':=')) {
      _throwSimpleSyntaxError(
          'Для инициализации перменной следует использовать оператор `:=` in\n\t${_debugLine(lookahead)}',
          _getCurrentToken());
    }

    var value = _expression();

    return {
      'type': NodeType.SET_VAR,
      'name': name,
      'value': value,
      'meta-line': _getCurrentToken().line
    };
  }

  Map _statement() {
    var current = _nextToken();

    if (current.type == TokenType.IDENT) {
      return _parseSetVarStmt(current);
    } else if (current.type == TokenType.KEYWORD) {
      switch (current.value) {
        case 'call':
          return _parseCallProcedureStmt();
        case 'begin':
          return _parseBlock(current);
        case 'if':
          return _parseIfStmt(current);
        case 'while':
          return _parseWhileStmt(current);
      }
    }

    _backToken();
    return _condition();
  }

  Map _parseSetConstantsStmt(Token current) {
    var pairs = []; // key1=value1, key2=value2 ... keyn=valuen

    while (true) {
      var nameOfConstant = _nextToken().value;

      var lookahead_0 = _nextToken();
      if (!_checkTokenValue(lookahead_0, '=')) {
        _throwSimpleSyntaxError(
            'after name of constant should be a value. For this must be a `=` after name.\n\t${_debugLine(lookahead_0)}',
            _getCurrentToken());
      }

      var valueOfConstant = _nextToken().value;

      pairs.add([nameOfConstant, valueOfConstant]);

      var lookahead = _nextToken();
      if (_checkTokenType(lookahead, TokenType.SEM)) {
        break;
      } else if (_checkTokenType(lookahead, TokenType.COMMA)) {
        var lookahead_2 = _nextToken();
        if (!_checkTokenType(lookahead_2, TokenType.IDENT))
          _throwSimpleSyntaxError(
              'после зяпятой идёт инициализация константы\n\t${_debugLine(lookahead_2)}',
              lookahead_2);
        _backToken();
        continue;
      }

      _throwSimpleSyntaxError(
          'can\'t parsing a constants stmt\n\t${_debugLine(_tokens[_pos - 2])}',
          lookahead);
    }

    return {
      'type': NodeType.SET_CONST,
      'pairs': pairs,
      'meta-line': current.line
    };
  }

  Map _parseVariablesDeclaration(Token current) {
    var names = []; // имена переменных

    while (true) {
      var name = _nextToken().value;
      names.add(name);

      var lookahead = _nextToken();
      if (_checkTokenType(lookahead, TokenType.SEM)) {
        break;
      } else if (_checkTokenType(lookahead, TokenType.COMMA)) {
        var lookahead2 = _nextToken();
        if (!_checkTokenType(lookahead2, TokenType.IDENT))
          _throwSimpleSyntaxError(
              'после запятой идёт след. имя перменной\n\t${_debugLine(lookahead2)}',
              lookahead2);
        _backToken();
        continue;
      }

      _throwSimpleSyntaxError(
          'Не удаётся распознать декларацию перменных\n\t${_debugLine(_tokens[_pos])}',
          _getCurrentToken());
    }

    return {
      'type': NodeType.DEC_VARS,
      'names': names,
      'meta-line': current.line
    };
  }

  Map _parseProcedureDefinitionBlock(Token current) {
    var nameOfProcedure = _nextToken().value;

    if (!_checkTokenType(_nextToken(), TokenType.SEM)) {
      _throwSimpleSyntaxError(
          'После имени процедуры должен идти `;`\n\t${_debugLine(_tokens[_pos - 1])}',
          _getCurrentToken());
    }

    Map body;
    List<Map> blocks = List<Map>();

    while (true) {
      var block = _block(in_procedure: true);

      if (block['type'] == NodeType.BLOCK) {
        body = block;
        break;
      } else if ([NodeType.DEC_VARS, NodeType.SET_CONST]
          .contains(block['type'])) {
        blocks.add(block);
        continue;
      }

      _throwSimpleSyntaxError('Не кен', _getCurrentToken());
    }

    return {
      'type': NodeType.PROC_DEFINE,
      'name': nameOfProcedure,
      'body': body,
      'blocks': blocks,
      'meta-line': current.line
    };
  }

  Map _block({in_procedure = false}) {
    var current = _nextToken();

    if (current.type == TokenType.KEYWORD) {
      if (current.value == 'const') {
        // "const" ident "=" number {"," ident "=" number} ";"
        return _parseSetConstantsStmt(current);
      } else if (current.value == 'var') {
        // "var" ident {"," ident} ";"
        return _parseVariablesDeclaration(current);
      } else if (current.value == 'procedure') {
        // "procedure" ident ";" block ";" } statement
        return _parseProcedureDefinitionBlock(current);
      }
    }

    _backToken();
    var stmt = _statement();

    if (!in_procedure && stmt['type'] == NodeType.BLOCK) {
      if (!_checkTokenValue(_nextToken(), '.')) {
        _throwSimpleSyntaxError(
            'Главный блок обязан заканчивается точкой с запятой!',
            _getCurrentToken());
      }
      stmt['type'] = NodeType.MAIN_BLOCK;
    } else if (in_procedure && stmt['type'] == NodeType.BLOCK) {
      if (!_checkTokenType(_nextToken(), TokenType.SEM)) {
        _throwSimpleSyntaxError(
            'нада `;`\n\t${_debugLine(_tokens[_pos])}', _getCurrentToken());
      }
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
    var line = '';
    var current_line = current.line;

    for (var i = 0; i < _tokens.length; i++) {
      if (_tokens[i].line == current_line) {
        line += _tokens[i].value + ' ';
      }
    }
    return line;
  }

  bool _checkTokenType(Token token, TokenType type) => token.type == type;
  bool _checkTokenValue(Token token, String value) => token.value == value;

  void _throwSimpleSyntaxError(String msg, Token token) {
    print("SyntaxError[${token.line}]: $msg");
    exit(0);
  }
}
