import '../syntax_analyzer/parser.dart';

class Optimization {
  static const _binops = [
    NodeType.ADD,
    NodeType.SUB,
    NodeType.MULTIPLY,
    NodeType.DIV,
    NodeType.LESS,
    NodeType.MORE,
    NodeType.EQ,
    NodeType.NOT_EQ
  ];

  List<Map> _program;
  Map<String, String> _constantsTable;

  Optimization(this._program) : _constantsTable = Map<String, String>();

  int _add(int a, int b) => a + b;
  int _sub(int a, int b) => a - b;
  int _mul(int a, int b) => a * b;
  int _div(int a, int b) => (a / b) as int;
  int _more(int a, int b) => (a > b) ? 1 : 0;
  int _less(int a, int b) => (a < b) ? 1 : 0;
  int _eq(int a, int b) => (a == b) ? 1 : 0;
  int _noteq(int a, int b) => (a != b) ? 1 : 0;

  int _evalBinOp(Function op, Map left, Map right) =>
      op(int.parse(left['value']), int.parse(right['value']));

  Map _optimize(Map node) {
    if (node == null) return null;

    var type = node['type'];

    if (_binops.contains(type)) {
      var l = _optimize(node['left']);
      var r = _optimize(node['right']);

      if (l['type'] == NodeType.CONST_NUMBER &&
          r['type'] == NodeType.CONST_NUMBER) {
        var op = ({
          NodeType.ADD: _add,
          NodeType.SUB: _sub,
          NodeType.MULTIPLY: _mul,
          NodeType.DIV: _div,
          NodeType.MORE: _more,
          NodeType.LESS: _less,
          NodeType.EQ: _eq,
          NodeType.NOT_EQ: _noteq
        })[node['type']];
        node['value'] = (_evalBinOp(op, l, r)).toString();
        node['type'] = NodeType.CONST_NUMBER;
        return node;
      }
    } else if (type == NodeType.SET_VAR) {
      node['value'] = _optimize(node['value']);
      return node;
    } else if (type == NodeType.BLOCK || type == NodeType.MAIN_BLOCK) {
      node['body'] = (node['body'] as List).map((e) => _optimize(e));
    } else if (type == NodeType.PROC_DEFINE) {
      node['body'] = _optimize(node['body']);
    } else if (type == NodeType.IF || type == NodeType.WHILE) {
      node['cond'] = _optimize(node['cond']);
      node['body'] = _optimize(node['body']);
      if (node['cond']['type'] == NodeType.CONST_NUMBER &&
          node['cond']['value'] == '0') {
        return null;
      }
    } else if (type == NodeType.SET_CONST) {
      for (List i in node['pairs']) _constantsTable[i[0]] = i[1];
    } else if (type == NodeType.VARIABLE_NAME) {
      if (_constantsTable.containsKey(node['name'])) {
        node['value'] = _constantsTable[node['name']];
        node['type'] = NodeType.CONST_NUMBER;
        return node;
      }
    }
    return node;
  }

  List<Map> getProgram() {
    var newListProgram = List<Map>();
    for (var i in _program) newListProgram.add(_optimize(i));
    return newListProgram;
  }
}
