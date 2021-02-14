import '../syntax_analyzer/parser.dart';
import '../syntax_analyzer/scanner.dart';

class SemanticChecker {
  List<Map> _program;
  List<List<String>> _scopes;
  List<List<String>> _scopesOfConstants;
  Map<String, int> _usedVariables; // подсчёт используемых переменных
  int errorsCount = 0;

  SemanticChecker(this._program)
      : _scopes = List<List<String>>(),
        _scopesOfConstants = List<List<String>>(),
        _usedVariables = Map<String, int>();

  void _throwSemanticError(String msg, Map node) {
    print('SemanticError[${node["meta-line"]}]: $msg');
    errorsCount++;
  }

  void _throwSemanticWarning(String msg, [Map node]) {
    print('\u001b[33mSemanticWarning\u001b[0m: $msg');
  }

  void _check(Map node, [Map parent]) {
    if (node == null) return;
    var type = node['type'];

    switch (type) {
      case NodeType.VARIABLE_NAME:
        var name = node['name'];
        var match = false;

        for (var i in _scopes) if (i.contains(name)) match = true;
        for (var i in _scopesOfConstants) if (i.contains(name)) match = true;

        if (!match)
          _throwSemanticError(
              'undefined variable $name in\n\t${node["meta-line"]}| ${_reconstruction(parent)}',
              node);

        if (match) _usedVariables[name]++;

        break;
      case NodeType.SET_VAR:
        var name = node['name'];
        // var error = false;
        var match = false;

        for (var i in _scopes) if (i.contains(name)) match = true;
        for (var i in _scopesOfConstants)
          if (i.contains(name)) {
            _throwSemanticError(
                'you are trying to set the value of a constant $name in\n\t${node["meta-line"]}| ${_reconstruction(node)}',
                node);
            return;
          }

        if (!match)
          _throwSemanticError(
              'undeclaration variable $name in\n\t${node["meta-line"]}| ${_reconstruction(node)}',
              node);

        _check(node['value'], node);
        // if (error) _scopes.last.add(name);
        break;
      case NodeType.ADD:
      case NodeType.SUB:
      case NodeType.DIV:
      case NodeType.MULTIPLY:
      case NodeType.MORE:
      case NodeType.LESS:
      case NodeType.EQ:
      case NodeType.NOT_EQ:
        _check(node['left'], parent);
        _check(node['right'], parent);
        break;
      case NodeType.BLOCK:
      case NodeType.MAIN_BLOCK:
        _scopes.add([]);
        for (var i in node['body']) _check(i, node);
        break;
      case NodeType.DEC_VARS:
        for (var i in node['names']) {
          if (Scanner.keywords.contains(i)) {
            _throwSemanticError('name of variable can\'t be a keyword', node);
            continue;
          }
          _scopes.last.add(i);
          _usedVariables[i] = 0;
        }
        break;
      case NodeType.SET_CONST:
        for (List i in node['pairs']) {
          _scopesOfConstants.last.add(i[0]);
          _usedVariables[i[0]] = 0;
        }
        ;
        break;
      case NodeType.WHILE:
      case NodeType.IF:
        _check(node['cond'], node);
        _check(node['body'], node);
        break;
      case NodeType.PROC_DEFINE:
        if (Scanner.keywords.contains(node['name']))
          _throwSemanticError(
              'name of procedure can\'t be keyword in\n\t${node["meta-line"]}| ${_reconstruction(node)}',
              node);

        _scopes.add([]);
        _scopesOfConstants.add([]);

        (node['blocks'] as List).forEach((element) => _check(element));
        _check(node['body']);
        _scopes.first.add(node['name']);

        _scopes.removeLast();
        _scopes.removeLast();
        _scopesOfConstants.removeLast();
        break;
      case NodeType.CALL_PROC:
        if (!_scopes.first.contains(node['name']))
          _throwSemanticError(
              'this procedure wasn\'t definition before \n\t${node["meta-line"]}| ${_reconstruction(node)}',
              node);
        break;
    }
  }

  bool check() {
    _scopes.add(['print']);
    _scopesOfConstants.add([]);

    for (var i in _program) _check(i);

    if (errorsCount == 0)
      _usedVariables.forEach((key, value) {
        if (key == 'out') return; // magic
        if (value == 0) _throwSemanticWarning('unused the "$key" variable');
      });

    return (errorsCount > 0) ? false : true;
  }

  String _reconstruction(Map node) {
    if (node == null) return '';
    var type = node['type'];

    switch (type) {
      case NodeType.VARIABLE_NAME:
        return node['name'];
      case NodeType.CONST_NUMBER:
        return node['value'];

      case NodeType.MULTIPLY:
        return '${_reconstruction(node["left"])} * ${_reconstruction(node["right"])}';
      case NodeType.MORE:
        return '${_reconstruction(node["left"])} > ${_reconstruction(node["right"])}';
      case NodeType.LESS:
        return '${_reconstruction(node["left"])} < ${_reconstruction(node["right"])}';
      case NodeType.ADD:
        return '${_reconstruction(node["left"])} + ${_reconstruction(node["right"])}';
      case NodeType.SUB:
        return '${_reconstruction(node["left"])} - ${_reconstruction(node["right"])}';
      case NodeType.DIV:
        return '${_reconstruction(node["left"])} / ${_reconstruction(node["right"])}';
      case NodeType.EQ:
        return '${_reconstruction(node["left"])} == ${_reconstruction(node["right"])}';
      case NodeType.NOT_EQ:
        return '${_reconstruction(node["left"])} # ${_reconstruction(node["right"])}';

      case NodeType.SET_VAR:
        return '${node["name"]} := ${_reconstruction(node["value"])}';
      case NodeType.IF:
        return 'if ${_reconstruction(node["cond"])} then ';
      case NodeType.WHILE:
        return 'while ${_reconstruction(node["cond"])} do ';
      case NodeType.BLOCK:
        var body = (node['body'] as List)
            .map((e) => _reconstruction(e))
            .map((e) => '   $e')
            .join('\n');
        return 'begin\n${body}\nend;';
      case NodeType.PROC_DEFINE:
        return 'procedure ${node["name"]};';
      case NodeType.CALL_PROC:
        return 'call ${node["name"]}';
    }

    return '%_%';
  }
}
