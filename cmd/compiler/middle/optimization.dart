import '../syntax_analyzer/parser.dart';

class Optimization {
  static final _binops = {
    NodeType.ADD: (int a, int b) => a + b,
    NodeType.SUB: (int a, int b) => a - b,
    NodeType.MULTIPLY: (int a, int b) => a * b,
    NodeType.DIV: (int a, int b) => (a / b) as int,
    NodeType.MORE: (int a, int b) => (a > b) ? 1 : 0,
    NodeType.LESS: (int a, int b) => (a < b) ? 1 : 0,
    NodeType.EQ: (int a, int b) => (a == b) ? 1 : 0,
    NodeType.NOT_EQ: (int a, int b) => (a != b) ? 1 : 0
  };

  List<Map> _program;
  Map<String, String> _constantsTable;
  List<Map> _newListProgram;
  List<Map> _buffTemp;

  Optimization(this._program)
      : _constantsTable = Map<String, String>(),
        _newListProgram = List<Map>(),
        _buffTemp = List<Map>();

  int _evalBinOp(Function op, Map left, Map right) =>
      op(int.parse(left['value']), int.parse(right['value']));

  Map _optimize(Map node) {
    if (node == null) return null;

    var type = node['type'];

    if (_binops.containsKey(type)) {
      var l = _optimize(node['left']);
      var r = _optimize(node['right']);

      // Удаление общих подвыражений
      if (_binops.containsKey(l['type']) && _binops.containsKey(r['type'])) {
        if (l['left']['type'] == NodeType.VARIABLE_NAME &&
            r['left']['type'] == NodeType.VARIABLE_NAME &&
            l['left']['name'] == r['left']['name'] &&
            l['right']['name'] == r['right']['name']) {
          print('da');
          _buffTemp.add(l);
          _buffTemp.add({'type': NodeType.SET_VAR, 'name': '_temp'});
          Map temp = {'type': NodeType.VARIABLE_NAME, 'name': '_temp'};
          node['left'] = temp;
          node['right'] = temp;
          return node;
        }
      }

      // constant folding
      if (l['type'] == NodeType.CONST_NUMBER &&
          r['type'] == NodeType.CONST_NUMBER) {
        var op = _binops[node['type']];
        node['value'] = (_evalBinOp(op, l, r)).toString();
        node['type'] = NodeType.CONST_NUMBER;
        return node;
      }
    } else if (type == NodeType.SET_VAR) {
      node['value'] = _optimize(node['value']);
      return node;
    } else if (type == NodeType.BLOCK || type == NodeType.MAIN_BLOCK) {
      var nodeBody = node['body'] as List;
      var body = [];

      for (var i = 0; i < nodeBody.length; i++) {
        var o = _optimize(nodeBody[i]);
        for (var j in _buffTemp) body.add(j);
        _buffTemp.clear();
        body.add(o);
      }

      node['body'] = body;
      return node;
    } else if (type == NodeType.PROC_DEFINE) {
      (node['blocks'] as List).forEach((e) => _optimize(e));
      node['body'] = _optimize(node['body']);
    } else if (type == NodeType.IF || type == NodeType.WHILE) {
      node['cond'] = _optimize(node['cond']);
      node['body'] = _optimize(node['body']);
      // delete dead code
      if (node['cond']['type'] == NodeType.CONST_NUMBER &&
          node['cond']['value'] == '0') {
        return null;
      }
    } else if (type == NodeType.SET_CONST) {
      for (List i in node['pairs']) _constantsTable[i[0]] = i[1];
    } else if (type == NodeType.VARIABLE_NAME) {
      // replace name on scalar
      if (_constantsTable.containsKey(node['name'])) {
        node['value'] = _constantsTable[node['name']];
        node['type'] = NodeType.CONST_NUMBER;
        return node;
      }
    }
    return node;
  }

  List<Map> getProgram() {
    for (var i in _program) _newListProgram.add(_optimize(i));
    return _newListProgram;
  }
}
